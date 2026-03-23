#===============================================================================
#Project Name: Salmon Prize 2025 - Within System BRT
#Creator: Curry James Cunningham, College of Fisheries and Ocean Sciences, UAF
#Date: 6.28.25
#
#Purpose: Forecast Salmon Abundance
#
# 1) 
#
#===============================================================================
#NOTES:
# Parameters are estimated by identifying the value of fixed effects that maximizes the marginal likelihood when integrated across random effects.  We approximate this multidimensional integral using the Laplace approximation, as implemented using Template Model Builder (Kristensen et al., 2016).


# Compile Fitting Data ===================

require(tidyverse)
require(dplyr)
require(tidymodels)
require(ggthemes)
require(here)
require(rsoi)
require(vip)

tidymodels_prefer()

# Workflow =============================
dir.output <- here("output")
dir.figs <- here("figs")
dir.data <- here("data")
dir.R <- here("R")

# Source R scripts ===============
source(file.path(dir.R, "compile-brt-within.R"))
source(file.path(dir.R, "fit-brt-within.R"))

# Read Data =====================================
dat <- read.csv(file.path(dir.data, "Additional_Data_Spawners", "GENERATED_FullDataSet_LongForm.csv"), skip=3)
names(dat)


rivers <- unique(dat$River)
n.rivers <- length(rivers)

rivers
n.rivers

sr.dat <- read.csv(file.path(dir.data, "Additional_Data_Spawners", "GENERATED_SRDataSet_LongForm.csv"), skip=3)

# Test Run Data =====================================

## Compile Data ======================
input.data <- compile_brt_within(river="Wood", pred.year=2025, dat=dat, sr.dat=sr.dat)


## Fit Model =================
fit_brt_within(input.data=input.data)

# Generate current year forecasts ==============================================
list.rmse <- vector(length=n.rivers)
list.rsq <- vector(length=n.rivers)
list.fcst <- vector(length=n.rivers)

r <- 1
for(r in 1:n.rivers) {
  print(rivers[r])
  input.data <- compile_brt_within(river=rivers[r], pred.year=2025, dat=dat, sr.dat=sr.dat)
  fit.output <- fit_brt_within(input.data=input.data)
  # Extract components
  list.rmse[r] <- fit.output$metric.pred$.estimate[which(fit.output$metric.pred$.metric=="rmse")]
  list.rsq[r] <- fit.output$metric.pred$.estimate[which(fit.output$metric.pred$.metric=="rsq")]
  list.fcst[r] <- fit.output$curr.pred$.pred
}


# Compile output
brt.within.fcst <- data.frame(rivers, list.rmse, list.rsq, list.fcst)
write.csv(brt.within.fcst, file.path(dir.output, "BRT Forecasts Within.csv"))
