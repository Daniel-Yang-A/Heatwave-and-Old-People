source("../src/HI_WBGT_cal.R")
source("../src/month_summary.R")
source("../src/station_to_county.R")
source("../src/map_to_county.R")
source("../src/gdn.R")

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

aoi_boundary_shp_filename <- "../data/raw/CA_Counties_TIGER2016.shp"
point_within_county <- map_to_county(aoi_boundary_shp_filename,
                                     code,
                                     long,
                                     lat)


# ----------------------------------------------------------------------
# heat island
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

# regression
## regression 1: heat wave data and death-related data
library(dplyr)
library(tidyr)

death <- read.csv("../preprocessed/death.csv")
elderly <- read.csv("../preprocessed/cal_census_2011_to_2015.csv")
HI_WBGT <- read.csv("../preprocessed/countywise_HI_WBGT_2011_2015.csv")

# data manipulation
HI_WBGT$Year <- as.integer(HI_WBGT$Year)
HI_WBGT$Month <- as.integer(HI_WBGT$Month)

# join the HI_WBGT table and the death profile by year, month and county name
heat_death <- HI_WBGT %>% inner_join( death, 
                                      by=c("Year"="year","Month"="month","NAME"="county"))


# join the processed table and the elderly information table by year and county name
heat_death <- heat_death %>% left_join( elderly,
                                        by=c("Year"="Year","NAME"="County"))

# add columns to record the death rate
heat_death <- heat_death %>% 
  mutate( death_rate = death / total,
          death_elder_rate = death / elderly )

# remove the outliners
heat_death <- heat_death[heat_death$death_elder_rate <= 0.5,]

## Write the processed data into RMDBS and store it as a csv
# write.csv(heat_death, file = "heat_death_2011_2015.csv", row.names = FALSE)

standardize <- function(col){
  sample_mean <- mean(col,na.rm=TRUE)
  sd <- sqrt(var(col,na.rm = TRUE))
  return((col-sample_mean)/sd)
}

standard_heat_death <- heat_death 
for (i in 4:ncol(heat_death)){
  standard_heat_death[,i] <- standardize(heat_death[,i])
}

# relationship between the death rate and the intensity of heat wave 
# (within county that have at least 1 heat waves in one month)
m1 <- lm(death_rate ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly +
           duration_heat_wave_monthly + 
           avg_heat_waves_WBGT_max_monthly, data = standard_heat_death)
summary(m1)

# relationship between the death elder rate and the intensity of heat wave 
# (within county that have at least 1 heat waves in one month)
m2 <- lm(death_elder_rate ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly +
           duration_heat_wave_monthly + 
           avg_heat_waves_WBGT_max_monthly
         , data = standard_heat_death)
summary(m2)

# relationship between the death rate and the intensity of heat wave 
# (including all the counties)
m3 <- lm(death_rate ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly, data = standard_heat_death)
summary(m3)

# relationship between the death elder rate and the intensity of heat wave 
# (including all the counties)
m4 <- lm(death_elder_rate ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly, data = standard_heat_death)
summary(m4)

# relationship between the elder proportion and the intensity of heat wave 
# (within county that have at least 1 heat waves in one month)
m5 <- lm(elder_proportion ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly +
           duration_heat_wave_monthly + 
           avg_heat_waves_WBGT_max_monthly, data = standard_heat_death)
summary(m5)

# relationship between the total population and the intensity of heat wave 
# (within county that have at least 1 heat waves in one month)
m6 <- lm(total ~ 
           avg_WBGT_max_monthly + 
           max_WBGT_max_monthly +
           duration_heat_wave_monthly + 
           avg_heat_waves_WBGT_max_monthly, 
         data = standard_heat_death)
summary(m6)


## regression 2: heat wave data and death data of each cause of death
data1 = read.csv("../data/raw/2021-05-14_deaths_final_2009-2013_occurrence_county_month_sup.csv")
data2 = read.csv("../data/raw/2021-11-29_deaths_final_2014-2018_occurrence_county_month_sup.csv")

# This function extracts the death number of every cause of death by month by county.
disease <- function(dataset, year) {
  dataset[is.na(dataset)]=0
  set<-c()
  county_name<-unique(dataset$County)
  month<-unique(dataset$Month)
  d = data.frame(matrix(nrow = 0,ncol = 15))
  colnames(d)<-unique(dataset$Cause_Desc)
  for (j in month) {
    for (i in county_name) {
      elderly_death<-dataset$Count[dataset$County==i&dataset$Year==year&dataset$Month==j
                                   &dataset$Strata=="Total Population"]
      
      d = rbind(d,elderly_death)
    }
  }
  df=data.frame(county=rep(county_name,12),
                year=rep(year,12*length(county_name)),
                month=rep(1:12,each=length(county_name)))
  df=cbind(df,d)
  colnames(df)<-c("county","year","month",unique(data1$Cause_Desc))
  return(df)
}

# Death number of year from 2011 to 2015
d2011<-disease(data1,2011)
d2012<-disease(data1,2012)
d2013<-disease(data1,2013)
d2014<-disease(data2,2014)
d2015<-disease(data2,2015)
disease<-rbind(d2011,d2012,d2013,d2014,d2015)

# merged the heat index table and the disease statitics table
heat_index = read.csv('../data/preprocessedheat_death_2011_2015.csv')
colnames(heat_index)[1:3]=c('year','month','county')
merged = merge(heat_index, disease, by = c('year','month','county'))

# To reduce the variance and increase the accuracy, we deleted the county with a very small population
table_big = merged[merged$total>100000,]
table_big[is.na(table_big)]=0
m1 = lm(death/`All causes (total)`~avg_WBGT_max_monthly+max_WBGT_max_monthly+duration_heat_wave_monthly+avg_heat_waves_WBGT_max_monthly,data = table_big)
summary(m1)

# The respective analysis of causes of death
table_b = table_big[,c(4:7,14:28)]
df1 = data.frame(matrix(nrow=0,ncol=2))
df2 = data.frame(matrix(nrow=0,ncol=2))
for (i in colnames(table_b)[5:19]) {
  m = lm(table_b[,i]/table_big$elderly~avg_WBGT_max_monthly+max_WBGT_max_monthly+
           duration_heat_wave_monthly+avg_heat_waves_WBGT_max_monthly,data = table_b)
  a = summary(m)$coefficients[3,c(1,4)]
  df1 = rbind(df1,a)
  b = summary(m)$coefficients[2,c(1,4)]
  df2 = rbind(df2,b)
}
colnames(df1)<-c('max_WBGT_max_monthly', 'p-value')
rownames(df1)<-colnames(table_b)[5:19]
print(df1)
colnames(df2)<-c('avg_WBGT_max_monthly', 'p-value')
rownames(df2)<-colnames(table_b)[5:19]
print(df2)

## regression 3: heat map data and death-related data
# Input of data
heat_map = read.csv('../data/preprocessed/countywise_Heatmap.csv')
death = read.csv('../data/preprocessed/heat_death_2011_2015.csv')
death_m=death[death$Year==2013&death$Month==7,]
death_m = death_m[,c(3,8,9,10)]
colnames(death_m)<-c("county","death","total","elderly")
joined_table=merge(heat_map,death_m, by = "county")

# The distribution of average heatmap index and variance heatmap index.
par(mfrow=c(1,2))
hist(joined_table$avg_heatmap)
hist(joined_table$var_heatmap)

# The relationship between death proportion of the elderly and the average and the variance of heatmap index.
m1=lm(death/elderly~avg_heatmap+var_heatmap,data = joined_table)
summary(m1)

# The relationship between the total population and the average and the variance of heatmap index
m2=lm(total~avg_heatmap+var_heatmap,data = joined_table)
summary(m2)

# The relationship between the elderly proportion and the average and the variance of heatmap index.
m3=lm(elderly/total~avg_heatmap+var_heatmap,data = joined_table)
summary(m3)
