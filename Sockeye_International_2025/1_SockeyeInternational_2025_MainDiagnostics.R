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



# TO DO: team-specific summaries
#largest_APE - which stock?
#smallest_APE  - which stock?
# largest error  - which stock?
#smallest error  - which stock?
#rank by prize  - which stock?





############################################################################
# 3) GENERATE SUMMARY PLOTS
############################################################################




plot_PM <- function(src.obj,pm.plot = "MAPE",system.plot = "All",
                    ylim.use = NULL,title.use=NULL,
                    ylab.use = NULL,
                    y.scalar.use = NULL # capture scalar in ylab.use axis label!!!!
                    ){

values.df <- src.obj$Results_Details %>% dplyr::filter(System == system.plot, PM == pm.plot, Version == "Values") %>%
              select(-System, -PM,-Version)

if(!is.null(y.scalar.use)){values.df <- values.df/y.scalar.use}

if(is.null(title.use)){title.use <- paste0(system.plot,": ",pm.plot)}
if(is.null(ylab.use)){ylab.use <- pm.plot}

plot(rep(1,length(values.df)),values.df, xlim=c(0.93,1.4),ylim=ylim.use,
     axes=FALSE,xlab = "",ylab = ylab.use, pch=21,col="darkblue",bg="lightgrey",cex = 1.2,
      col.main="darkblue")
axis(2, las=1)
text(rep(1.05,length(values.df)),values.df,labels = names(values.df),
     col="darkblue",adj= 0,xpd=NA)
title(main=title.use,line=-0.5,col.main="darkblue")

}




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






#pm.title <- "Mean Percent Error"
#range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
#ylim.overall <- c(3*10^6,0)

#
#pm.title <- "Mean Absolute Error"
#range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
#ylim.overall <- c(3*10^6,0)


#p
#
#range(results.obj$Results_Details %>% dplyr::filter(Version == "Values",PM==pm.do) %>% select(-System,-PM,-Version))
#ylim.overall <- c(5*10^6,0)




png(filename = paste0(folder.use,"/Diagnostics/PM_ValueComparison_",pm.do,".png"),
    width = 480*4.5, height = 480*3.5, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


#par(mfrow=c(2,2),mai=c(2.5,2.5,2,2))

par(mfrow=c(1,4),mai=c(1,2.2,1.5,1.5))



plot_PM(results.obj,pm.plot = pm.do ,system.plot = "All",
        ylim.use = ylim.overall,title.use="All",
        ylab.use = ylab.overall, y.scalar.use = y.scalar )
  abline(h=0,col="red",lwd=3)

plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Bristol Bay",
        ylim.use = ylim.overall,title.use="Bristol Bay",
ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)

plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Fraser River",
        ylim.use = ylim.overall,title.use="Fraser River",
ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)

plot_PM(results.obj,pm.plot = pm.do ,system.plot = "Columbia",
        ylim.use = ylim.overall,title.use="Columbia",
        ylab.use = "", y.scalar.use = y.scalar  )
  abline(h=0,col="red",lwd=3)


title(main=pm.title,outer=TRUE,line=-1,col.main="darkblue")


dev.off()


} # end looping through PM
