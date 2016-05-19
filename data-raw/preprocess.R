library(readr)
library(dplyr)
library(lubridate)

pedestrians <- read_csv(
  "data-raw/Pedestrian_Counts.csv",
  col_names = c("DateTime", "SensorID", "SensorName", "Counts"), 
  skip = 1
)
names(pedestrians) <- sub("^Sensor", "", names(pedestrians))
pedestrians$Month <- format(pedestrians$DateTime, format = "%b")

pedestrians <- pedestrians %>% 
  mutate(DateTime = as.POSIXct(DateTime, format = "%d-%b-%Y %H:%M")) %>%
  mutate(Year = year(DateTime)) %>%
  mutate(Month = month(DateTime)) %>%
  mutate(Day = day(DateTime)) %>%
  mutate(Wday = wday(DateTime)) %>%
  mutate(Weekend = ifelse(Wday %in% c(6, 7), "Weekend", "Weekday")) %>%
  mutate(Hour = hour(DateTime)) %>%
  # minutes are all zero
  #mutate(Minute = minute(DateTime)) %>%
  # Data is inconsistent before 2013 (also, some dates pre-2013 have parsing trouble)
  filter(!is.na(DateTime), Year >= 2013)

devtools::use_data(pedestrians, overwrite = T)

sensors <- read_csv("data-raw/Pedestrian_Sensor_Locations.csv")
names(sensors) <- sub("^Sensor ", "", names(sensors))
# there are some sensors that don't have any pedestrian data
sensors2 <- semi_join(sensors, pedestrians, by = "ID")
devtools::use_data(sensors, overwrite = T)

cog <- read_csv("data-raw/pedestrian-cognostics.csv")
names(cog) <- c("ID", names(cog)[-1])
devtools::use_data(cog, overwrite = T)
