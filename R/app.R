#' Launch shiny app for exploring pedestrian data
#' 
#' @param prop what proportion of the raw data should be displayed?
#' 
#' @export
#' @examples \dontrun{
#' launchApp()
#' }


launchApp <- function(prop = 0.01) {
  sensors <- pedestrians::sensors
  vars <- names(pedestrians::pedestrians)
  # random sample (needed for performance/speed)
  n <- nrow(pedestrians::pedestrians)
  pedSample <- pedestrians::pedestrians[sample(n, n * prop), ]
  
  # mechanism for maintain selection across
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
          ),
          numericInput(
            "alphaSelect", "Alpha transparency", value = 3 / (prop * 1000), min = 0, max = 1
          )
        ),
        column(
          width = 3,
          h4("Time Series controls:"),
          selectInput("x", "Choose an X:", vars, selected = "Hour"),
          selectInput("filter", "Choose a filter:", c("none", vars), selected = "none"),
          selectInput("facet", "Choose a conditioning:", c("none", vars), selected = "none"),
          numericInput(
            "alphaBase", "Alpha transparency", value = 1 / (prop * 1000), min = 0, max = 1
          ),
          selectizeInput(
            "tooltip", "Choose variable to show in tooltip", multiple = TRUE,
            vars, selected = c("DateTime", "Name") 
          )
        )
      )
    ),
    fluidRow(
      column(
        width = 4,
        leafletOutput("map")
      ),
      column(
        width = 8,
        plotlyOutput("pcp")
      )
    ),
    plotlyOutput("timeSeries")
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
        # isolate ensures this doesn't get invalidated when brushColor changes
        isolate({
          selection(eventData, input$brushColor, `|`)
        })
      }
      # before returning selection data,
      # add a marker to the map (without redrawing the whole thing)
      dat <- selection()
      leafletProxy("map", session) %>% 
        removeMarker(paste0("selected", dat$ID))
      
      if (any(dat$selected)) {
        d <- dat %>% filter(selected) %>% left_join(sensors, by = "ID")
        leafletProxy("map", session) %>%
          addCircleMarkers(
            d$Longitude, d$Latitude, layerId = paste0("selected", d$ID),
            label = d$Description, color = d$fill
          )
      }
      dat
    })
    
    output$pcp <- renderPlotly({
      cog01 <- data.frame(
        pedestrians::cog[, 1], 
        lapply(pedestrians::cog[, -1], scales::rescale)
      )
      cog01 <- left_join(cog01, sensors[c("ID", "Description")], by = "ID")
      dat <- inner_join(tidyr::gather(cog01, variable, value, -ID, -Description), selectHandler(), by = "ID")
      #dat <- left_join(dat, sensors[c("ID", "Description")], by = "ID")
      p <- ggplot(dat, aes(variable, value, text = Description, key = ID, group = ID, color = fill)) + 
        geom_point(size =  0.0001) + geom_line(alpha = 0.5) +
        scale_color_identity() + labs(x = NULL, y = NULL) + 
        theme(axis.text.x = element_text(angle = 45), legend.position = "none")
      l <- plotly_build(ggplotly(p, tooltip = "text")) 
      l$layout$margin$b <- l$layout$margin$b + 20
      l$layout$dragmode <- "select"
      l
    })
    
    output$timeSeries <- renderPlotly({
      dat <- inner_join(pedSample, selectHandler(), by = "ID")
      dat$tooltip <- apply(dat[input$tooltip], 1, function(x) {
        paste0(colnames(dat[input$tooltip]), ": ", x, collapse = "<br />")
      })
      pointMap <- aes_string(x = input$x, y = "Counts", color = "fill", text = "tooltip")
      smoothMap <- aes_string(x = input$x, y = "Counts", color = "fill")
      d <- dat[!dat$selected, ]
      p <- ggplot(data = d) + 
        geom_point(pointMap, alpha = input$alphaBase) + 
        geom_smooth(smoothMap, se = FALSE) + 
        labs(x = NULL, y = NULL) + scale_color_identity() 
      if (any(dat$selected)) {
        d <- dat[dat$selected, ]
        p <- p + 
          geom_smooth(data = d,  smoothMap, se = FALSE) +
          geom_point(data = d, pointMap, alpha = input$alphaSelect) 
      }
      if (input$facet != "none") {
        p <- p + 
          facet_wrap(as.formula(paste("~", input$facet)), ncol = 1, scales = "free")
      }
      l <- plotly_build(ggplotly(p, tooltip = "text"))
      l$data <- lapply(l$data, function(x) { x$type <- "scattergl"; x })
      l$layout$height <- 600 * max(1, length(unique(as.list(pedSample)[[input$facet]])))
      l
    })
    
    #output$timeSeries2 <- renderUI({
    #  height <- 600 * max(1, length(unique(pedSample[[input$facet]])))
    #  plotlyOutput("timeSeries", height = height)
    #})
    
  }
  shinyApp(ui, server)
}
