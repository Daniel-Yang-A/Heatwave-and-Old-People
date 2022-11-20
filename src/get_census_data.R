library(tidycensus)

old <-
  get_acs(
    geography = "county",
    variables = c(
      "B01001_020",
      "B01001_021",
      "B01001_022",
      "B01001_023",
      "B01001_024",
      "B01001_025",
      "B01001_044",
      "B01001_045",
      "B01001_046",
      "B01001_047",
      "B01001_048",
      "B01001_049"
    ),
    year = 2013,
    state = "CA",
    survey = "acs1"
  )

data <-
  get_acs(
    geography = "county",
    variables = c("B01001_001"),
    year = 2013,
    state = "CA",
    survey = "acs1"
  )

old <- aggregate(estimate ~ GEOID, old, sum)

data <- merge(data, old, by="GEOID")

data <- data.frame(data$GEOID, data$NAME, data$estimate.x, data$estimate.y)

write.table(
  data,
  "ca_population.csv",
  row.names = FALSE,
  col.names = TRUE,
  sep = ","
)
