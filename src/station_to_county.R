# Input: the temperature index of some stations at some time.
# Output: the data frame contains the 4 features by county. Features are:
#        1) Monthly average WGBT_max in each station
#        2) Duration of heat wave in each station by month (WGBT_max >28)
#        3) Monthly maximum WGBT_max in each station
#        4) Monthly average WGBT_max in each station for heat wave (WGBT_max > 28)
# Function: Summarize the temperature data by county.

library(dplyr)

station_to_county <-
  function(year,
           month,
           name,
           avg_WBGT_max_monthly,
           max_WBGT_max_monthly,
           duration_heat_wave_monthly,
           avg_heat_waves_WBGT_max_monthly) {
    if (all(
      c(
        length(year),
        length(month),
        length(name),
        length(avg_WBGT_max_monthly),
        length(max_WBGT_max_monthly),
        length(duration_heat_wave_monthly),
        length(avg_heat_waves_WBGT_max_monthly)
      ) == length(year)
    )) {
      data <-
        data.frame(
          year = year,
          month = month,
          name = name,
          avg_WBGT_max_monthly = avg_WBGT_max_monthly,
          max_WBGT_max_monthly = max_WBGT_max_monthly,
          duration_heat_wave_monthly = duration_heat_wave_monthly,
          avg_heat_waves_WBGT_max_monthly = avg_heat_waves_WBGT_max_monthly
        )
      data_final <- data %>%
        group_by(year, month, name) %>%
        summarize(
          avg_WBGT_max_monthly = mean(avg_WBGT_max_monthly, na.rm = TRUE),
          max_WBGT_max_monthly = max(max_WBGT_max_monthly, na.rm =
                                       TRUE),
          duration_heat_wave_monthly = mean(duration_heat_wave_monthly, na.rm =
                                              TRUE),
          avg_heat_waves_WBGT_max_monthly = mean(avg_heat_waves_WBGT_max_monthly, na.rm =
                                                   TRUE)
        )
      return(data_final)
    } else {
      stop("Input values do not have the same length.")
    }
  }