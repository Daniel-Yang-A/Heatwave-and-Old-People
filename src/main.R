source("../src/HI_WBGT_cal.R")
source("../src/month_summary.R")
source("../src/station_to_county.R")
source("../src/map_to_county.R")

## user-defined input
# list all the name of the station daily temperature and relative humidity files here.
# It should include "Station_name", "Year", "Month", "Date", "Air_Temperature_max", "Relative_Humidity_min" columns
input_file_names <- c("2011_0_100.csv","2011_101_200.csv","2011_201_300.csv",
                      "2011_301_400.csv","2011_401_500.csv","2011_501_555.csv",
                      "2012_0_185.csv","2012_185_370.csv","2012_370_555.csv",
                      "2013_0_185.csv","2013_185_336.csv","2013_336_555.csv",
                      "2014_0_190.csv","2014_190_380.csv","2014_380_555.csv",
                      "2015_0_185.csv","2015_185_310.csv","2015_310_435.csv","2015_435_555.csv")

# read data
bydailybystation <- data.frame()
for (i in input_file_names) {
  bydailybystation <- rbind(bydailybystation, read.csv(paste("../data/raw/",i,sep=""), header=FALSE))
}
colnames(bydailybystation) <- c("Station_name", "Year", "Month", "Date", "Air_Temperature_max", "Relative_Humidity_min")

# Drop abnormal data
bydailybystation <- bydailybystation[bydailybystation$Air_Temperature_max>=30,]
bydailybystation <- bydailybystation[(bydailybystation$Relative_Humidity_min<=100 & bydailybystation$Relative_Humidity_min>=0),]

# Calculate temperature index
temperature_index <- HI_WBGT_cal(bydailybystation$Air_Temperature_max, bydailybystation$Relative_Humidity_min)
bydailybystation$HI_max <- temperature_index[[1]]
bydailybystation$WBGT_max <- temperature_index[[2]]

# Summarize by month
bymonthbystation <- month_summary(bydailybystation$Year, bydailybystation$Month, bydailybystation$Station_name, bydailybystation$WBGT_max)

# Summarize by county
bymonthbycounty <- station_to_county(bymonthbystation$year, bymonthbystation$month, bymonthbystation$station, bymonthbystation$avg_WBGT_max_monthly, bymonthbystation$max_WBGT_max_monthly, bymonthbystation$duration_heat_wave_monthly, bymonthbystation$avg_heat_waves_WBGT_max_monthly)

# ------------------------------------------------------------
# heatwave
monitoring_station_csv_filename <- "../data/raw/CA_monitoring_station.csv"
monitoring_station <- read.csv(monitoring_station_csv_filename, fileEncoding="latin1")
monitoring_station <-  # overkill the repetitions
  monitoring_station %>%
  group_by(name) %>%
  summarize(code = min(code, na.rm = TRUE),
            Longitude = min(Longitude, na.rm = TRUE),
            Latitude = min(Latitude, na.rm = TRUE))

str_transform <- function(str){
  str <- str_replace_all(str, "¡ã", "")
  str <- str_replace_all(str, "\'", "")
  str <- str_replace_all(str, "\"", "")
  dec_str <- as.numeric(conv_unit(str, from = "deg_min_sec", to = "dec_deg"))
  return(dec_str)
}

code <- monitoring_station$code
lat <- str_transform(monitoring_station$Latitude)
long <-  -str_transform(monitoring_station$Longitude)

point_within_county <- map_to_county(aoi_boundary_shp_filename,
                                     code,
                                     long,
                                     lat)


# ----------------------------------------------------------------------
# heat island
aoi_boundary_shp_filename <- "../data/raw/CA_Counties_TIGER2016.shp"
heat_txt_file <- "../data/raw/heat_map.txt"
lat_txt_file  <- "../data/raw/lat_mat.txt"
long_txt_file  <- "../data/raw/long_mat.txt"

sup_heat_txt_file <- "../data/raw/sup_heat_map.txt"
sup_lat_txt_file  <- "../data/raw/sup_lat_mat.txt"
sup_long_txt_file  <- "../data/raw/sup_long_mat.txt"

heatmap <- as.matrix(read.table(heat_txt_file,sep=","))
lat <- as.matrix(read.table(lat_txt_file,sep=","))
long <- as.matrix(read.table(long_txt_file,sep=","))

sup_heatmap <- as.matrix(read.table(sup_heat_txt_file,sep=","))
sup_lat <- as.matrix(read.table(sup_lat_txt_file,sep=","))
sup_long <- as.matrix(read.table(sup_long_txt_file,sep=","))

# Convert Matrix to Vector, record each entry from the original matrix plot as an observation
heatmap_vec <- c(as.vector(heatmap),as.vector(sup_heatmap))
lat_vec <- c(as.vector(lat),as.vector(sup_lat))
long_vec <- c(as.vector(long),as.vector(sup_long))

# remove the NA observations
idx_na <- which(heatmap_vec==0)
heatmap_vec <- heatmap_vec[-idx_na]
lat_vec <- lat_vec[-idx_na]
long_vec <- long_vec[-idx_na]

point_within_county <- map_to_county(aoi_boundary_shp_filename,
              heatmap_vec,
              long_vec,
              lat_vec)

point_within_county
