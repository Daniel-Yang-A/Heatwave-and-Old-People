source("gdn.R")
data1 = read.csv("2021-05-14_deaths_final_2009-2013_occurrence_county_month_sup.csv")
data2 = read.csv("2021-11-29_deaths_final_2014-2018_occurrence_county_month_sup.csv")


county_name<-unique(data1$County)

d2011<-gdn(data1,2011)
d2012<-gdn(data1,2012)
d2013<-gdn(data1,2013)
d2014<-gdn(data2,2014)
d2015<-gdn(data2,2015)

dd<-rbind(d2011,d2012,d2013,d2014,d2015)
write.csv(dd,"death.csv",row.names = F)





library(tidycensus)

cd<-c()
ed<-c()
out=data.frame()
for (j in 2011:2015) {
  cd<-c()
  ed<-c()
for (i in unique(data1$County)) {
  f1<-get_acs(state='CA', county=i,geography = 'tract', variables = c("B01001_001"), geometry = T,year = j)
  cd<-c(cd,sum(f1$estimate))
  f2<-get_acs(state='CA', county=i,geography = 'tract', variables = 
                c("B01001_020","B01001_021","B01001_022","B01001_023","B01001_024","B01001_025","B01001_044",
                  "B01001_045","B01001_046","B01001_047","B01001_048","B01001_049"), geometry = F,year = j)
  ed<-c(ed,sum(f2$estimate))
}

ep<-ed/cd
#dr<-100*dy/ed
outn<-data.frame(
  Year=rep(j,58),County=unique(data1$County), total = cd, 
                elderly = ed, elder_proportion = ep)
out=rbind(out,outn)
}
write.csv(out,"cal_census_2011_to_2015.csv",row.names = F)
library(devtools)













