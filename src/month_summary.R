# Input: the temperature index of some stations at some time.
# Output: the data frame contains the 4 features by month. Features are:
#        1) Monthly average WGBT_max in each station
#        2) Duration of heat wave in each station by month (WGBT_max >28)
#        3) Monthly maximum WGBT_max in each station
#        4) Monthly average WGBT_max in each station for heat wave (WGBT_max > 28)
# Function: Summarize the temperature data by month.

library(dplyr)

month_summary <- function(year, month, station, WBGT_max) {
  if (all(c(
    length(year),
    length(month),
    length(station),
    length(WBGT_max)
  ) == length(year))) {
    data <-
      data.frame(
        year = year,
        month = month,
        station = station,
        WBGT_max = WBGT_max
      )
    data <- data[!is.na(data$WBGT_max),]
    data_month <- data %>%
      group_by(year, month, station) %>%
      summarise(
        avg_WBGT_max_monthly = mean(WBGT_max, na.rm = TRUE),
        max_WBGT_max_monthly = max(WBGT_max, na.rm = TRUE)
      )
    
    data_month_heat_wave <- data %>%
      group_by(year, month, station) %>%
      filter(WBGT_max > 28) %>%
      summarise(
        duration_heat_wave_monthly = ifelse(is.na(n()) == TRUE, 0, n()),
        avg_heat_waves_WBGT_max_monthly = mean(WBGT_max, na.rm = TRUE)
      )
    
    data_month <- left_join(data_month,
                            data_month_heat_wave,
                            by = c("year", "month", "station"))
    return(data_month)
  } else {
    stop("Input values do not have the same length.")
  }
}

# test
# year <- c(2011, 2011, 2011, 2011, 2012, 2012, 2012, 2012)
# month <- c(4, 4, 5, 5, 6, 6, 7, 7)
# station <- c("a", "a", "a", "b", "b", "b", "b", "a")
# temperature <- c(29,30,31,32,34,12,34,24)
# month_summary(year, month, station, temperature)







