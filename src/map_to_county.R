library(measurements)
library(dplyr)
library(sf)
library(tidyverse)
# library(ggplot2)


map_to_county <-
  function(aoi_boundary_shp_filename,
           variable,
           long,
           lat) {
    if (all(
      c(
        length(long),
        length(lat)
        ) == length(variable)
    )) {
      data <- as.data.frame(cbind(variable,long,lat))
      colnames(data) <- c("variable","long","lat")
      
      ## transform coordinate !!!
      aoi_boundary_HARV <- read_sf(aoi_boundary_shp_filename)
      aoi_boundary_HARV$geometry <- st_transform(aoi_boundary_HARV$geometry, 4326)
      
      # ## Plot a overview map
      # # png("map_station_county.png", width = 960, height = 960)
      # ggplot()+
      #   geom_sf(data=aoi_boundary_HARV$geometry)+
      #   geom_point(aes(long, lat))
      # # dev.off()
      
      ## You can put other useful columns in the long_lat data frame as well.
      heat_sf <- data %>%
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
      point_within_county <- data.frame("variable"=point_within_county$variable,
                                        "county"=point_within_county$NAME,
                                        "geometry"=point_within_county$geometry) 
      return(point_within_county)
    } else {
      stop ("Input values do not have the same length.")
    }
    
  }

# ## test 1
# aoi_boundary_shp_filename <- "CA_Counties_TIGER2016.shp"
# heat_txt_file <- "heat_map.txt"
# lat_txt_file  <- "lat_mat.txt"
# long_txt_file  <- "long_mat.txt"
# 
# sup_heat_txt_file <- "sup_heat_map.txt"
# sup_lat_txt_file  <- "sup_lat_mat.txt"
# sup_long_txt_file  <- "sup_long_mat.txt"
# 
# heatmap <- as.matrix(read.table(heat_txt_file,sep=","))
# lat <- as.matrix(read.table(lat_txt_file,sep=","))
# long <- as.matrix(read.table(long_txt_file,sep=","))
# 
# sup_heatmap <- as.matrix(read.table(sup_heat_txt_file,sep=","))
# sup_lat <- as.matrix(read.table(sup_lat_txt_file,sep=","))
# sup_long <- as.matrix(read.table(sup_long_txt_file,sep=","))
# 
# ## Convert Matrix to Vector, record each entry from the original matrix plot as an observation
# heatmap_vec <- c(as.vector(heatmap),as.vector(sup_heatmap))
# lat_vec <- c(as.vector(lat),as.vector(sup_lat))
# long_vec <- c(as.vector(long),as.vector(sup_long))
# 
# ## remove the NA observations
# idx_na <- which(heatmap_vec==0)
# heatmap_vec <- heatmap_vec[-idx_na]
# lat_vec <- lat_vec[-idx_na]
# long_vec <- long_vec[-idx_na]
# 
# point_within_county <- map_to_county(aoi_boundary_shp_filename,
#               heatmap_vec,
#               long_vec,
#               lat_vec)
# 
# 
# ## test 2
# library(stringr)
# monitoring_station_csv_filename <- "CA_monitoring_station.csv"
# monitoring_station <- read.csv(monitoring_station_csv_filename)
# monitoring_station <-  # overkill the repetitions
#   monitoring_station %>% 
#   group_by(name) %>%
#   summarize(code = min(code, na.rm = TRUE),
#             Longitude = min(Longitude, na.rm = TRUE),
#             Latitude = min(Latitude, na.rm = TRUE))
# 
# transform_long_lat <- function(str){
#   str <- str_replace_all(str, "°", "")
#   str <- str_replace_all(str, "\'", "")
#   str <- str_replace_all(str, "\"", "")
#   dec_str <- as.numeric(conv_unit(str, from = "deg_min_sec", to = "dec_deg"))
#   return(dec_str)
# }
# 
# code <- monitoring_station$code
# lat <- transform_long_lat(monitoring_station$Latitude)
# long <-  -transform_long_lat(monitoring_station$Longitude)
# 
# point_within_county <- map_to_county(aoi_boundary_shp_filename,
#                                      code,
#                                      long,
#                                      lat)
