library(measurements)
library(stringr)
library(dplyr)
library(sf)
library(tidyverse)
library(ggplot2)

## self-defined input files: You can modify the input files to generate a new case study
## 1. a monitoring station geometric information csv: should include
###  1) a column "name" for the name of that monitoring station
###  2) a column "Longitude" for the longitude of that monitoring station (form: xx°xx'xx")
###  2) a column "Latitude" for the latitude of that monitoring station (form: xx°xx'xx")
monitoring_station_csv_filename <- "CA_monitoring_station.csv"
## 2. a shp document and its auxiliary document that contains county geometry boundary information
aoi_boundary_shp_filename <- "CA_Counties_TIGER2016.shp"
## 3. a processed station-wise daily Heat Index (HI) & Wet Bulb Globe Temperature (WBGT) document
HI_WBGT_stationwise_csv_filename <- "processed_HI_WBGT_2011_2015.csv"

## self-defined output filenames and database info
countywise_HI_WBGT_csv_filename <- "countywise_HI_WBGT_2011_2015.csv"

monitoring_station <- read.csv(monitoring_station_csv_filename)
monitoring_station <-  # overkill the repetitions
  monitoring_station %>% 
  group_by(name) %>%
  summarize(code = min(code, na.rm = TRUE),
            Longitude = min(Longitude, na.rm = TRUE),
            Latitude = min(Latitude, na.rm = TRUE))

## define a function to transform the longitude and latitude form from xx°xx'xx" to decimal degree
str_transform <- function(str){
  str <- str_replace_all(str, "°", "")
  str <- str_replace_all(str, "\'", "")
  str <- str_replace_all(str, "\"", "")
  dec_str <- as.numeric(conv_unit(str, from = "deg_min_sec", to = "dec_deg"))
  return(dec_str)
}

lat <- str_transform(monitoring_station$Latitude)
long <-  str_transform(monitoring_station$Longitude)
long_lat <- data.frame("name"=monitoring_station$name,
                       "code"=monitoring_station$code,
                       "long"=-long,
                       "lat"=lat)

## transform coordinate !!!
aoi_boundary_HARV <- read_sf(aoi_boundary_shp_filename)
aoi_boundary_HARV$geometry <- st_transform(aoi_boundary_HARV$geometry, 4326)

## Plot a overview map
# png("map_station_county.png", width = 960, height = 960)
ggplot()+
  geom_sf(data=aoi_boundary_HARV$geometry)+
  geom_point(aes(-long, lat))
# dev.off()

## You can put other useful columns in the long_lat data frame as well.
sta_sf <- long_lat %>%
  mutate_at(vars(long, lat), as.numeric) %>%   # coordinates must be numeric
  st_as_sf(
    coords = c("long", "lat"),
    agr = "constant",
    crs = 4326,
    stringsAsFactors = FALSE,
    remove = TRUE
  )

(station_in_county <- st_join(sta_sf, aoi_boundary_HARV, join = st_within))

## Join the station in county table and processed WBGT stationwise data
HI_WBGT_stationwise <- read.csv(HI_WBGT_stationwise_csv_filename)
county_in_station_HI_WBGT <- 
  left_join(HI_WBGT_stationwise, station_in_county, by=c("Station_name"="name"))

## Feature Engineering (Aggregate stationwise data into countywise data)
countywise_HI_WBGT <- county_in_station_HI_WBGT %>%
  group_by(Year, Month, NAME) %>%
  summarize(avg_WBGT_max_monthly = mean(avg_WBGT_max_monthly,na.rm=TRUE),
            max_WBGT_max_monthly = max(max_WBGT_max_monthly,na.rm=TRUE),
            duration_heat_wave_monthly = mean(duration_heat_wave_monthly,na.rm=TRUE),
            avg_heat_waves_WBGT_max_monthly = mean(avg_heat_waves_WBGT_max_monthly,na.rm=TRUE))

## Write the processed data into RMDBS and store it as a csv
write.csv(countywise_HI_WBGT, file = countywise_HI_WBGT_csv_filename, row.names = FALSE)
# dbWriteTable(mysqlconnection, name="countywise_HI_WBGT", value=data_month, row.names = FALSE, overwrite=TRUE)
