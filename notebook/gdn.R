gdn <- function(dataset, year) {
  dataset[is.na(dataset)]=0
  set<-c()
  county_name<-unique(dataset$County)
  month<-unique(dataset$Month)
  d<-c()
  for (j in month) {
    for (i in county_name) {
      elderly_death<-sum(dataset$Count[dataset$County==i&dataset$Year==year&dataset$Month==j
                                       &dataset$Cause_Desc=="All causes (total)"&dataset$Strata=="Age"][9:11])
      d<-c(d,elderly_death)
    }
  }
  df=data.frame(county=rep(county_name,12),
                year=rep(year,12*length(county_name)),
                month=rep(1:12,each=length(county_name)),
                death=d)
  
  return(df)
}