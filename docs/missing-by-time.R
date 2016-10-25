# devtools::install_github("ropensci/plotly#554")
library(plotly)
library(crosstalk)
library(dplyr)

data(pedestrians, package = "pedestrians")
data(cog, package = "pedestrians")

p1 <- pedestrians %>%
  filter(is.na(Counts)) %>%
  count(Name) %>%
  arrange(n) %>%
  mutate(Name = factor(Name, .[["Name"]])) %>% 
  SharedData$new(~Name, group = "melb") %>%
  plot_ly(y = ~Name, x = ~n, text = ~Name) %>% 
  add_bars(hoverinfo = "text", color = I("black")) %>%
  layout(
    xaxis = list(title = "Number missing"), yaxis = list(title = "")
  )

# stratisfied random sample of raw data (needed for performance/speed)
n <- nrow(pedestrians)
idx <- c()
for (i in unique(pedestrians$Name)) {
  idx <- c(idx, sample(which(pedestrians$Name %in% i), n * 0.001))
}
pedSample <- pedestrians[idx, ]

# TODO: why does take so long with plot_ly()?
gg <- pedSample %>%
  SharedData$new(~Name, group = "melb") %>%
  ggplot(aes(x = lubridate::yday(DateTime) + Hour / 24, text = Name,
             y = Counts, group = interaction(Name, Year))) +
  geom_line(alpha = 0.1) +
  facet_wrap(~Year, ncol = 1) +
  labs(x = NULL, y = NULL)

p2 <- ggplotly(gg, tooltip = "text", height = 800) %>%
  layout(
    yaxis = list(title = ""), 
    xaxis = list(title = "Day of year"),
    dragmode = "zoom"
  )

s <- subplot(p1, p2, titleX = TRUE) %>%
  layout(
    margin = list(l = 300, b = 50), 
    barmode = "overlay"
  ) %>%
  highlight("plotly_click", color = "red")

owd <- setwd("docs/missing-by-time")
htmlwidgets::saveWidget(s, "index.html")
if (interactive()) browseURL("index.html")
setwd(owd)