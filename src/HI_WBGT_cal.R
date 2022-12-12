# Input: air_temperature_max, relative_humidity_min
# Output: HI_max, WBGT_max
# Function: Calculate the heatwave temperature index according to 
#          air temperature and relative humidity.

HI_WBGT_cal <- function(air_temperature_max,
                        relative_humidity_min) {
  if (length(air_temperature_max) != length(relative_humidity_min)) {
    stop("Temperature and humidity do not have the same length.")
  } else {
    T_max <- as.numeric(air_temperature_max)
    RH_min <- as.numeric(relative_humidity_min)
    HI_max <-
      ((0.5 * (T_max + 61.0 + (T_max - 68.0) * 1.2) + (0.094 * RH_min)) + T_max) /
      2
    WBGT_max <- -0.0034 * HI_max ^ 2 + 0.96 * HI_max - 34
    return(list(HI_max = HI_max, WBGT_max = WBGT_max))
  }
}

# test
# HI_WBGT_cal(seq(31,40,by=1),seq(0,100,by=11))
# HI_WBGT_cal(NA, NA)
