library(dplyr)
library(tidyr)
library(RMySQL)

## user-defined input
# list all the name of the station daily temperature and relative humidity files here.
# It should include "Station_name", "Year", "Month", "Date", "Air_Temperature_max", "Relative_Humidity_min" columns
input_file_names <- c("2011_0_100.csv","2011_101_200.csv","2011_201_300.csv",
                "2011_301_400.csv","2011_401_500.csv","2011_501_555.csv",
                "2012_0_185.csv","2012_185_370.csv","2012_370_555.csv",
                "2013_0_185.csv","2013_185_336.csv","2013_336_555.csv",
                "2014_0_190.csv","2014_190_380.csv","2014_380_555.csv",
                "2015_0_185.csv","2015_185_310.csv","2015_310_435.csv","2015_435_555.csv")

## user-defined output filename
output_stationwise_daily_HI_WGBT_filename <- "TEMP_HUM_HI_WBGT_2011_2015"
output_stationwise_monthly_HI_WGBT_filename <- "processed_HI_WBGT_2011_2015"
  
## construct a new data frame to record all the temperature data
df <- data.frame(matrix(ncol=8,nrow=0))
colnames(df) <- c("Station_name", "Year", "Month", "Date",
                  "Air_Temperature_max", "Relative_Humidity_min", "HI_max", "WBGT_max")

## define a function to calculate HImax and WGBTmax
HI_WBGT_cal <- function(file_name){
  data <- read.csv(paste("../data/raw/",file_name,sep=""), header=FALSE)
  colnames(data) <- c("Station_name", "Year", "Month", "Date", "Air_Temperature_max", "Relative_Humidity_min")
  
  ## remove the outliers
  data <- data[data$Air_Temperature_max>=30,]
  data <- data[(data$Relative_Humidity_min<=100 & data$Relative_Humidity_min>=0),]
  
  T_max <- as.numeric(data$Air_Temperature_max)
  RH_min <- as.numeric(data$Relative_Humidity_min)
  
  HI_max <- ((0.5*(T_max+61.0+(T_max-68.0)*1.2)+(0.094*RH_min))+T_max)/2
  WBGT_max <- -0.0034*HI_max^2 + 0.96*HI_max-34
  
  data <- data %>%
    mutate(HI_max = HI_max,
           WBGT_max = WBGT_max)
  
  df <- rbind(df, data)
  return(df)
}

# merge all the csv into one data frame
for (file_name in input_file_names) {
  df <- HI_WBGT_cal(file_name)
  }

## Write the merged data into RMDBS and store it as a csv
write.csv(df,paste(output_stationwise_daily_HI_WGBT_filename,".csv",sep=""), row.names = FALSE)
# mysqlconnection = dbConnect(RMySQL::MySQL(),
#                             dbname='506_project',
#                             host='35.2.205.222',
#                             port=3306,
#                             user='linyu',
#                             password='123456',
# )
# dbWriteTable(mysqlconnection, name=output_stationwise_daily_HI_WGBT_filename, value=df, row.names = FALSE, overwrite=TRUE)


## Feature Engineering and Aggregating into Monthly data
df <- df[!is.na(df$WBGT_max),]
data_month <- df %>% 
  group_by(Year, Month, Station_name) %>%
  #group_by(Station_name, .add=TRUE)
  summarise(
    avg_WBGT_max_monthly = mean(WBGT_max,na.rm=TRUE),
    max_WBGT_max_monthly = max(WBGT_max,na.rm=TRUE)
  )

data_month_heat_wave <- df %>% 
  group_by(Year, Month, Station_name) %>%
  filter(WBGT_max>28) %>%
  summarise(
    duration_heat_wave_monthly = ifelse(is.na(n())==TRUE,0,n()),
    avg_heat_waves_WBGT_max_monthly = mean(WBGT_max,na.rm=TRUE)
  )

data_month <- left_join(data_month, data_month_heat_wave, by=c("Year","Month","Station_name"))

## Write the processed data into RMDBS and store it as a csv
write.csv(data_month,paste(output_stationwise_monthly_HI_WGBT_filename,".csv",sep=""), row.names = FALSE)
#dbWriteTable(mysqlconnection, name="processed_HI_WBGT_2011_2015", value=data_month, row.names = FALSE, overwrite=TRUE)