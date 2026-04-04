# Script to compare candidate models tested by our team against observed returns
# Could a different model selection approach done better?


library(tidyverse)

yr.do <- 2025
folder.use <- paste0("Sockeye_International_",yr.do)

obs.runs <- read.csv(paste0(folder.use,"/Observed_Runs/",folder.use,"_ObservedRuns.csv"),comment = "#")
obs.runs$Stock <- gsub("All of Columbia River","Columbia",obs.runs$Stock )
obs.runs$Stock <- gsub(" River","",obs.runs$Stock )
obs.runs$System <- gsub("Columbia","Columbia River",obs.runs$System )

obs.runs

team.submission <- read.csv(paste0(folder.use,"/Team_Submissions/Salmon ForecastR/predictions.csv")) %>%
  dplyr::rename(Submitted_FC = Prediction,Stock = Run)

team.submission$Stock <- gsub("Stuart's Late Sockeye run","Late Stuart",team.submission$Stock)
team.submission$Stock <- gsub("'s Sockeye run","",team.submission$Stock)
team.submission$Stock <- gsub(" River","",team.submission$Stock)
team.submission$Stock <- gsub("All of Columbia","Columbia",team.submission$Stock)
team.submission$Stock


full.outputs <- read.csv(paste0(folder.use,"/Team_Submissions/Salmon ForecastR/additional_files/FullOutputs_ForecastsAndRanks.csv") )
full.outputs$Stock <- gsub("Bonneville Lock & Dam","Columbia",full.outputs$Stock)

fc.ranges <- full.outputs %>% dplyr::filter(FC_Year == yr.do,Age=="Total") %>%
              group_by(System,Stock) %>%
  summarize(Min_FC = min(p50),Mean_FC = mean(p50),Max_FC = max(p50))  %>%
  left_join(obs.runs %>% select(System,Stock,Run),by= c("System","Stock") ) %>%
  select(System, Stock, Run, everything()) %>%
  mutate(Min_FC_Ratio = Min_FC/Run,
         Mean_FC_Ratio = Mean_FC/Run,
         Max_FC_Ratio = Max_FC/Run) %>%
  mutate(System_Short = case_match(System,
    "Bristol Bay" ~ "BB", "Columbia River" ~ "CR", "Fraser River" ~ "FR" )) %>%
  left_join(team.submission,by="Stock") %>%
  mutate(Submitted_FC_Ratio = Submitted_FC/Run)

fc.ranges


if(!dir.exists(paste0(folder.use,"/Team_Submissions/Salmon ForecastR/CustomDiagnostics"))){
  dir.create(paste0(folder.use,"/Team_Submissions/Salmon ForecastR/CustomDiagnostics") )
}



png(filename = paste0(folder.use,"/Team_Submissions/Salmon ForecastR/CustomDiagnostics/CandidateModel_Comparison_TeamSalmonForecastR.png"),
    width = 480*4.5, height = 480*3.5, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


num.stks <- dim(fc.ranges)[1]

par(mai=c(5,5.5,4,1.5))

x.axis.vals <- c(1/10,1/4,1/2,1,2,4,10)
x.axis.labels <- c("1/10","1/4","1/2","1","2","4","10")

plot(1:5,1:5,type="n",bty="n",axes=FALSE,
     xlim = range(log(x.axis.vals,base=10)),
     ylim=c(num.stks+1.5,0.5),
     xlab= "",ylab="")
title( main = "Team Salmon ForecastR",col.main="darkblue",line=3.5)
mtext("Ratio of FC/Obs (Base 10 log-scale)",side=3,line=2)
axis(3,at=log(x.axis.vals,base =10),labels = x.axis.labels)
abline(v=log(1,base=10), col="red",lwd=4)
text(log(1,base=10),num.stks+2,"Bull's Eye!",col="red",xpd=NA)

labels.use <- paste0(fc.ranges$Stock," (",fc.ranges$System_Short,")")
labels.use
text(par("usr")[1],1:num.stks,labels.use, adj=1,xpd=NA)


segments(log(fc.ranges$Min_FC_Ratio,base=10) ,1:num.stks,
         log(fc.ranges$Max_FC_Ratio,base=10) ,1:num.stks,
         col="darkblue",lwd=3,lend=2)

points(log(fc.ranges$Mean_FC_Ratio,base=10) ,1:num.stks,
       pch=19,col="darkblue",cex=1.4)

points(log(fc.ranges$Submitted_FC_Ratio,base=10) ,1:num.stks,
       pch=4,col="red",cex=1.4,lwd=3)

legend(par("usr")[1],
       par("usr")[3]+1,
       legend = c("Range of total forecast (all ages) across candidate models",
                           "Mean of total (all ages) forecast across candidate models",
                           "Submitted forecast  (sum of age-specific selected models)"),
       pch=c(NA,19,4),lty=c(1,NA,NA),lwd=3,col = c("darkblue","darkblue","red"),
       bty="n",xpd=NA)


dev.off()









