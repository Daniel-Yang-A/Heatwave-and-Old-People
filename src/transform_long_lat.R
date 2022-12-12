library(stringr)
library(measurements)

# Since the geometric information in our file is str format and hard to compare
# we then define a function to transform the longitude and latitude form 
# from xx°xx'xx" to decimal degree.
transform_long_lat <- function(str){
  str <- str_replace_all(str, "°", "")
  str <- str_replace_all(str, "\'", "")
  str <- str_replace_all(str, "\"", "")
  dec_str <- as.numeric(conv_unit(str, from = "deg_min_sec", to = "dec_deg"))
  return(dec_str)
}

# ## test
# monitoring_station_csv_filename <- "CA_monitoring_station.csv"
# monitoring_station <- read.csv(monitoring_station_csv_filename)
# monitoring_station <-  # overkill the repetitions
#   monitoring_station %>%
#   group_by(name) %>%
#   summarize(code = min(code, na.rm = TRUE),
#             Longitude = min(Longitude, na.rm = TRUE),
#             Latitude = min(Latitude, na.rm = TRUE))
# lat <- transform_long_lat(monitoring_station$Latitude)
# long <- -transform_long_lat(monitoring_station$Longitude)
# print(head(cbind(long,lat)))