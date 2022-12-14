# The Impact of Heat Waves and Urban Heat Island to Older Adults

## Description
This project is aiming at investigating whether urban heat island effects and heat waves are correlate to the incidence of heat-related diseases among the aged, and how they affect the life-expectancy of older adults. 

The repository contains:
- an analysis of the impact of heat waves and urban heat island to elders
- a case study which focuses on the weather conditions and heat-related diseases among the aged located in California from 2011 to 2015
- an interactive surface to calculate heat index

## Background
1. heat wave definition
   The heat waves in this project are identified for a temperature-humidity threshold: one day or longer periods where the daily maximum Wet Bulb Globe Temperature (WBGTmax) > 28 °C. This WBGTmax thresholds follow the International Standards Organization (ISO) criteria for risk of occupational heat related heat illness. 

2. Analysis Scope and Measurement
   - Heat-related death data is collected from [California State: Death Profiles by County by Month, 1970-2020](https://data.chhs.ca.gov/dataset/death-profiles-by-county). This provides monthly mortality data in California counties. Thus, our analysis is all measured county-wise and monthly from 2011 to 2015 within California. 
   - Daily Station-wise temperature and humidity information is crawled from [Western Regional Climate Center (WRCC)](https://wrcc.dri.edu/cgi-bin/wea_monsum.pl?ca). The geometry (latitide and longtitude) information is then utilized to map the station into counties, the scope of each county is retrieved from [California Open Data Portal](https://data.ca.gov/dataset/california-counties). The following feature engineering is based on this processed county-wise data. ![Meteorological Monitoring Stations in California Counties](https://gitlab.umich.edu/506-heatwave-and-old-people/heatwave-and-old-people/-/raw/main/result/map_station_county.png){:height="50%" width="50%"}

## Operating Instruction
1. All the files in the src directory is the codes that is highly generalized from codes shown in the notebook directory.
2. To run the code, just download the whole project and run /src/main.R. It would directly refer to other source code. By running main.R, you can generate a case study which focuses on the weather conditions and heat-related diseases among the aged located in California from 2011 to 2015. You can also input other files to DIY a new case study and explore further.
### description to the code in src
1. HI_WBGT_cal.R: 
   - Input: air_temperature_max, relative_humidity_min
   - Output: HI_max, WBGT_max
   - Function: Calculate the heatwave temperature index according to air temperature and relative humidity.
   - Author: Orginial Version (Yu Lin); Generalization (Yupeng Yang)
2. NASA.ipynb:
   - Function: Sample Code to download data 8-day average temperature emissivity satellite data covering California State
   from 7/20/2013 to 7/27/2013 to measure the heat island effects from NASA.
   - Author: Shukun Liu
3. crawl_all_station_address_code.ipynb / crawl_station_weather_data.py
   - Function: Sample code to crawled daily weather data of over 500 stations from all over California
   - Author: Shukun Liu
4. get_census_data.R
   - Function: get census data (disease data of elder people)
   - Author: Yizhou Zhang
5. map_to_county.R
   - Input: aoi_boundary_shp_file, variable of interest, geometry information (long,lat)
   - Output: a mapping relationship between variable of interest and county
   - Function: Map the variable of interest into a polygen boundry of county
   - Author: Orginial Version (Yu Lin); Generalization (Yu Lin)
6. month_summary.R / station_to_county.R
   - Input: the temperature index of some stations at some time.
   - Output: the data frame contains the 4 features by \textbf{month} / by \textbf{county}. Features are:
      1) Monthly average WGBT_max in each station
      2) Duration of heat wave in each station by month (WGBT_max >28)
      3) Monthly maximum WGBT_max in each station
      4) Monthly average WGBT_max in each station for heat wave (WGBT_max > 28)
   - Function: Summarize the temperature data by month / by county.
   - Author: Orginial Version (Yu Lin); Generalization (Yupeng Yang)
7. tranform_long_lat.R
   - Input: longitude and latitude information with form xx°xx'xx"
   - Output: longitude and latitude information in decimal degree
   - Function: transform the longitude and latitude form from xx°xx'xx" to decimal degree.
   - Author: Orginial Version (Yu Lin); Generalization (Yu Lin)

### description to other directory
1. notebook
   - Workflow_Code_Explanation.Rmd/pdf: the whole workflow and code explanation for our case study, including description, background, Data Exploration and Feature Engineering and Model Fitting.
   - other original version source code (before high generalization)
2. result
   - interactive application and its sample result
   - example of mapping station to county
   - model fitting result
3. data
   - raw: data we collected and crawled or downloaded from census data
   - preprocessed: the intermediate files we generated in the progress of project


## Interactive Results
To better stress and illustrate our data manipulation results, we build an interactive application so that user can see the overview of our datasets with preferred features. The sample picture are listed below.

![](https://gitlab.umich.edu/506-heatwave-and-old-people/heatwave-and-old-people/-/raw/main/result/app_sample_result_1.JPG){:height="70%" width="70%"}

![](https://gitlab.umich.edu/506-heatwave-and-old-people/heatwave-and-old-people/-/raw/main/result/app_sample_result_2.JPG)
{:height="70%" width="70%"}
To use the application, one can install shiny package and then run /result/app.R.

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
2. Data Crawling and Cleaning: Shukun Liu
3. Data Processing and Feature Engineering: Yu Lin
4. Integrate Codes and Code Explanation Writing: Yu Lin, Shukun Liu
5. RDBMS construction: Yupeng Yang, Yu Lin
6. Modeling and Data Analysis: Yu Lin, Yizhou Zhang
7. Code Generalization: Yupeng Yang
8. Interactive Application: Yupeng Yang
9. Output Report: Shukun Liu
10. readme and repository construction: Yu Lin
