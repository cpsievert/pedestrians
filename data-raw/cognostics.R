library(dplyr)
library(tidyr)
library(lubridate)
# devtools::install_github("earowang/tscognostics")
library(tscognostics)
# tscognostics should really import this...
library(mgcv)


## Pull data from the web
limit <- 1453000 # all the up-to-date records needs to be retrieved
web_add <- "https://data.melbourne.vic.gov.au/resource/mxb8-wn4w.json?" 
ped_url <- paste0(web_add, "$limit=", limit)
json <- jsonlite::fromJSON(ped_url) # without api token

# tidy up data
pedestrians <- tbl_df(json) %>%
  mutate(
    DateTime = as.POSIXct(strptime(daet_time, "%d-%b-%Y %H:%M")),
    Counts = as.numeric(qv_market_peel_st),
    Name = sensor_name
  ) %>%
  select(DateTime, Counts, Name) %>%
  filter(
    DateTime >= as.POSIXct("2013-01-01 00:00:00")
  ) %>%
  # mainly here to match the description field in the sensor location data
  mutate(
    Name = sub("Chinatown-Lt Bourke St (South)", "Chinatown-Russel St (South)", Name, fixed = T),
    Name = sub("St Kilda Rd-Alexandra Gardens", "St. Kilda Rd-Alexandra Gardens", Name, fixed = T),
    Name = sub("Bourke St-Russell St (West)", "Bourke St-Russel St (West)", Name, fixed = T)
  ) %>%
  # TODO: get sensor location data for SouthBank
  filter(Name != "Southbank")

# expect no missing values
stopifnot(!anyNA(pedestrians))
# TODO: where does the sensort data come from?
load("data/sensors.rda")
# all stations must reside in the sensor location data!
missingSensors <- setdiff(unique(pedestrians$Name), sensors$Description)
stopifnot(length(missingSensors) == 0)

# make missing hours explicit
allHours <- with(pedestrians, seq(from = min(DateTime), to = max(DateTime), by = "hour"))
dat <- setNames(
  data.frame(expand.grid(allHours, unique(pedestrians$Name)), stringsAsFactors = F),
  c("DateTime", "Name")
)

pedestrians <- dat %>%
  left_join(pedestrians) %>%
  mutate(
    Year = year(DateTime),
    Month = month(DateTime),
    Day = day(DateTime),
    Wday = wday(DateTime),
    Weekend = ifelse(Wday %in% c(6, 7), "Weekend", "Weekday"),
    Hour = hour(DateTime)
  )

devtools::use_data(pedestrians, overwrite = T)

## Turn the df to time series
ts_pedestrians <- pedestrians %>%
  select(DateTime, Name, Counts) %>%
  spread(Name, Counts) %>%
  select(-DateTime) %>%
  xts::xts(allHours, frequency = 24)

## Compute cognostics
cog <- tsmeasures(ts_pedestrians, width = 48) # 7*24 = 2 days window
rownames(cog) <- colnames(ts_pedestrians)
devtools::use_data(cog, overwrite = TRUE)

## TODO: where does the sensors data come from?
#sensors$ID <- factor(sensors$ID)
#sensors <- dplyr::semi_join(sensors, pedestrians, by = "ID")
#devtools::use_data(sensors, overwrite = TRUE)
