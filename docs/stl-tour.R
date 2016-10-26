# devtools::install_github("ropensci/plotly#554")
library(plotly)
library(crosstalk)
library(htmltools)
library(dplyr)
library(tidyr)
library(tourr)

data(pedestrians, package = "pedestrians")
data(cog, package = "pedestrians")

# tour of stl() influenced time-series cognostics
cogVars <- c("trend", "curvature", "linearity", "season", "peak", "trough")
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

steps <- c(0, rep(1/15, 500))
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

#options(digits = 3)

tour <- tour_dat %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(x = ~x, y = ~y, frame = ~step, color = I("black"), 
          height = 400, width = 800) %>%
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
  animationOpts(33, 0) %>%
  animationSlider(hide = TRUE) %>%
  hide_legend() %>%
  layout(dragmode = "select") %>%
  highlight(persistent = TRUE)

# "standardized" (i.e., mean 0, std dev 1) cognostics
cogSTD <- cog[, cogVars] %>%
  scale() %>%
  data.frame(stringsAsFactors = F) %>%
  mutate(Name = rownames(.)) %>%
  gather(variable, value, -Name) %>%
  mutate(variable = factor(variable, cogVars))

# TODO: get this working in pure plot_ly() (needs a fix for building group index when x is categorical)
p <- cogSTD %>%
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(height = 400) %>% 
  ggplot(aes(variable, value, group = Name, text = Name)) + 
  geom_line() + geom_point(size = 0.01) + 
  theme(axis.text.x = element_text(angle = 45)) + 
  labs(x = NULL, y = NULL)

p2 <- p %>%
  ggplotly(tooltip = "text", height = 400) %>%
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
          color = I("black"), alpha = 0.01, height = 400, hoverinfo = "text") %>% 
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

p4 <- plot_ly(byHour, x = ~Hour, color = I("black"), height = 400) %>%
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
  highlight(off = NULL, opacityDim = 0, persistent = TRUE) %>%
  hide_legend()

html <- tags$div(
  style = "display: flex; flex-wrap: wrap",
  tags$div(tour, align = "center", style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p2, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p3, style = "width: 50%; padding: 1em; border: solid;"),
  tags$div(p4, style = "width: 50%; padding: 1em; border: solid;")
)

# opens in an interactive session
res <- html_print(html)

# dir.create("docs/stl-tour")
# TODO: can this be done in a standalone fashion?
file.copy(
  dir(dirname(res), full.names = TRUE), 
  "docs/stl-tour", 
  overwrite = T, recursive = T
)