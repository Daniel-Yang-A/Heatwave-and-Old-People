# The Impact of Heat Waves to Older Adults

## Description
This project is aiming at investigating whether urban *heat island effects* and heat waves are correlate to the incidence of heat-related diseases among the aged, and how they affect the life-expectancy of older adults. 

The repository contains:
- an analysis of the impact of heat waves to elders
- a case study which focuses on the weather conditions and heat-related diseases among the aged located in California from 2011 to 2015
- an interactive surface to calculate heat index

## Background
1. heat wave definition
   The heat waves in this project are identified for a temperature-humidity threshold: one day or longer periods where the daily maximum Wet Bulb Globe Temperature (WBGTmax) > 28 °C. This WBGTmax thresholds follow the International Standards Organization (ISO) criteria for risk of occupational heat related heat illness. 

2. Analysis Scope and Measurement
   - Heat-related death data is collected from [California State: Death Profiles by County by Month, 1970-2020](https://data.chhs.ca.gov/dataset/death-profiles-by-county). This provides monthly mortality data in California counties. Thus, our analysis is all measured county-wise and monthly from 2011 to 2015 within California. 
   - Daily Station-wise temperature and humidity information is crawled from [Western Regional Climate Center (WRCC)](https://wrcc.dri.edu/cgi-bin/wea_monsum.pl?ca). The geometry (latitide and longtitude) information is then utilized to map the station into counties, the scope of each county is retrieved from [California Open Data Portal](https://data.ca.gov/dataset/california-counties). The following feature engineering is based on this processed county-wise data. ![Meteorological Monitoring Stations in California Counties](map_station_county.png)

## Interactive Results

To better stress and illustrate our data manipulation results, we build an interactive application so that user can see the overview of our datasets with preferred features. The sample picture are listed below.

![](https://gitlab.umich.edu/506-heatwave-and-old-people/heatwave-and-old-people/-/raw/main/sample_result/app1.JPG)

![](https://gitlab.umich.edu/506-heatwave-and-old-people/heatwave-and-old-people/-/raw/main/sample_result/app2.JPG)

To use the application, one can install shiny package and then run /sample_result/app.R.

## Installation
The following packages are required to run the case study notebook.

General: 
- R >= 4.0
- Python >= 3.5
- colab

Python:
- pandas
- numpy
- chromium-chromedriver 
- selenium
- multiprocessing
- time

R:
- measurement
- stringr
- df
- ggplot2
- tidyverse
- RMySQL
- dplyr
- shiny

## Usage
1. An general idea of how heat wave would impact elder generation
2. An highly interactive application is designed to generalize our case study to worldwide for every possible period.


## Contributing
1. Data Collection: all the team members
2. Data Crawling and Cleaning: Yu LinShukun Liu
3. Data Processing and Feature Engineering: Yu Lin
4. RDBMS construction: Yizhou Zhang
5. Modeling and Data Analysis: all the team members
6. Project and Gitlab Management: Yupeng Yang
7. Interactive Application: Yupeng Yang
8. Output Report: all the team members
