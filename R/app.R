#' Launch shiny app for exploring pedestrian data
#' 
#' @export
#' @examples \dontrun{
#' launchApp()
#' }


launchApp <- function() {
  
  data("pedestrians")
  data("sensors")
  data("cog")
  # random sample (needed for performance/speed)
  pedSample <- pedestrians[sample(seq_len(nrow(pedestrians)), 10000), ]
  
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
            "brushColor", "Selection Color", 
            choices = c("red", "purple", "green", "blue", "yellow")
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
        width = 5,
        leafletOutput("map")
      ),
      column(
        width = 4, 
        plotlyOutput("tourPlot")
      ),
      column(
        width = 3,
        h4("Touring controls:"),
        checkboxInput("play", "Start Grand Tour:", value = FALSE),
        selectizeInput(
          "tourVars", "Touring variables:", multiple = TRUE, 
          names(cog)[-1], names(cog)[-1]
        )
      )
    )
  )
  server <- function(input, output, session) {
    
    output$map <- renderLeaflet({
      leaflet() %>% 
        addTiles() %>% 
        fitBounds(min(sensors$Longitude), min(sensors$Latitude), 
                  max(sensors$Longitude), max(sensors$Latitude)) %>%
        addCircleMarkers(
          sensors$Longitude, sensors$Latitude, layerId = sensors$ID,
          color = "black", label = sensors$Description
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
            label = d$Description, color = d$fill
          )
      }
      dat
    })
    
    output$timeSeries <- renderPlotly({
      dat <- inner_join(pedSample, selectHandler(), by = "ID")
      dat$tooltip <- apply(dat[input$tooltip], 1, function(x) {
        paste0(colnames(dat[input$tooltip]), ": ", x, collapse = "<br />")
      })
      # dates are slow, so we force x to always be numeric
      # first off, how many tick labels to show?
      nTicks <- length(unique(dat[[input$x]]))
      # 12 months and 3 years for datetimes
      qs <- quantile(dat[[input$x]], seq(0, 1, length.out = min(nTicks, 36)))
      xAxis <- list(
        title = "", 
        range = c(0, 1),
        ticktext = if ("POSIXct" %in% class(qs)) scales::date_format("%b %y")(qs) else as.character(qs), 
        tickvals = as.numeric(sub("%", "", names(qs))) / 100,
        tickangle = -45
      )
      dat[[input$x]] <- scales::rescale(as.numeric(dat[[input$x]]))
      
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
        xaxis = xAxis,
        yaxis = list(title = "Counts")
      )
    })
    
    # touring stuffs
    initTour <- reactive({
      mat <- scales::rescale(as.matrix(cog[input$tourVars]))
      tour <- new_tour(mat, grand_tour(), NULL)
      list(
        mat = mat,
        tour = tour,
        step = tour(1)
      )
    })
    
    iterTour <- reactive({
      tr <- initTour()
      if (input$play) invalidateLater(1000 / 30, NULL)
      tr$step <- tr$tour(2 / 30) # you always want 30 frames/second, right?
      list(
        mat = tr$mat,
        tour = tr$tour,
        step = tr$step
      )
    })
    
    tourDat <- reactive({
      tr <- iterTour()
      tDat <- setNames(
        data.frame(cog[, 1], tr$mat %*% tr$step$proj), 
        c("ID", "x", "y")
      )
      inner_join(selectHandler(), tDat, by = "ID")
    })
    
    output$tourPlot <- renderPlotly({
      dat <- inner_join(tourDat(), sensors[c("ID", "Description")], by = "ID")
      plot_ly(
        dat, x = x, y = y, text = Description, key = ID,
        mode = "markers", hoverinfo = "text", marker = list(color = toRGB(fill, 0.5))
      ) %>% layout(
        width = 400, height = 400, showlegend = FALSE,
        xaxis = list(title = "", range = c(-1, 1)), 
        yaxis = list(title = "", range = c(-1, 1))
      )
    })
    
  }
  
  shinyApp(ui, server)
  
}
