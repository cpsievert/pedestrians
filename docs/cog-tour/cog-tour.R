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
cogVars <- colnames(cog)
cog01 <- rescale(cog[, cogVars])
tour <- new_tour(cog01, grand_tour(), NULL)

tour_dat <- function(step_size) {
  step <- tour(step_size)
  proj <- center(cog01 %*% step$proj)
  data.frame(x = proj[,1], y = proj[,2], Name = rownames(cog01))
}

proj_dat <- function(step_size) {
  step <- tour(step_size)
  data.frame(
    x = step$proj[,1], y = step$proj[,2], measure = colnames(cog01)
  )
}

steps <- c(0, rep(1/15, 1000))
stepz <- cumsum(steps)

# tidy version of tour data
tour_dats <- lapply(steps, tour_dat)
tour_datz <- Map(function(x, y) cbind(x, step = y), tour_dats, stepz)
tour_dat <- dplyr::bind_rows(tour_datz)

# tidy version of tour projection data
proj_dats <- lapply(steps, proj_dat)
proj_datz <- Map(function(x, y) cbind(x, step = y), proj_dats, stepz)
proj_dat <- dplyr::bind_rows(proj_datz)

ax <- list(
  title = "", range = c(-1.1, 1.1), 
  zeroline = F, showticklabels = F
)

options(digits = 3)

tour <- tour_dat %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(x = ~x, y = ~y, frame = ~step, color = I("black"), 
          height = 400, width = 700) %>%
  add_markers(text = ~Name, hoverinfo = "text") %>%
  layout(xaxis = ax, yaxis = ax)

axes <- proj_dat %>%
  plot_ly(x = ~x, y = ~y, frame = ~step, hoverinfo = "none") %>%
  add_segments(xend = 0, yend = 0, color = I("gray85")) %>%
  add_text(text = ~measure, color = I("black")) %>%
  layout(xaxis = ax, yaxis = ax)

# very important these animation options are specified _after_ subplot()
# since they call plotly_build(., registerFrames = T)
tour <- subplot(tour, axes, nrows = 1, shareY = T, margin = 0) %>% 
  animation_opts(33) %>%
  hide_legend() %>%
  layout(dragmode = "select") %>%
  highlight(persistent = TRUE)

# set some crosstalk options for leaflet 
options(opacityDim = 0.5, persistent = TRUE)

# for setting map aspect ratio
mapRatio <- with(sensors, diff(range(Longitude)) / diff(range(Latitude)))

map <- sensors %>%
  SharedData$new(~Name, group = "melb") %>%
  leaflet(height = 300, width = 300 * mapRatio) %>% 
  addTiles(attribution = FALSE) %>% 
  fitBounds(
    ~min(Longitude), ~min(Latitude), ~max(Longitude), ~max(Latitude)
  ) %>%
  addCircleMarkers(
    ~Longitude, ~Latitude, layerId = ~Name, label = ~Name, color = "black"
  )

# "standardized" (i.e., mean 0, std dev 1) cognostics
cogSTD <- cog[, cogVars] %>%
  scale() %>%
  data.frame(stringsAsFactors = F) %>%
  mutate(Name = rownames(.)) %>%
  gather(variable, value, -Name)

# TODO: get this working in pure plot_ly() (needs a fix for building group index when x is categorical)
p <- cogSTD %>%
  SharedData$new(~Name, group = "melb") %>%
  ggplot(aes(variable, value, group = Name, text = Name)) + 
    geom_line() + geom_point(size = 0.01) + 
    labs(x = NULL, y = NULL) + theme_bw() +
    theme(axis.text.x = element_text(angle = 45)) 

p2 <- p %>%
  ggplotly(tooltip = "text", height = 300) %>%
  layout(dragmode = "select", margin = list(b = 70)) %>%
  highlight(off = "plotly_deselect", dynamic = TRUE, persistent = TRUE)

# stratisfied random sample of raw data (needed for performance/speed)
# for reproducing the sampled counts
set.seed(9999)
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
  add_ribbons(ymin = ~q1, ymax = ~q3, alpha = 0.5) %>%
  add_lines(y = ~med) %>%
  layout(
    title = "IQR by station vs overall",
    yaxis = list(title = ""), 
    xaxis = list(title = "Hour of Day"),
    dragmode = "zoom"
  ) %>%
  highlight(off = NULL, opacityDim = 0, persistent = TRUE) %>%
  hide_legend()

# TODO: why does take so long with plot_ly()?
gg <- pedSample %>%
  SharedData$new(~Name, group = "melb") %>%
  ggplot(aes(x = lubridate::yday(DateTime) + Hour / 24, text = paste(Name, "<br />", DateTime), 
             y = Counts, group = interaction(Name, Year))) +
  geom_line(alpha = 0.2) +
  facet_wrap(~Year, ncol = 1) +
  labs(x = NULL, y = NULL) + theme_bw()

p5 <- ggplotly(gg, tooltip = "text", height = 800) %>%
  layout(
    title = "Raw Counts (randomly sampled)",
    yaxis = list(title = ""), 
    xaxis = list(title = "Day of year"),
    dragmode = "zoom"
  ) %>%
  highlight(off = "plotly_doubleclick", defaultValues = 1, persistent = TRUE)

html <- tags$div(
  style = "display: flex; flex-wrap: wrap",
  tags$div(map, style = "width: 22%; padding: 1em"),
  tags$div(tour, style = "width: 38%; padding: 1em"),
  tags$div(p2, style = "width: 40%; padding: 1em"),
  tags$div(p3, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p4, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p5, style = "width: 100%; padding: 1em; border: solid;")
)

# opens in an interactive session
res <- html_print(html)

# dir.create("docs/cog-tour")
# TODO: can this be done in a standalone fashion?
file.copy(
  dir(dirname(res), full.names = TRUE), 
  "docs/cog-tour", 
  overwrite = T, recursive = T
)