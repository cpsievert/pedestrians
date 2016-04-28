#' Pedestrian counts
#'
#' A dataset containing pedestrian counts at various locations in the 
#' CBD area of Melbourne Australia between 2013 and 2016
#'
#' @format A data frame with 831,639 rows with the following variables:
#' \itemize{
#'   \item DateTime: A date time when the count 
#'   \item ID: An id for the sensor location.
#'   \item Name: The name of the sensor.
#'   \item Counts: The number of pedestrians who walked by the sensor within the hour.
#'   \item Month: The month.
#'   \item Year: The year.
#'   \item Day: The day.
#'   \item Wday: The day of the week.
#'   \item Weekend: Is this a weekend?
#'   \item Hour: The hour.
#' }
"pedestrians"

#' Sensor Locations
#'
#' A dataset containing information about each sensor.
#'
#' @format A data frame with 44 rows with the following variables:
#' \itemize{
#'   \item ID: An id for the sensor location.
#'   \item Name: The name of the sensor.
#'   \item Description: A description of the sensor.
#'   \item Status: Is this sensor installed?
#'   \item Upload Date:
#'   \item Year Installed: 
#'   \item Location Type:
#'   \item Geometry:
#'   \item Latitude:
#'   \item Longitude:
#' }
"sensors"


#' Sensor Locations
#'
#' A dataset containing time series cognostics for each sensor
#'
#' @format A data frame with 44 rows with the following variables:
#' \itemize{
#'   \item ID: An id for the sensor.
#' }
"cog"