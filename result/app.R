# If you see error about reading file, please use line 52 instead of line 53.

library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)

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

bydailybystation$Air_Temperature_max <- as.numeric(bydailybystation$Air_Temperature_max)
bydailybystation$Relative_Humidity_min <- as.numeric(bydailybystation$Relative_Humidity_min)

bydailybystation <- bydailybystation[!is.na(bydailybystation$Air_Temperature_max),]
bydailybystation <- bydailybystation[!is.na(bydailybystation$Relative_Humidity_min),]

# Drop abnormal data
bydailybystation <- bydailybystation[bydailybystation$Air_Temperature_max>=30,]
bydailybystation <- bydailybystation[(bydailybystation$Relative_Humidity_min>=0 & bydailybystation$Relative_Humidity_min<=100),]

# Calculate temperature index
temperature_index <- HI_WBGT_cal(bydailybystation$Air_Temperature_max, bydailybystation$Relative_Humidity_min)
bydailybystation$HI_max <- temperature_index[[1]]
bydailybystation$WBGT_max <- temperature_index[[2]]

# Summarize by month
bymonthbystation <- month_summary(bydailybystation$Year, bydailybystation$Month, bydailybystation$Station_name, bydailybystation$WBGT_max)


# heatwave
aoi_boundary_shp_filename <- "../data/raw/CA_Counties_TIGER2016.shp"
monitoring_station_csv_filename <- "../data/raw/CA_monitoring_station.csv"
#monitoring_station <- read.csv(monitoring_station_csv_filename)
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

station <- monitoring_station$name
lat <- str_transform(monitoring_station$Latitude)
long <-  -str_transform(monitoring_station$Longitude)

point_within_county <- map_to_county(aoi_boundary_shp_filename,
                                     station,
                                     long,
                                     lat)

bymonthbystation <- left_join(bymonthbystation, point_within_county, by=c("station"="variable"))

# Summarize by county
bymonthbycounty <- station_to_county(bymonthbystation$year, bymonthbystation$month, bymonthbystation$county, bymonthbystation$avg_WBGT_max_monthly, bymonthbystation$max_WBGT_max_monthly, bymonthbystation$duration_heat_wave_monthly, bymonthbystation$avg_heat_waves_WBGT_max_monthly)

aoi_boundary_HARV <- read_sf(aoi_boundary_shp_filename)[,c(5,18)]
bymonthbycounty <- left_join(bymonthbycounty, aoi_boundary_HARV, by=c("name"="NAME"))

# ggplot()+
#   geom_sf(data=aoi_boundary_HARV$geometry)+
#   geom_sf(data=bymonthbycounty[1:1000,]$geometry, aes(fill=bymonthbycounty[1:1000,]$avg_WBGT_max_monthly))+
#     scale_color_gradient(low = "blue", high = "red")

death <- read.csv("../data/preprocessed/death.csv")
elderly <- read.csv("../data/preprocessed/cal_census_2011_to_2015.csv")
HI_WBGT <- read.csv("../data/preprocessed/countywise_HI_WBGT_2011_2015.csv")

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

heat_death <- left_join(heat_death, aoi_boundary_HARV, by=c("NAME"="NAME"))

# Define UI
ui <- fluidPage(
  titlePanel("The impact of heatwave on older people"),
  tabsetPanel(
    tabPanel("Key Index",
      sidebarLayout(
        sidebarPanel(
          helpText(
            "Input a set of maximum temperature and relative humidity, calculate heat index and WBGT max"
          ),
          numericInput(
            inputId = "Tmax",
            label = "maximum temperature",
            value = 70,
            step = 0.1,
            min = -273,
            max = 200
          ),
          numericInput(
            inputId = "RHmin",
            label = "minimum relative humidity",
            value = 60,
            step = 1,
            min = 0,
            max = 100
          )
        ),
         
        mainPanel(
          h3("Below is the interactive result"),
          textOutput("heat_index"),
          textOutput("wbgt_max"),
          h3("Below is the data used in our analysis"),
          tableOutput("temp_index")
        )
      ), 
    # p("Input a set of maximum temperature and relative humidity"),
    # # fileInput("file", "Data", buttonLabel = "Upload..."),
    ),
    tabPanel(
      "County Plot",
      sidebarLayout(
        sidebarPanel(
          width = 4,
          selectInput(
            "county_year", 
            h4("Year Selection"), 
            choices = list("2011" = 2011, "2012" = 2012, "2013" = 2013, "2014" = 2014, "2015" = 2015), 
            selected = 2011
          ),
          sliderInput("county_month", h4("Month Selection"),
                      min = 1, max = 12, value = 1),
          selectInput(
            "county_index", 
            h4("Index1 Selection"), 
            choices = list("Average WBGT max" = 1, "Heatwave Duration" = 2), 
            selected = 1
          ),
          selectInput(
            "death_index", 
            h4("Index2 Selection"), 
            choices = list("death_rate" = 1, "elder_death_rate" = 2), 
            selected = 1
          )
        ),
        mainPanel(
          column(6, 
                 h4("Temperature Map"),
                 plotOutput("county_plot")
          ),
          column(6,
                 h4("Death Rate Map"),
                 plotOutput("death_plot")
          )
        )
      )
    )
  )
    # # Show a plot of the generated distribution
    # mainPanel(plotOutput("distPlot"))
    # )
)
  
# Define server logic required to draw a histogram
server <- function(input, output) {
  output$heat_index <- renderText({ 
    paste("The heat index is", HI_WBGT_cal(input$Tmax, input$RHmin)[[1]])
  })
  
  output$wbgt_max <- renderText({ 
    paste("The maximum wbgt is", HI_WBGT_cal(input$Tmax, input$RHmin)[[2]])
  })
  
  output$temp_index <- renderTable({
    bydailybystation[1:100,]
  })
  
  output$county_plot <- renderPlot({
    temp <- bymonthbycounty[bymonthbycounty$year == input$county_year,]
    temp <- temp[temp$month == input$county_month,]
    g1 <- ggplot()+
      geom_sf(data=aoi_boundary_HARV$geometry)
    if (input$county_index == 1) {
      g1 + geom_sf(data=temp$geometry, aes(fill=temp$avg_WBGT_max_monthly))+
        scale_fill_viridis_c(option = "D", limit=c(-3,31), name="")+
        theme(plot.margin = margin(0, 0, 0, 0, "cm"))
    } else if (input$county_index == 2) {
      g1 + geom_sf(data=temp$geometry, aes(fill=temp$duration_heat_wave_monthly))+
        scale_fill_viridis_c(option = "D", limit=c(0,31), name="")+
        theme(plot.margin = margin(0, 0, 0, 0, "cm"))
    }
  })
  
  output$death_plot <- renderPlot({
    cur <- heat_death[heat_death$Year == input$county_year,]
    cur <- cur[cur$Month == input$county_month,]
    g1 <- ggplot()+
      geom_sf(data=aoi_boundary_HARV$geometry)
    if (input$death_index == 1) {
      g1 + geom_sf(data=cur$geometry, aes(fill=cur$death_rate))+
        scale_fill_viridis_c(option = "C", limit=c(0,0.001), name="")+
        theme(plot.margin = margin(0, 0, 0, 0, "cm"))
    } else if (input$death_index == 2) {
      g1 + geom_sf(data=cur$geometry, aes(fill=cur$death_elder_rate))+
        scale_fill_viridis_c(option = "C", limit=c(0,0.01), name="")+
        theme(plot.margin = margin(0, 0, 0, 0, "cm"))
    }
  })
  
  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x    <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    
    # draw the histogram with the specified number of bins
    hist(
      x,
      breaks = bins,
      col = 'darkgray',
      border = 'white',
      xlab = 'Waiting time to next eruption (in mins)',
      main = 'Histogram of waiting times'
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
  