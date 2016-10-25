# A standalone HTML version of launchApp()

# devtools::install_github("rstudio/leaflet@56eb3ecbb25ddc195c1cc6f530246dbb565f99ee")
library(leaflet)
# devtools::install_github("ropensci/plotly@dce5a288b2b7daddf3884b4f57dbfa4e02b9fab8")
library(plotly)
library(crosstalk)
library(htmltools)
library(dplyr)
library(tidyr)
library(tourr)

data(pedestrians, package = "pedestrians")
data(sensors, package = "pedestrians")
data(cog, package = "pedestrians")


# tour of time-series cognostics
# TODO: try touring a PCA of the actual time-series
cog01 <- rescale(cog)
tour <- new_tour(cog01, grand_tour(), NULL)

tour_dat <- function(step_size) {
  step <- tour(step_size)
  proj <- center(cog01 %*% step$proj)
  data.frame(x = proj[,1], y = proj[,2], Name = rownames(cog))
}

steps <- c(0, rep(1/15, 500))
stepz <- cumsum(steps)

# tidy version of tour data
tour_dats <- lapply(steps, tour_dat)
tour_datz <- Map(function(x, y) cbind(x, step = y), tour_dats, stepz)
tour_dat <- dplyr::bind_rows(tour_datz)

ax <- list(
  title = "", range = c(-1, 1), zeroline = FALSE
)

options(digits = 3)

tour <- tour_dat %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(x = ~x, y = ~y, frame = ~step, color = I("black"), height = 250, width = 250) %>%
  add_markers(text = ~Name, hoverinfo = "text") %>%
  hide_legend() %>%
  layout(xaxis = ax, yaxis = ax) %>%
  animationOpts(33, 0) %>%
  animationSlider(hide = TRUE)

# set some crosstalk options for leaflet 
options(opacityDim = 0.5, persistent = TRUE)

# for setting map aspect ratio
mapRatio <- with(sensors, diff(range(Longitude)) / diff(range(Latitude)))

map <- sensors %>%
  SharedData$new(~Description, group = "melb") %>%
  leaflet(height = 250, width = 250 * mapRatio) %>% 
  addTiles() %>% 
  fitBounds(
    ~min(Longitude), ~min(Latitude), ~max(Longitude), ~max(Latitude)
  ) %>%
  addCircleMarkers(
    ~Longitude, ~Latitude, layerId = ~Description, label = ~Description, color = "black"
  )

# "standardized" (i.e., mean 0, std dev 1) cognostics
cogSTD <- cog %>%
  scale() %>%
  data.frame(stringsAsFactors = F) %>%
  mutate(Name = rownames(.)) %>%
  gather(variable, value, -Name)

# TODO: get this working in pure plot_ly() (needs a fix for building group index when x is categorical)
p <- cogSTD %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(height = 250) %>% 
  ggplot(aes(variable, value, group = Name, text = Name)) + 
  geom_line() + geom_point(size = 0.01) + 
  theme(axis.text.x = element_text(angle = 45)) + 
  labs(x = NULL, y = NULL)

p2 <- p %>%
  ggplotly(tooltip = "text", height = 250) %>%
  layout(dragmode = "select", margin = list(b = 70)) %>%
  highlight(off = "plotly_deselect", dynamic = TRUE, persistent = TRUE)

# stratisfied random sample of raw data (needed for performance/speed)
n <- nrow(pedestrians)
idx <- c()
for (i in unique(pedestrians$Name)) {
  idx <- c(idx, sample(which(pedestrians$Name %in% i), n * 0.001))
}
pedSample <- pedestrians[idx, ]

# plot 3
p3 <- pedSample %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(x = ~Hour, y = ~Counts, text = ~paste(DateTime, "<br />", Name),
          color = I("black"), alpha = 0.01, height = 250, hoverinfo = "text") %>% 
  toWebGL() %>%
  layout(
    title = "Raw Counts (randomly sampled)",
    yaxis = list(title = ""), 
    xaxis = list(title = "Hour of Day")
  ) %>%
  highlight(off = NULL, opacityDim = 1, persistent = TRUE)

# plot 4 (IQR ribbons)
tidyIQR <- function(data, groups = NULL) {
  if (is.SharedData(data)) data <- data$origData()
  for (i in groups) {
    data <- group_by_(data, i, add = TRUE)
  }
  summarise(
    data,
    min = min(Counts, na.rm = T),
    q1 = quantile(Counts, 0.25, na.rm = T),
    med = median(Counts, na.rm = T),
    q3 = quantile(Counts, 0.75, na.rm = T),
    max = max(Counts, na.rm = T)
  )
}

byHour <- tidyIQR(pedestrians, "Hour")
byHourID <- tidyIQR(pedestrians, c("Hour", "Name"))
byHourID <- SharedData$new(byHourID, ~Name, "melb")

p4 <- plot_ly(byHour, x = ~Hour, color = I("black"), height = 250) %>%
  add_ribbons(ymin = ~q1, ymax = ~q3) %>%
  add_lines(y = ~med) %>%
  add_data(byHourID) %>%
  group_by(Name) %>%
  add_ribbons(ymin = ~q1, ymax = ~q3, color = I("red"), alpha = 0.5) %>%
  add_lines(y = ~med, color = I("red")) %>%
  layout(
    title = "IQR by station vs overall",
    yaxis = list(title = ""), 
    xaxis = list(title = "Hour of Day"),
    dragmode = "zoom"
  ) %>%
  highlight(off = "plotly_doubleclick", opacityDim = 0, persistent = TRUE) %>%
  hide_legend()

# why does this blow up?
#p5 <- pedSample %>%
#  SharedData$new(~Name, group = "melb") %>%
#  plot_ly(x = ~lubridate::yday(DateTime) + Hour / 24, 
#              y = ~Counts, height = 250) %>%
#  group_by(Name, Year) %>%
#  add_lines(alpha = 0.02, color = I("black")) %>%
#  layout(
#    title = "Raw Counts (randomly sampled)",
#    yaxis = list(title = ""), 
#    xaxis = list(title = "Day of year"),
#    dragmode = "zoom"
#  ) %>%
#  highlight(off = "plotly_doubleclick", defaultValues = 1, persistent = TRUE) %>%
#  rangeslider()
#
miniflex <- tags$div(
  style = "display: flex; flex-wrap: wrap",
  tags$div(map, style = "width: 50%"),
  tags$div(tour, style = "width: 50%")
)

browsable(tags$div(
  style = "display: flex; flex-wrap: wrap",
  tags$div(miniflex, align = "center", style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p2, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p3, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p4, style = "width: 50%; padding: 1em; border: solid;")#,
  #tags$div(p5, style = "width: 100%; padding: 1em; border: solid;")
))


# this should be easier -- https://github.com/ramnathv/htmlwidgets/issues/226

# flexbox <- function(..., css = "padding: 1em; border: solid;") {
#   dots <- list(...)
#   isWidget <- vapply(dots, function(x) inherits(x, c("htmlwidget", "shiny.tag.list")), logical(1))
#   if (any(!isWidget)) {
#     stop("Must provide htmlwidgets or tagList objects in ...")
#   }
#   divs <- list()
#   for (i in seq_along(dots)) {
#     if (!is.null(dots[[i]]$width)) {
#       css <- paste(sprintf("width: %s;", dots[[i]]$width), css)
#     }
#     divs[[i]] <- tags$div(dots[[i]], style = css)
#   }
#   html_print(
#     tags$div(style = "display: flex; flex-wrap: wrap", divs)
#   )
# }
# 
# wrap(p1, p2, p3)
# 
