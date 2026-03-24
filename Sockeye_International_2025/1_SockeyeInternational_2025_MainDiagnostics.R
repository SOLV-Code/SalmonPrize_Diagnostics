# Script to consolidate and analyze the 2025 Sockeye International results
# Questions/comments? -> start a new issue at https://github.com/SOLV-Code/SalmonPrize_Diagnostics/issues


# load packages
library(tidyverse)

# load custom functions
source("FUNCTIONS/SalmonPrize_DiagnosticFunctions.R")


############################################################################
# 1) COMPILE THE SUBMISSIONS
############################################################################


folder.use <- "Sockeye_International_2025"
submissions.path <- paste0(folder.use,"/Team_Submissions")


# get a list of teams that submitted entries
# manually shorten very long team names
# remove spaces from labels
teams.list <- unlist(list.dirs(submissions.path,full.names=FALSE,recursive=FALSE) )
teams.list

teams.labels<- gsub("- PACific Ecosystem Approach for SALmon FORECASTing","",teams.list)
teams.labels<- gsub(" ","",teams.labels)
teams.labels<- gsub("Team","",teams.labels)
teams.labels

# get observed runs
predictions.df <- read.csv(paste0(folder.use,"/Observed_Runs/",folder.use,"_ObservedRuns.csv"),comment = "#")


# add team predictions
for(i in 1:length(teams.list)){

team.do <-  teams.list[i]
team.label.use <- teams.labels[i]
print(team.label.use)

paste0(submissions.path,"/",team.do,"/predictions.csv")

team.pred <- read.csv(paste0(submissions.path,"/",team.do,"/predictions.csv"),comment = "#")
names(team.pred) <- c("SubmissionLabel",team.label.use)

predictions.df <- predictions.df %>% left_join(team.pred, by="SubmissionLabel")



}

# don't need this alternative identifier for subsequent steps
predictions.df <- predictions.df %>% select(-SubmissionLabel)

predictions.df

write_csv(predictions.df,paste0(folder.use,"/Diagnostics/MAIN_PredictionsSummary.csv"))


# create alternative version that includes agency forecasts

agency.fc <- read.csv(paste0(folder.use,"/AgencyFC/",folder.use,"_AgencyForecasts.csv"),
                      comment="#")

predictions.inclagency.df <- predictions.df %>%
  left_join(agency.fc %>% select(Stock, Forecast) %>% dplyr::rename(AgencyFC = Forecast),
            by="Stock") %>% select(System,Stock,Run,AgencyFC,everything())

write_csv(predictions.inclagency.df,paste0(folder.use,"/Diagnostics/MAIN_PredictionsSummary_InclAgencyFC.csv"))



############################################################################
# 2) CALCULATE THE PERFORMANCE MEASURES AND RANKS
############################################################################

source("FUNCTIONS/SalmonPrize_DiagnosticFunctions.R")

results.obj <- calc_PMandRanks(predictions.df)

names(results.obj)

results.obj$Results_Details
write_csv(results.obj$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM.csv"))

results.obj$RanksByPrize
write_csv(results.obj$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize.csv"))


results.obj.inclagency <- calc_PMandRanks(predictions.inclagency.df)

names(results.obj.inclagency)

results.obj.inclagency$Results_Details
write_csv(results.obj.inclagency$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM_InclAgencyFC.csv"))

results.obj.inclagency$RanksByPrize
write_csv(results.obj.inclagency$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize_InclAgencyFC.csv"))


# TO DO: team-specific summaries
#largest_APE - which stock?
#smallest_APE  - which stock?
# largest error  - which stock?
#smallest error  - which stock?
#rank by prize  - which stock?





############################################################################
# 3) GENERATE SUMMARY PLOTS
############################################################################

source("FUNCTIONS/SalmonPrize_DiagnosticFunctions.R")


# PLOT TYPE: 1 PLOT FOR EACH PM, 4 PANELS (All, BB, FR, CR)


for(pm.do in c("MAPE", "MPE", "RMSE")){

if(pm.do == "MAPE"){
pm.title <- "Mean Absolute Percent Error (MAPE)"
range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
ylim.overall <- c(200,0)
ylab.overall <- "MAPE"
y.scalar <- 1
}


if(pm.do == "MPE"){
  pm.title <- "Mean Percent Error (MPE)"
  range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
  ylim.overall <- c(-100,200)
  ylab.overall <- "MPE"
  y.scalar <- 1
}

if(pm.do == "RMSE"){
    pm.title <- "Root Mean Square Error"
    range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
    ylim.overall <- c(5,0)
    ylab.overall <- "RMSE (Mill)"
    y.scalar <- 10^6
  }


png(filename = paste0(folder.use,"/Diagnostics/PM_ValueComparison_ByPM_",pm.do,".png"),
    width = 480*5.5, height = 480*3.9, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


#par(mfrow=c(2,2),mai=c(2.5,2.5,2,2))

par(mfrow=c(1,4),mai=c(1,2.2,1.5,1.5))


plot_PM(results.obj,pm.plot = pm.do ,system.plot = "All",
        ylim.use = ylim.overall,title.use="All",
        ylab.use = ylab.overall, y.scalar.use = y.scalar )
  abline(h=0,col="red",lwd=3)


agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == "All",PM == pm.do, Version == "Values") %>%
    select(AgencyFC)/y.scalar
points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)


plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Bristol Bay",
        ylim.use = ylim.overall,title.use="Bristol Bay",
ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)

  agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == "Bristol Bay",PM == pm.do, Version == "Values") %>%
    select(AgencyFC)/y.scalar
  points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
  text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)



plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Fraser River",
        ylim.use = ylim.overall,title.use="Fraser River",
ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)

  agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == "Fraser River",PM == pm.do, Version == "Values") %>%
    select(AgencyFC)/y.scalar
  points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
  text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)

plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Columbia",
        ylim.use = ylim.overall,title.use="Columbia",
        ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)

  agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == "Columbia",PM == pm.do, Version == "Values") %>%
    select(AgencyFC)/y.scalar
  points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
  text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)

title(main=pm.title,outer=TRUE,line=-1,col.main="darkblue")


dev.off()


} # end looping through PM




# PLOT TYPE: 1 PLOT FOR SYSTEM, 2 PANELS (MAPE, MAE)


for(system.do in c("All", "Bristol Bay", "Fraser River","Columbia")){

  png(filename = paste0(folder.use,"/Diagnostics/PM_ValueComparison_BySystem_",system.do,"_Zoomed.png"),
      width = 480*4.5, height = 480*3.5, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


  #par(mfrow=c(2,2),mai=c(2.5,2.5,2,2))

  par(mfrow=c(1,2),mai=c(1,2.2,2,1.5))


  plot_PM(results.obj,pm.plot = "MAPE" ,system.plot = system.do,
          ylim.use = c(100,0),title.use="MAPE",
          ylab.use = NULL, y.scalar.use = NULL )
  abline(h=0,col="red",lwd=3)


  agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == system.do, PM == "MAPE", Version == "Values") %>%
    select(AgencyFC)
  points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
  text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)



  plot_PM(results.obj,pm.plot = "MPE" ,system.plot = system.do,
          ylim.use = c(-100,100),title.use="MPE",
          ylab.use = "", y.scalar.use = NULL  )
  abline(h=0,col="red",lwd=3)


  agencypm.tmp <- results.obj.inclagency$Results_Details  %>%
    dplyr::filter(System == system.do, PM == "MPE", Version == "Values") %>%
    select(AgencyFC)
  points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
  text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)

  title(main=system.do,outer=TRUE,line=-1,col.main="darkblue")


  dev.off()


} # end looping through systems



#############################
# DETAILS BY STOCK
# not a function yet!


for(stk.plot in predictions.df$Stock){

system.label <- results.obj$PercError %>% dplyr::filter(Stock==stk.plot) %>% select(System)

png(filename = paste0(folder.use,"/Diagnostics/Results_ByStock_",system.label,"_",stk.plot,".png"),
    width = 480*4.5, height = 480*3.5, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)

par(mfrow=c(1,2),mai=c(2,3,4,4))

src.obj <- results.obj




perc.df <- src.obj$PercError %>% dplyr::filter(Stock == stk.plot)
perc.df

system.label <- perc.df$System

perc.df <- perc.df %>% select(-System,-Stock)


agencypm.tmp <- results.obj.inclagency$PercError  %>%
  dplyr::filter(Stock == stk.plot) %>%
  select(AgencyFC)









obs.run <- src.obj$Predictions %>% dplyr::filter(Stock == stk.plot) %>% select(Run)
obs.run

if(obs.run >10^6){ scalar.use <- 10^6; scalar.label = "M"; round.use <- 2}
if(obs.run > 10^4 & obs.run < 10^6){ scalar.use <- 10^3; scalar.label = "k"; round.use <- 0}
if(obs.run <= 10^4 ){ scalar.use <- 1; scalar.label = ""; round.use <- 0}

vals.50p <- prettyNum(round(obs.run*0.5/scalar.use,round.use),big.mark=",")
labels.50p <- c(paste0("-",vals.50p,scalar.label), paste0(vals.50p,scalar.label))
labels.50p

vals.25p <- prettyNum(round(obs.run*0.25/scalar.use,round.use),big.mark=",")
labels.25p <- c(paste0("-",vals.25p,scalar.label), paste0(vals.25p,scalar.label))
labels.25p



plot(rep(1,length(perc.df)),perc.df, xlim=c(0.93,1.4),ylim=range(perc.df,0),
     axes=FALSE,xlab = "",ylab = "", pch=21,col="darkblue",bg="lightgrey",cex = 1.2,
     main = "Full Range", col.main="darkblue")
axis(2, las=1)
abline(h = 0 , col="red",lwd=6)

abline(h = 100* c(-0.5,-0.25,0.25,0.5),col="darkgrey",lty=2,lwd=3)
axis(4,at = 100* c(-0.5,0.5),labels =labels.50p, las=1,tick=FALSE)
axis(4,at = 100* c(-0.25,0.25),labels =labels.25p, las=1,tick=FALSE)

text(rep(1.05,length(perc.df)),perc.df,labels = names(perc.df),
     col="darkblue",adj= 0)

points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)


text(par("usr")[1], par("usr")[4], labels = "% Error", xpd=NA ,adj=c(1,0))
#text(par("usr")[2], par("usr")[4], labels = "Error", xpd=NA) #,adj=0.1)


plot(rep(1,length(perc.df)),perc.df, xlim=c(0.93,1.4),ylim=c(-60,60),
     axes=FALSE,xlab = "",ylab = "", pch=21,col="darkblue",bg="lightgrey",cex = 1.2,
     main = "Zoomed In", col.main="darkblue")
axis(2, at= c(seq(-50,50,by=25)),las=1)
abline(h = 0 , col="red",lwd=6)
abline(h = 100* c(-0.5,-0.25,0.25,0.5),col="darkgrey",lty=2,lwd=3)
axis(4,at = 100* c(-0.5,0.5),labels =labels.50p, las=1,tick=FALSE)
axis(4,at = 100* c(-0.25,0.25),labels =labels.25p, las=1,tick=FALSE)

text(rep(1.05,length(perc.df)),perc.df,labels = names(perc.df),
     col="darkblue",adj= 0)

points(1,agencypm.tmp,col="red",pch=8,cex=1.2)
text(1.05,agencypm.tmp,"Agency FC",col="red",adj=0)

text(par("usr")[1], par("usr")[4], labels = "% Error", xpd=NA ,adj=c(1,0))


title(main=paste0(system.label,": ",stk.plot),outer=TRUE,line=-1,col.main="darkblue")
title(main=paste0("Obs Run = ",prettyNum(obs.run,big.mark=",")),outer=TRUE,line=-2,col.main="darkblue",cex.main=0.95)




dev.off()


}




