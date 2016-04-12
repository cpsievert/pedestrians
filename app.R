library(shiny)
library(leaflet)
library(plotly)
library(dplyr)

# read in data
pedestrians <- feather::read_feather("pedestrians.feather")
names(pedestrians) <- sub("^Sensor", "", names(pedestrians))
# random sample (needed for performance/speed)
pedSample <- pedestrians[sample(seq_len(nrow(pedestrians)), 10000), ]

sensors <- feather::read_feather("sensors.feather")
names(sensors) <- sub("^Sensor ", "", names(sensors))
# there are some sensors that don't have any pedestrian data
sensors <- semi_join(sensors, pedestrians, by = "ID")

cog <- feather::read_feather("cognostics.feather")
# compute pca and grab first two principal components
pcaDat <- setNames(
  data.frame(cog[, 1], princomp(cog, cor = TRUE)$scores[, 1:2]),
  c("ID", "Comp.1", "Comp.2")
)
# attach sensor description for informative tooltips
pcaDat <- left_join(
  pcaDat, sensors[c("ID", "Description")], by = "ID"
)

# mechanism for managing selected sensors
init <- function() {
  s <- data.frame(
    ID = sensors$ID,
    selected = rep(FALSE, nrow(sensors)),
    fill = rep("black", nrow(sensors)),
    stringsAsFactors = FALSE
  )
  function(x, color = "red", logic = xor) {
    if (missing(x)) return(s)
    # if a characters are provided, assume they are sensor IDs
    if (!is.logical(x)) x <- sensors$ID %in% x
    s$selected <- logic(s$selected, x)
    if (!any(s$selected)) {
      s$fill <- "black"
    } else {
      # 'lazy' coloring (i.e., only change the color if this is a "new" selection)
      idx <- s$fill %in% "black" & s$selected
      if (any(idx)) s[idx, "fill"] <- color
    }
    s <<- s
  }
}
selection <- init()

# user interface
ui <- fluidPage(
  checkboxInput("show", "Show Controls", value = FALSE),
  conditionalPanel(
    condition = "input.show",
    fluidRow(
      column(
        width = 2,
        h4("Selection controls:"),
        checkboxInput("persist", "Persistent Selections", value = FALSE),
        selectInput(
          "brushColor", "Selection Color", choices = c("red", "blue", "yellow")
        )
      ),
      column(
        width = 3,
        h4("Time Series controls:"),
        selectInput("x", "Choose a X:", names(pedestrians), selected = "DateTime"),
        selectizeInput(
          "tooltip", "Choose variable to show in tooltip", multiple = TRUE,
          names(pedestrians), selected = c("Year", "Month", "Day", "Hour") 
        )
      )
    )
  ),
  plotlyOutput("timeSeries"),
  fluidRow(
    column(
      width = 6,
      leafletOutput("map")
    ),
    column(
      width = 6, 
      plotlyOutput("pcaPlot")
    )
  ),
  verbatimTextOutput("selection")
)
server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      fitBounds(min(sensors$Longitude), min(sensors$Latitude), 
                max(sensors$Longitude), max(sensors$Latitude)) %>%
      addCircleMarkers(
        sensors$Longitude, sensors$Latitude, layerId = sensors$ID,
        popup = sensors$Description, color = "black"
      )
  })
  
  # obtain a subset of the data that is still under consideration
  selectHandler <- reactive({
    # if not in persistant selection mode, clear the selection first
    if (!input$persist) selection(FALSE, "black", `&`)
    
    eventData <- unique(c(
      event_data("plotly_click")[["key"]],
      event_data("plotly_selected")[["key"]],
      input$map_marker_click
    ))
    if (!is.null(eventData)) {
      isolate({
        selection(eventData, input$brushColor, `|`)
      })
    }
    # before returning selection data,
    # add a marker to the map (without redrawing the whole thing)
    dat <- selection()
    if (any(dat$selected)) {
      d <- dat %>% filter(selected) %>% left_join(sensors, by = "ID")
      leafletProxy("map", session) %>% 
        removeMarker(paste0("selected", dat$ID)) %>%
        addCircleMarkers(
          d$Longitude, d$Latitude, layerId = paste0("selected", dat$ID),
          popup = d$Description, color = d$fill
        )
    }
    dat
  })
  
  output$timeSeries <- renderPlotly({
    dat <- inner_join(pedSample, selectHandler(), by = "ID")
    dat$tooltip <- apply(dat[input$tooltip], 1, function(x) {
      paste0(colnames(dat[input$tooltip]), ": ", x, collapse = "<br />")
    })
    if (any(dat$selected)) {
      s <- filter(dat, selected)
      ns <- filter(dat, !selected)
      # draw the "non-selected" (shadowed) points first
      p <- plot_ly(
        x = ns[[input$x]], y = ns$Counts, text = ns$tooltip,
        type = "scattergl", mode = "markers", hoverinfo = "text",
        marker = list(color = toRGB(ns$fill, 0.01))
      )
      # TODO: trace for each fill?
      p <- add_trace(
        p, x = s[[input$x]], y = s$Counts, text = s$tooltip,
        type = "scattergl", mode = "markers", hoverinfo = "text",
        marker = list(color = toRGB(s$fill, 0.2))
      )
    } else {
      p <- plot_ly(
        x = dat[[input$x]], y = dat$Counts, text = dat$tooltip,
        type = "scattergl", mode = "markers", hoverinfo = "text",
        marker = list(color = toRGB(dat$fill, 0.05))
      )
    }
    layout(
      p, showlegend = FALSE, 
      xaxis = list(title = ""), 
      yaxis = list(title = "Counts")
    )
  })
  
  output$pcaPlot <- renderPlotly({
    dat <- inner_join(selectHandler(), pcaDat, by = "ID")
    p <- ggplot(dat, aes(Comp.1, Comp.2, 
                         text = Description, key = ID)) + 
      geom_point(aes(colour = fill)) + scale_colour_identity() +
      theme(aspect.ratio = 1, legend.position = "none") + 
      labs(x = NULL, y = NULL)
    
    ggplotly(p, tooltip = "text") %>%
      layout(dragmode = "select")
  })
  
  #output$selection <- renderPrint({
  #  summary(selectHandler())
  #})
}

shinyApp(ui, server)