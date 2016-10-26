#' Launch shiny app for exploring pedestrian data
#' 
#' Using this function is not recommended (at least currently).
#' Visit the website for examples like this shiny app that don't
#' require shiny -- \url{http://cpsievert.github.io/pedestrians}
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
          checkboxInput("persist", "Persistent Selections", value = TRUE),
          selectInput(
            "brushColor", "Selection Color", 
            choices = c("red", "purple", "green", "blue", "yellow")
          )
        ),
        column(
          width = 3,
          h4("Time Series controls:"),
          selectInput("x", "Choose an X:", vars, selected = "Hour"),
          selectInput("facet", "Choose a conditioning:", c("none", vars), selected = "none"),
          numericInput(
            "alpha", "Alpha transparency", value = 1 / (prop * 1000), min = 0, max = 1
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
    plotlyOutput("timeSeries", height = 700)
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
      cog <- pedestrians::cog
      cog01 <- data.frame(
        ID = cog[, "ID"], 
        lapply(cog[!grepl("^ID$", names(cog))], scales::rescale)
      )
      cog01 <- left_join(cog01, sensors[c("ID", "Description")], by = "ID")
      dat <- inner_join(tidyr::gather(cog01, variable, value, -ID, -Description), selectHandler(), by = "ID")
      #dat <- left_join(dat, sensors[c("ID", "Description")], by = "ID")
      p <- ggplot(dat, aes(variable, value, text = Description, key = ID, group = ID, color = fill)) + 
        geom_point(size =  0.0001) + geom_line(alpha = 0.5) +
        scale_color_identity() + labs(x = NULL, y = NULL) + 
        theme(axis.text.x = element_text(angle = 45), legend.position = "none")
      l <- plotly_build(ggplotly(p, tooltip = "text")) 
      l$x$layout$margin$b <- l$layout$margin$b + 20
      l$x$layout$dragmode <- "select"
      l
      
      # TODO: why aren't events firing correctly?!?
      # dat %>%
      #   group_by(ID) %>%
      #   plot_ly(x = ~variable, y = ~value, text = ~Description, key = ~ID,
      #           color = ~fill, colors = unique(dat$fill)) %>%
      #   add_lines(hoverinfo = "text") %>% plotly_json()
      #   layout(
      #     dragmode = "select",
      #     hovermode = "closest",
      #     showlegend = FALSE,
      #     xaxis = list(title = ""), 
      #     yaxis = list(title = ""),
      #     margin = list(b = 50, r = 35)
      #   )
    })
    
    output$timeSeries <- renderPlotly({
      dat <- inner_join(pedSample, selectHandler(), by = "ID")
      dat$tooltip <- apply(dat[input$tooltip], 1, function(x) {
        paste0(colnames(dat[input$tooltip]), ": ", x, collapse = "<br />")
      })
      mcolor <- toRGB("black", input$alpha)
      datSelect <- dat[dat$selected, ]
      
      p1 <- dat %>% 
        plot_ly(x = string2formula(input$x), y = ~Counts, text = ~tooltip, hoverinfo = "text") %>%
        add_markers(marker = list(color = mcolor), name = "All Stations") %>%
        add_markers(data = datSelect, marker = list(color = ~fill), showlegend = FALSE)
      
      if (input$x != "Hour") {
        return(p1)
      }
      
      p2 <- ts_summary(input$x, datSelect$ID, datSelect$fill)
      
      subplot(p1, p2, nrows = 2, shareX = TRUE)
      
    })
    
  }
  shinyApp(ui, server)
}
