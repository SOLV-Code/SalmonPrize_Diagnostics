require(readr)
require(tidyverse)

new_data <- read_csv("/Users/haleyoleynik/Documents/UBC/Salmon Prize/R_data_long_v3.csv")
#data <- read_csv("/Users/haleyoleynik/Documents/UBC/Salmon Prize/R_data_long_v4.csv")
#props <- read_csv("/Users/haleyoleynik/Documents/UBC/Salmon Prize/R_props.csv")
#new_data <- left_join(data,props, by = c("System", "Stock","BroodYear"))

# Geometric mean predictions -----------
library(dplyr)

# Calculate geometric mean of avg_RS for each Stock
mean_RS <- new_data %>%
  group_by(Stock) %>%
  filter(BroodYear %in% c(2017, 2018, 2019)) %>%
  summarize(meanRS = exp(mean(log(avg_RS), na.rm = TRUE)))

# Calculate geometric means of prop_4, prop_5, and prop_6
mean_props <- new_data %>%
  group_by(Stock) %>%
  filter(BroodYear %in% c(2014, 2015, 2016, 2017)) %>%
  summarize(
    mean_prop4 = exp(mean(log(prop_4), na.rm = TRUE)),
    mean_prop5 = exp(mean(log(prop_5), na.rm = TRUE)),
    mean_prop6 = exp(mean(log(prop_6), na.rm = TRUE))
  )

# Join the summaries
avgs <- left_join(mean_RS, mean_props, by = "Stock")
all <- left_join(new_data, avgs, by = "Stock")

# Calculate predicted recruits
all %>%
  group_by(Stock) %>%
  summarise(
    predR = mean_prop6[1] * (meanRS[1] * Spawners[BroodYear == 2019]) +
      mean_prop5[1] * (meanRS[1] * Spawners[BroodYear == 2020]) +
      mean_prop4[1] * (meanRS[1] * Spawners[BroodYear == 2021])
  )


# Geometric mean retrospective analysis  -----------------
library(dplyr)
library(purrr)

retrospective_preds_by_stock_v2 <- new_data %>%
  group_by(Stock) %>%
  group_split() %>%
  map_dfr(function(stock_df) {
    stock_name <- unique(stock_df$Stock)
    
    # Define prediction years for this stock
    prediction_years <- stock_df %>%
      filter(!is.na(Spawners)) %>%
      pull(BroodYear) %>%
      unique() %>%
      sort()
    
    # Filter out early years that don't have required lag
    prediction_years <- prediction_years[prediction_years >= (min(stock_df$BroodYear) + 12)]
    
    map_dfr(prediction_years, function(yr) {
      # meanRS: geometric mean of avg_RS from (yr - 8):(yr - 6)
      rs_values <- stock_df %>%
        filter(BroodYear %in% (yr - 8):(yr - 6)) %>%
        pull(avg_RS) %>%
        na.omit() %>%
        .[. > 0]
      
      meanRS <- if (length(rs_values) > 0) exp(mean(log(rs_values))) else NA_real_
      
      # geometric mean of each prop from (yr - 11):(yr - 8)
      props_df <- stock_df %>%
        filter(BroodYear %in% (yr - 11):(yr - 8))
      
      geo_mean <- function(x) {
        x <- na.omit(x)
        x <- x[x > 0]
        if (length(x) > 0) exp(mean(log(x))) else NA_real_
      }
      
      mean_prop4 <- geo_mean(props_df$prop_4)
      mean_prop5 <- geo_mean(props_df$prop_5)
      mean_prop6 <- geo_mean(props_df$prop_6)
      
      # get spawners from lagged years
      S_years <- stock_df %>%
        filter(BroodYear %in% c(yr - 6, yr - 5, yr - 4)) %>%
        select(BroodYear, Spawners)
      
      S2019 <- S_years$Spawners[S_years$BroodYear == (yr - 6)]
      S2020 <- S_years$Spawners[S_years$BroodYear == (yr - 5)]
      S2021 <- S_years$Spawners[S_years$BroodYear == (yr - 4)]
      
      # compute predR
      predR <- (mean_prop6 * (meanRS * S2019)) +
        (mean_prop5 * (meanRS * S2020)) +
        (mean_prop4 * (meanRS * S2021))
      
      tibble(
        Stock = stock_name,
        prediction_year = yr,
        meanRS = meanRS,
        mean_prop4 = mean_prop4,
        mean_prop5 = mean_prop5,
        mean_prop6 = mean_prop6,
        S2019 = S2019,
        S2020 = S2020,
        S2021 = S2021,
        predR = predR
      )
    })
  })

#write_csv(retrospective_preds_by_stock_v2, "/Users/haleyoleynik/Documents/UBC/Salmon Prize/R_predictions_geom-mean.csv")









