string2formula <- function(x) {
  as.formula(paste0("~", x))
}


ts_summary <- function(x = "Hour", ids = c(1, 2, 3), colors = c("red", "red", "blue")) {
  
  if (length(x) != 1 || !x %in% names(pedestrians)) {
    stop(
      "`x` must be one of the following:", 
      paste(names(pedestrians), collapse = ", "),
      call. = FALSE
    )
  }
  
  # doesn't make sense to display summaries for every day
  if ("DateTime" == x) {
    pedestrians <- mutate(pedestrians, YearMonth = as.numeric(paste0(Year, Month, sep = ".")))
    x <- "YearMonth"
  }
  
  add_summary <- function(p, ids = NULL, color = "black") {
    if (!is.null(ids)) {
      pedestrians <- filter(pedestrians, ID %in% ids)
    }
    p %>%
      add_data(pedestrians) %>%
      group_by_(x) %>%
      summarise(
        min = min(Counts),
        q1 = quantile(Counts, 0.25),
        med = median(Counts),
        q3 = quantile(Counts, 0.75),
        max = max(Counts)
      ) %>%
      add_ribbons(
        ymin = ~min, ymax = ~max, name = "Range", hoverinfo = "none",
        fillcolor = toRGB(color, 0.1), line = list(color = color)
      ) %>%
      add_ribbons(
        ymin = ~q1, ymax = ~q3, name = "IQR", hoverinfo = "none",
        fillcolor = toRGB(color, 0.5), line = list(color = color)
      ) %>%
      add_lines(y = ~med, line = list(color = color), name = "median")
  }
  
  # always plot the overall summary
  p <- plot_ly(x = string2formula(x)) %>% add_summary(color = "black") 
  
  if (!length(ids) || !length(colors)) {
    return(p)
  }
  
  for (i in unique(colors)) {
    p <- p %>% add_summary(ids = ids[colors %in% i], color = i)
  }
  
  p
  
}

