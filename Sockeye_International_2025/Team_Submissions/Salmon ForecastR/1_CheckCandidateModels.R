# Script to compare candidate models tested by our team against observed returns
# Could a different model selection approach done better?


library(tidyverse)

yr.do <- 2025
folder.use <- "Sockeye_International_2025"

obs.runs <- read.csv(paste0(folder.use,"/Observed_Runs/",folder.use,"_ObservedRuns.csv"),comment = "#")

full.outputs <- read.csv(paste0(folder.use,"/Team_Submissions/Salmon ForecastR/additional_files/FullOutputs_ForecastsAndRanks.csv") )


fc.ranges <- full.outputs %>% dplyr::filter(FC_Year == yr.do,Age=="Total") %>%
              group_by(Stock)

fc.ranges
