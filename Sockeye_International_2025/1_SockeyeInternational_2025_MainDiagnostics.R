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
# 2) CALCULATE THE PERFORMANCE MEASURES
############################################################################

calc_PMandRanks <- function(pred){
# pred is a data frame with columns System, Stock, Run (obs run size) and then
# 1 column for each team submission

team.cols <-   names(pred)[-c(1:3)]
#print(team.cols)


raw.error.src <- pred %>% select(all_of(team.cols)) - pred$Run
perc.error.src <- round(raw.error.src / pred$Run *100,2)


raw.error <- bind_cols(pred %>% select(System,Stock),
                   raw.error.src)
perc.error <- bind_cols(pred %>% select(System,Stock),
                   perc.error.src)


mape.all <- perc.error %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))

mape.bysystem <- perc.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))
#print(mape.bysystem)

#print(t(apply(mape.bysystem,1,rank, ties.method="average")))


results.details <- bind_cols(data.frame(System = "All",PM = "MAPE",Version="Values"),mape.all) %>%
                  bind_rows(
                  bind_cols(data.frame(System = "All",PM = "MAPE",Version="Rank"),as.data.frame(rank(mape.all,ties.method = "average")) %>% t() ),
                  bind_cols(mape.bysystem %>% mutate(PM = "MAPE",Version="Values") ),
                  bind_cols(System = mape.bysystem$System, PM = "MAPE",Version="Rank",
                            t(apply(mape.bysystem %>% select(-System),1,rank, ties.method="average")) )

                  ) %>%
  arrange(System,PM, Version)



out.list <- list(
  Predictions = pred,
  RawError = raw.error,
  PercError = perc.error,
  Results_Details = results.details)

return(out.list)

}



results.obj <- calc_PMandRanks(predictions.df)


names(results.obj)
results.obj$Results_Details







# for each team
#largest_APE
#smallest_APE
#rank by prize


