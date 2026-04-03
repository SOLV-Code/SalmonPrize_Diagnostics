# Script to consolidate and analyze the 2025 Sockeye International results
# Questions/comments? -> start a new issue at https://github.com/SOLV-Code/SalmonPrize_Diagnostics/issues

# THIS SCRIPT CALCULATES PERFORMANCE MEASURES AND RANKS
# NEXT SCRIPT DOES A BUNCH OF PLOT EXPLORATIONS


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



# create alternative version that includes agency forecasts AND competitor ensemble forecast
# using mean or median across teams


predictions.inclagencyensemble.df <- predictions.inclagency.df %>%
  rowwise() %>%
  mutate(
    Ensemble_Mean = mean(c_across(all_of(teams.labels)), na.rm = TRUE),
    Ensemble_Median = median(c_across(all_of(teams.labels)), na.rm = TRUE)) %>% ungroup
write_csv(predictions.inclagencyensemble.df,paste0(folder.use,"/Diagnostics/MAIN_PredictionsSummary_InclAgencyFCAndEnsemble.csv"))




#  mutate( = across(, ~ mean(.x) ))





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

# calculate alternative results treating agency forecast and ensemble across teams as additional competitors

results.obj.inclagencyandensemble <- calc_PMandRanks(predictions.inclagencyensemble.df)

names(results.obj.inclagencyandensemble)

results.obj.inclagencyandensemble$Results_Details
write_csv(results.obj.inclagencyandensemble$Results_Details,paste0(folder.use,"/Diagnostics/DETAILS_RanksAndValuesForAltPM_InclAgencyFCAndEnsemble.csv"))

results.obj.inclagencyandensemble$RanksByPrize
write_csv(results.obj.inclagencyandensemble$RanksByPrize,paste0(folder.use,"/Diagnostics/MAIN_RanksByPrize_InclAgencyFCAndEnsemble.csv"))




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







