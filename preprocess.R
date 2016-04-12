library(readr)
library(dplyr)
library(lubridate)

pedestrian <- read_csv(
  "data/Pedestrian_Counts.csv",
  col_names = c("DateTime", "SensorID", "SensorName", "Counts"), 
  skip = 1
)

pedestrian <- pedestrian %>% 
  mutate(DateTime = as.POSIXct(DateTime, format = "%d-%b-%Y %H:%M")) %>%
  mutate(Year = year(DateTime)) %>%
  mutate(Month = month(DateTime)) %>%
  mutate(Day = day(DateTime)) %>%
  mutate(Hour = hour(DateTime)) %>%
  # minutes are all zero
  #mutate(Minute = minute(DateTime)) %>%
  # Data is inconsistent before 2013 (also, some dates pre-2013 have parsing trouble)
  filter(!is.na(DateTime), Year >= 2013)

feather::write_feather(pedestrian, "pedestrians.feather")

sensors <- read_csv("data/Pedestrian_Sensor_Locations.csv")
feather::write_feather(sensors, "sensors.feather")

cog <- read_csv("data/pedestrian-cognostics.csv")
feather::write_feather(cog, "cognostics.feather")
