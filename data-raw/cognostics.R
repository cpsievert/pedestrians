# devtools::install_github("earowang/tscognostics")
library(dplyr)
library(jsonlite)
library(lubridate)
library(tscognostics)

## Pull data from the web
limit <- 1453000 # all the up-to-date records needs to be retrieved
web_add <- "https://data.melbourne.vic.gov.au/resource/mxb8-wn4w.json?" 
ped_url <- paste0(web_add, "$limit=", limit)
pedestrians <- fromJSON(ped_url) # without api token
pedestrians <- tbl_df(pedestrians)
colnames(pedestrians) <- c("DateTime", "Counts", "SensorID", "SensorName")
pedestrians <- pedestrians %>%
  mutate(DateTime = as.POSIXct(strptime(pedestrians$DateTime, "%d-%b-%Y %H:%M")),
         Counts = as.integer(Counts), SensorID = factor(SensorID))

## Look at data from 2013 Jan to 2016 Jan
pedestrians <- pedestrians %>%
  filter(DateTime >= as.POSIXct("2013-01-01 00:00:00") &
         DateTime <= as.POSIXct("2016-01-31 23:00:00"))

## Data cleaning
pedestrians <- pedestrians %>%
  mutate(SensorName = ifelse(SensorName == "Lygon St (West)",
                             "Lygon Street (West)", 
                             SensorName))
pedestrians <- pedestrians %>%
  mutate(SensorName = ifelse(SensorName == "Lonsdale St (South)",
                             "Lonsdale Street (South)", 
                             SensorName))
pedestrians <- pedestrians %>%
  mutate(SensorName = ifelse(SensorName == "Bourke St-Russel St (West)",
                             "Bourke St-Russell St (West)", 
                             SensorName))

## Adding new variables
names(pedestrians) <- sub("^Sensor", "", names(pedestrians))
pedestrians <- pedestrians %>% 
  mutate(Year = year(DateTime)) %>%
  mutate(Month = month(DateTime)) %>%
  mutate(Day = day(DateTime)) %>%
  mutate(Wday = wday(DateTime)) %>%
  mutate(Weekend = ifelse(Wday %in% c(6, 7), "Weekend", "Weekday")) %>%
  mutate(Hour = hour(DateTime))

devtools::use_data(pedestrians, overwrite = T)

## Turn the df to time series
dates <- sort(unique(pedestrians$DateTime))
ids <- as.numeric(unique(pedestrians$ID))
ts_pedestrians <- matrix(NA, nrow = length(dates), ncol = length(ids))
for (i in seq_along(ids)) {
  tmp <- subset(pedestrians, ID == ids[i])
  j <- is.element(dates, tmp$DateTime)
  ts_pedestrians[j, i] <- tmp$Counts
}
ts_pedestrians <- ts(ts_pedestrians, frequency = 24)

## Computate cognostics
cog <- tsmeasures(ts_pedestrians, width = 48) # 7*24 = 2 days window
cog <- as.data.frame(cog)
cog$ID <- factor(ids)
devtools::use_data(cog, overwrite = TRUE)


## TODO: where does the sensors data come from?
sensors$ID <- factor(sensors$ID)
sensors <- dplyr::semi_join(sensors, pedestrians, by = "ID")
devtools::use_data(sensors, overwrite = TRUE)
