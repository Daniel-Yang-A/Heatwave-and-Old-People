library(measurements)
library(stringr)
library(dplyr)
library(sf)
library(tidyverse)
library(ggplot2)

## self-defined input files: You can modify the input files to generate a new case study
## 1. a set of files including heatmap, latitude, longitude information respectively. 
heat_txt_file <- "../data/raw/heat_map.txt"
lat_txt_file  <- "../data/raw/lat_mat.txt"
long_txt_file  <- "../data/raw/long_mat.txt"

sup_heat_txt_file <- "../data/raw/sup_heat_map.txt"
sup_lat_txt_file  <- "../data/raw/sup_lat_mat.txt"
sup_long_txt_file  <- "../data/raw/sup_long_mat.txt"

## 2. a shp document and its auxiliary document that contains county geometry boundary information
aoi_boundary_shp_filename <- "../data/raw/CA_Counties_TIGER2016.shp"

## self-defined output filenames and database info
heat_point_within_county_csv_filename <- "heat_point_within_county.csv"
countywise_Heatmap_csv_filename <- "countywise_Heatmap.csv"

## read in the heat information and geomatric information
heatmap <- as.matrix(read.table(heat_txt_file,sep=","))
lat <- as.matrix(read.table(lat_txt_file,sep=","))
long <- as.matrix(read.table(long_txt_file,sep=","))

sup_heatmap <- as.matrix(read.table(sup_heat_txt_file,sep=","))
sup_lat <- as.matrix(read.table(sup_lat_txt_file,sep=","))
sup_long <- as.matrix(read.table(sup_long_txt_file,sep=","))

## Convert Matrix to Vector, record each entry from the original matrix plot as an observation
heatmap_vec <- c(as.vector(heatmap),as.vector(sup_heatmap))
lat_vec <- c(as.vector(lat),as.vector(sup_lat))
long_vec <- c(as.vector(long),as.vector(sup_long))

## combine three columns together to construct a new matrix with three columns:
## 1. heat
## 2. latitude
## 3. longitide
heatmap <- as.data.frame(cbind(heatmap_vec,lat_vec,long_vec))
colnames(heatmap) <- c("heat","lat","long")

## remove the abnormal observation (with heat<=0)
heatmap <- heatmap[heatmap$heat > 0, ]
lat <- heatmap$lat
long <- heatmap$long

## transform coordinate !!!
aoi_boundary_HARV <- read_sf(aoi_boundary_shp_filename)
aoi_boundary_HARV$geometry <- st_transform(aoi_boundary_HARV$geometry, 4326)

## Plot a overview map
# png("map_station_county.png", width = 960, height = 960)
ggplot()+
  geom_sf(data=aoi_boundary_HARV$geometry)+
  geom_point(aes(long, lat))
# dev.off()

## You can put other useful columns in the long_lat data frame as well.
heat_sf <- heatmap %>%
  mutate_at(vars(long, lat), as.numeric) %>%   # coordinates must be numeric
  st_as_sf(
    coords = c("long", "lat"),
    agr = "constant",
    crs = 4326,
    stringsAsFactors = FALSE,
    remove = TRUE
  )

point_in_county <- st_join(heat_sf, aoi_boundary_HARV, join = st_within)
point_within_county <- point_in_county[!is.na(point_in_county$NAME),]
point_within_county <- data.frame("heat"=point_within_county$heat,
                                  "county"=point_within_county$NAME,
                                  "geometry"=point_within_county$geometry)

## write out the processed heatmap within counties
write.csv(point_within_county, file = heat_point_within_county_csv_filename, row.names = FALSE)

## Feature Engineering (Aggregate pointwise data into countywise data)
countywise_Heatmap <- point_within_county %>%
  group_by(county) %>%
  summarize(avg_heatmap = mean(heat,na.rm=TRUE),
            var_heatmap = var(heat,na.rm=TRUE))

## Write the processed data into RMDBS and store it as a csv
write.csv(countywise_Heatmap, file = countywise_Heatmap_csv_filename, row.names = FALSE)
# dbWriteTable(mysqlconnection, name="countywise_Heatmap", value=countywise_Heatmap, row.names = FALSE, overwrite=TRUE)
