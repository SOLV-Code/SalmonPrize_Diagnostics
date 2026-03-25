calc_PMandRanks <- function(pred){
  # pred is a data frame with columns System, Stock, Run (obs run size) and then
  # 1 column for each team submission
  # if input is retrospective results, then it also has a "ReturnYear" column


id.cols <- names(pred %>% select(any_of(c("System","Stock","ReturnYear","Run"))))
team.cols <- names(pred %>% select(-any_of(c("System","Stock","ReturnYear","Run"))))

print(id.cols)
print(team.cols)

# CALCULATE ERRORS

  raw.error.src <- pred %>% select(all_of(team.cols)) - pred$Run
  perc.error.src <- round(raw.error.src / pred$Run *100,2)


  raw.error <- bind_cols(pred %>% select(any_of(id.cols)),
                         raw.error.src)
  perc.error <- bind_cols(pred %>% select(any_of(id.cols)),
                          perc.error.src)


# CALCULATE PERFORMANCE MEASURES (Overall vs. by system)

  mape.all <- perc.error %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))
  mape.bysystem <- perc.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))
  mae.all <- raw.error %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))
  mae.bysystem <- raw.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ round(mean(abs(.x)),2) ))

  mpe.all <- perc.error %>% summarize(across(all_of(team.cols), ~ round(mean(.x),2) ))
  mpe.bysystem <- perc.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ round(mean(.x),2) ))
  mre.all <- raw.error %>% summarize(across(all_of(team.cols), ~ round(mean(.x),2) ))
  mre.bysystem <- raw.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ round(mean(.x),2) ))

  rmse.all <- raw.error %>% summarize(across(all_of(team.cols), ~ sqrt(mean(.x^2)) ))
  rmse.bysystem <- raw.error %>% group_by(System) %>% summarize(across(all_of(team.cols), ~ sqrt(mean(.x^2)) ))


# COMPILE PM IN SINGLE DATA FRAME AND CALCULATE RANKS

results.details <- bind_cols(data.frame(System = "All",PM = "MAPE",Version="Values"),mape.all) %>%
    # MAPE Mean Absolute Percent Error
    bind_rows(
      bind_cols(data.frame(System = "All",PM = "MAPE",Version="Rank"),as.data.frame(rank(mape.all,ties.method = "average")) %>% t() ),
      bind_cols(mape.bysystem %>% mutate(PM = "MAPE",Version="Values") ),
      bind_cols(System = mape.bysystem$System, PM = "MAPE",Version="Rank",
                t(apply(mape.bysystem %>% select(-System),1,rank, ties.method="average")) ),

      # MAE Mean Absolute Error
      bind_cols(data.frame(System = "All",PM = "MAE",Version="Values"),mae.all),
      bind_cols(data.frame(System = "All",PM = "MAE",Version="Rank"),as.data.frame(rank(mae.all,ties.method = "average")) %>% t() ),
      bind_cols(mae.bysystem %>% mutate(PM = "MAE",Version="Values") ),
      bind_cols(System = mae.bysystem$System, PM = "MAE",Version="Rank",
                t(apply(mae.bysystem %>% select(-System),1,rank, ties.method="average")) ),

      # MPE Mean Percent Error
      bind_cols(data.frame(System = "All",PM = "MPE",Version="Values"),mpe.all),
      bind_cols(data.frame(System = "All",PM = "MPE",Version="Rank"),as.data.frame(rank(abs(mpe.all),ties.method = "average")) %>% t() ),
      bind_cols(mpe.bysystem %>% mutate(PM = "MPE",Version="Values") ),
      bind_cols(System = mpe.bysystem$System, PM = "MPE",Version="Rank",
                t(apply(abs(mpe.bysystem %>% select(-System)),1,rank, ties.method="average")) ),

      # MRE Mean Raw Error
      bind_cols(data.frame(System = "All",PM = "MRE",Version="Values"),mre.all),
      bind_cols(data.frame(System = "All",PM = "MRE",Version="Rank"),as.data.frame(rank(abs(mre.all),ties.method = "average")) %>% t() ),
      bind_cols(mre.bysystem %>% mutate(PM = "MRE",Version="Values") ),
      bind_cols(System = mre.bysystem$System, PM = "MRE",Version="Rank",
                t(apply(abs(mre.bysystem %>% select(-System)),1,rank, ties.method="average")) ),

      # RMSE Root Mean Square Error
      bind_cols(data.frame(System = "All",PM = "RMSE",Version="Values"),rmse.all),
      bind_cols(data.frame(System = "All",PM = "RMSE",Version="Rank"),as.data.frame(rank(rmse.all,ties.method = "average")) %>% t() ),
      bind_cols(rmse.bysystem %>% mutate(PM = "RMSE",Version="Values") ),
      bind_cols(System = rmse.bysystem$System, PM = "RMSE",Version="Rank",
                t(apply(rmse.bysystem %>% select(-System),1,rank, ties.method="average")) ),




    ) %>%
    arrange(System,PM, Version)




# GENERATE SUMMARY OF RANKS BY PRIZE


  results.summaryofranks <-  results.details   %>% dplyr::filter(Version == "Rank", System =="All") %>% select(-System,-Version) %>%
    column_to_rownames("PM")%>% t() %>% as.data.frame() %>% rownames_to_column("Team") %>%
    mutate(Prize = "1 Best Overall Prediction") %>%
    bind_rows(

      results.details  %>% dplyr::filter(Version == "Rank", System =="Bristol Bay") %>% select(-System,-Version) %>%
        column_to_rownames("PM")%>% t() %>% as.data.frame() %>% rownames_to_column("Team") %>%
        mutate(Prize = "2 Best Bristol Bay Prediction"),

      results.details   %>% dplyr::filter(Version == "Rank", System =="Fraser River") %>% select(-System,-Version) %>%
        column_to_rownames("PM")%>% t() %>% as.data.frame() %>% rownames_to_column("Team") %>%
        mutate(Prize = "3 Best Fraser Prediction"),

      results.details   %>% dplyr::filter(Version == "Rank", System =="Columbia") %>% select(-System,-Version) %>%
        column_to_rownames("PM")%>% t() %>% as.data.frame() %>% rownames_to_column("Team") %>%
        mutate(Prize = "4 Best Columbia Prediction"),



    ) %>%
    select(Prize,Team,MAPE,everything()) %>% arrange(Prize,MAPE)




# OUTPUT OBJECT


  out.list <- list(
    Predictions = pred,
    RawError = raw.error,
    PercError = perc.error,
    Results_Details = results.details,
    RanksByPrize = results.summaryofranks)

  return(out.list)

}



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

if(is.null(ylim.use)){ ylim.use <- rev(range(values.df,0 )) }


plot(rep(1,length(values.df)),values.df, xlim=c(0.93,1.4),ylim=ylim.use,
     axes=FALSE,xlab = "",ylab = ylab.use, pch=21,col="darkblue",bg="lightgrey",cex = 1.2)
axis(2, las=1)
text(rep(1.05,length(values.df)),values.df,labels = names(values.df),
     col="darkblue",adj= 0) #,xpd=NA)
title(main=title.use,line=0,col.main="darkblue")

}
