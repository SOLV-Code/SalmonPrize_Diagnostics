# Script to consolidate and analyze the 2025 Sockeye International results
# Questions/comments? -> start a new issue at https://github.com/SOLV-Code/SalmonPrize_Diagnostics/issues


# load packages
library(tidyverse)

# load custom functions
source("FUNCTIONS/SalmonPrize_DiagnosticFunctions.R")


############################################################################
# 1) COMPILE THE SUBMISSIONS
############################################################################

competition.year <- 2025
retro.yrs <- 2020:2024
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

models.metadata <- read.csv(paste0(submissions.path,"/Sockeye_International_2025_ModelMetadata.csv"),
                                   comment="#")
team.info <- read.csv(paste0(submissions.path,"/Team_Info.csv"),
                      comment="#")

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


# repeat for retrospective
# (same structure, just has a year column as well, and getting the run numbers from the data pack)


retro.df<- read.csv(paste0(folder.use,"/CompetitionDataSet/Original_Data_Pack/Combined_Return_Bristol_Columbia_Fraser.csv"),
                             comment="#") %>% select(System, River, ReturnYear,Total_Returns) %>%
  mutate(System = gsub("Columbia River","Columbia",System)) %>%
  dplyr::rename(Stock = River,Run = Total_Returns) %>%
  mutate(Stock = paste(Stock,"River")) %>%
  mutate(Stock= gsub("Bonneville Lock & Dam River", "All of Columbia River",Stock)) %>%
  mutate(Stock= gsub("Stellako River", "Stellako",Stock)) %>%
  dplyr::filter(ReturnYear %in% retro.yrs)


# extract team retrospectives
for(i in 1:length(teams.list)){

  team.do <-  teams.list[i]
  team.label.use <- teams.labels[i]
  print(team.label.use)

  retro.path <- paste0(submissions.path,"/",team.do,"/retrospective.csv")

  if(file.exists(retro.path)){

      team.retro <- read.csv(retro.path,comment = "#")  %>%
                      pivot_longer(all_of(paste0("X",retro.yrs)),names_to = "ReturnYear") %>%
                    mutate(ReturnYear = as.numeric(gsub("X","",ReturnYear)))
         names(team.retro)[4] <- team.label.use

       retro.df <- retro.df %>% left_join(team.retro, by =c("System","Stock","ReturnYear"))
  }

}




retro.df




############################################################################
# 2) CALCULATE THE PERFORMANCE MEASURES AND RANKS
############################################################################

source("FUNCTIONS/SalmonPrize_DiagnosticFunctions.R")


# calculate main competition results

results.obj <- calc_PMandRanks(predictions.df)

names(results.obj)

results.obj$Results_Details
write_csv(results.obj$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM.csv"))

results.obj$RanksByPrize
write_csv(results.obj$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize.csv"))

# calculate alternative results treating agency forecast as another competitor

results.obj.inclagency <- calc_PMandRanks(predictions.inclagency.df)

names(results.obj.inclagency)

results.obj.inclagency$Results_Details
write_csv(results.obj.inclagency$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM_InclAgencyFC.csv"))

results.obj.inclagency$RanksByPrize
write_csv(results.obj.inclagency$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize_InclAgencyFC.csv"))


# calculate retrospective results


results.obj.retro <- calc_PMandRanks(retro.df)

names(results.obj.retro)

results.obj.retro$Results_Details
write_csv(results.obj.retro$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM_RETRO.csv"))

results.obj.retro$RanksByPrize
write_csv(results.obj.retro$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize_RETRO.csv"))




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

perc.df <- perc.df %>% select(-System,-Stock,-Run)


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


##########################################################################
# DETAILED DIAGNOSTIC BY STOCK FOR EACH TEAM, INCLUDING RETROSPECTIVE
# not a function yet!


teams.list
team.do <- "SalmonForecastR"

for(stk.do in predictions.df$Stock){


agency.fc.sub <- agency.fc %>% dplyr::filter(Stock == stk.do)
predictions.df.sub <- predictions.df %>% dplyr::filter(Stock == stk.do)

models.metadata.sub <- models.metadata %>% dplyr::filter(Stock == stk.do,Team == team.do)
team.info.sub <- team.info  %>% dplyr::filter(Team == team.do)



team.folder <- paste0(submissions.path,"/",team.info.sub$Team_FullName,"/DiagnosticPlots")
if(!dir.exists(team.folder)){dir.create(team.folder)}



team.df <- retro.df %>% dplyr::filter(Stock == stk.do) %>%
  select(all_of(c("System","Stock","ReturnYear","Run",team.do))) %>%
  mutate(Type="Retrospective") %>% bind_rows(
    predictions.df %>% dplyr::filter(Stock == stk.do) %>%
      select(all_of(c("System","Stock","Run",team.do))) %>%
      mutate(ReturnYear = competition.year,Type="Prediction")
    )

names(team.df)[5] <- "TeamEntry"

team.df


title.use <- paste0(team.do,": ", stk.do," (",predictions.df.sub$System,")")


ylim.use <- range(
          0,
          team.df$Run,
          team.df$TeamEntry,
          agency.fc %>% dplyr::filter(Stock == stk.do) %>% select(Forecast),
          predictions.df %>% dplyr::filter(Stock == stk.do) %>% select(-System, -Stock,-Run)


)

ylim.use[2] <- ylim.use[2]*1.15

ylim.use

yr.range <- range(retro.yrs,competition.year)
xlim.use <- yr.range +c(0,1.5)
xlim.use



png(filename = paste0(team.folder,"/",team.do,"_",stk.do,".png"),
    width = 480*4.5, height = 480*3.5, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


layout(matrix(c(1,1,2,3),ncol=2,byrow=TRUE),height=c(3,1))






plot(1:5,1:5,xlim = xlim.use,ylim=ylim.use,
     axes=FALSE, xlab="Return Year",ylab="Run Size",
    type="n")

title(main=title.use,col.main="darkblue")

rect(competition.year-0.25,ylim.use[1],
     competition.year+0.25,ylim.use[2],
     col="lightgrey",border="lightgrey")

rect(competition.year+1-0.25,ylim.use[1],
     competition.year+1+0.25,ylim.use[2],
     col="white",border="lightgrey",lty=2)



axis(2,las=1)
axis(1, at=retro.yrs)
axis(1, at = competition.year,label = paste0(competition.year,"\nFC Yr"),padj=0.3)

obs.val <- unlist(predictions.df.sub$Run)

team.fc.val <- unlist(predictions.df.sub %>% select(all_of(team.do)))

segments(competition.year,team.fc.val,
         xlim.use[2],team.fc.val,col="red",lty=2 )
segments(competition.year,obs.val,
         xlim.use[2],obs.val,col="darkblue",lty=2 )


lines(team.df$ReturnYear,team.df$Run,
  pch=19,col="darkblue",cex=1.2,type="o")

points(competition.year,
       obs.val,
       pch=19,col="darkblue",cex=2)

lines(team.df$ReturnYear,team.df$TeamEntry,
      pch=21,col="red",bg="white",cex=1.2,type="o")

points(competition.year,
       team.fc.val,
       pch=21,col="red",bg="white",cex=2,type="o")





preds.vec <- predictions.df.sub %>% select(-System,-Stock,-Run)

points(rep(competition.year+1,length(preds.vec)),
       preds.vec,pch=19,col="darkgrey",cex=1.2)
text(rep(competition.year+1.05,length(preds.vec)),
     preds.vec,names(preds.vec),adj=0,xpd=NA,col="lightgrey")


points(competition.year+1,
       agency.fc.sub$Forecast,
       pch=8,col="darkorange",bg="white",cex=1.2,type="o",lwd=3)
text(competition.year+1.1,
       agency.fc.sub$Forecast,
     "Agency FC",col="darkorange",adj=0,xpd=NA,font=2)



legend("topleft",#xlim.use[1],ylim.use[2],
       legend = c("Obs","Team Entry"),
       pch=c(19,21),col = c("darkblue","red"),pt.bg = "white",pt.cex=2,
       bty="n",ncol=2)


par(mai = c(0,0,0,0))

plot(1:5,1:5,axes=FALSE,xlab="",ylab="",type="n")
text(1,5,"Team Model:",font =2,xpd=NA,adj=0 )
text(1,4.5,paste(strwrap(models.metadata.sub$ModelNotes,width=60), collapse='\n'),
     adj=c(0,1),xpd=NA,cex=0.8)




plot(1:5,1:5,axes=FALSE,xlab="",ylab="",type="n")
text(1,5,"Agency Model:",font =2,xpd=NA,adj=0 )
text(1,4.5,paste(strwrap(agency.fc.sub$ForecastModel,width=60), collapse='\n'),
               adj=c(0,1),xpd=NA,cex=0.8)

dev.off()


} # end looping through stocks



