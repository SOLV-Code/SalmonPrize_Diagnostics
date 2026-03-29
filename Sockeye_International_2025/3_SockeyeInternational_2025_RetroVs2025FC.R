# Script to consolidate and analyze the 2025 Sockeye International results
# Questions/comments? -> start a new issue at https://github.com/SOLV-Code/SalmonPrize_Diagnostics/issues

# THIS SCRIPT DOES A BUNCH OF PLOT EXPLORATIONS
# IT USES OBJECTS FROM THE PREVIOUS SCRIPT
# CODE HAS NOT YET BEEN CLEANED UP AND PUT INTO PROPER FUNCTIONS



###############################
# Does retrospective ranking predict 2025 performance?
# only have retro for 3 of 10 teams, but can check relative performance

# 1 Best Overall Prediction
# 2 Best Bristol Bay Prediction
# 3 Best Fraser Prediction
# 4 Best Columbia Prediction


# By system/prize

main.ranks <- results.obj$RanksByPrize

retro.ranks <- results.obj.retro$RanksByPrize
names(retro.ranks)[-c(1:2)] <- paste0(names(retro.ranks)[-c(1:2)],"_Retro")

retro.ranks

rank.comp <- main.ranks %>% left_join(retro.ranks,by = c("Prize","Team")) %>%
                dplyr::filter(!is.na(MAPE_Retro))

rank.reranked <-rank.comp %>% select(Prize,Team,MAPE,MAPE_Retro) %>%
  dplyr::filter(Prize == "3 Best Fraser Prediction") %>%
  group_by(Prize) %>%
  mutate(MAPE_Reranked= rank(MAPE)) %>% ungroup()
print(rank.reranked)

contingency.table.tmp <- table(rank.reranked %>% select(MAPE_Retro,MAPE_Reranked) )
contingency.table.tmp

chisq.test(contingency.table.tmp,
           simulate.p.value = TRUE)



# Larger Sample Test:
# Compare 2025 APE to Retro MAPE for each stock
# Across teams: 14 stocks * 3 teams = 42 samples
# by team: 14 samples

retro.teams.list <- names(retro.df %>% select(-any_of(c("System","Stock","ReturnYear","Run"))))
retro.teams.list

teams.pch <- c(21,22,23)
teams.bg <-  c("orange","lightblue","white")


ape.comp <- results.obj$PercError %>% select(all_of(c("System","Stock","Run", retro.teams.list))) %>%
                          pivot_longer(cols = all_of(retro.teams.list),
                                       names_to = "Team",values_to = "APE_2025FC")  %>%
                          mutate(APE_2025FC = abs(APE_2025FC)) %>%
  left_join(
results.obj.retro$PercError %>% group_by(Stock) %>% summarize(across(all_of(retro.teams.list), ~ round(mean(abs(.x)),2) )) %>%
  pivot_longer(cols = all_of(retro.teams.list),
               names_to = "Team",values_to = "MAPE_Retro"),
by = c("Stock","Team"))


write_csv(ape.comp,paste0(folder.use,"/Diagnostics/COMPARISON_ByStock_RetroVsFC.csv"))





# PLOT FULL RANGE


xlim.use <-  range(ape.comp$MAPE_Retro)*1.1
ylim.use <-  range(ape.comp$APE_2025FC)*1.1

plot(1:5,1:5,type="n",bty="n",
     xlab = "Retrospective MAPE (2020-2024)",
     ylab = "APE for 2025 Forecast",
     xlim = xlim.use,ylim=ylim.use,las=1,
     main = "Retrospective vs. Forecast Performance By Stock\nFull Range")

legend("topleft",legend = retro.teams.list,
       pch = teams.pch,pt.bg=teams.bg,col="darkblue",
       bty="n",ncol=3,pt.cex=2
       )

segments(0,100,100,100,col="red",lty=2)
segments(100,0,100,100,col="red",lty=2)

for(i in 1:length(retro.teams.list)){
team.do <- retro.teams.list[i]
pch.use <- teams.pch[i]
bg.use <- teams.bg[i]
print(team.do)

df.sub <- ape.comp %>% dplyr::filter(Team == team.do)

points(df.sub$MAPE_Retro,df.sub$APE_2025FC,
       pch=pch.use,col="darkblue",bg=bg.use,cex=1.2)


flag.idx <- df.sub$MAPE_Retro > 100 | df.sub$APE_2025FC > 100
text(df.sub$MAPE_Retro[flag.idx]+10,
     df.sub$APE_2025FC[flag.idx],
     gsub(" River","",df.sub$Stock[flag.idx]),
     adj=0,xpd=NA
)



}





# PLOT ZOOMED IN


xlim.use <- ylim.use <- c(0,120)

plot(1:5,1:5,type="n",bty="n",
     xlab = "Retrospective MAPE (2020-2024)",
     ylab = "APE for 2025 Forecast",
     xlim = xlim.use,ylim=ylim.use,las=1,
     main = "Retrospective vs. Forecast Performance By Stock\nZoomed In")

legend("topleft",legend = retro.teams.list,
       pch = teams.pch,pt.bg=teams.bg,col="darkblue",
       bty="n",ncol=3,pt.cex=2
)

segments(0,100,100,100,col="red",lty=2)
segments(100,0,100,100,col="red",lty=2)


# fitted line
fit.src <- ape.comp %>% dplyr::filter(MAPE_Retro <= 100,APE_2025FC <= 100)


library(rstanarm)
library(bayesplot)
library(bayestestR)

# Fit a Bayesian linear regression model
bayes.reg.fit <- stan_glm(APE_2025FC ~ MAPE_Retro, data = fit.src, seed = 123)

# model summary
print(bayes.reg.fit)

# Visualize the posterior distribution of a coefficient (e.g., 'wt')
mcmc_dens(bayes.reg.fit, pars = c("MAPE_Retro"))

# Get the 89% credible interval (CI) for parameters
hdi(bayes.reg.fit)

post.pred <- posterior_predict(bayes.reg.fit)



# plot points

for(i in 1:length(retro.teams.list)){
  team.do <- retro.teams.list[i]
  pch.use <- teams.pch[i]
  bg.use <- teams.bg[i]
  print(team.do)

  df.sub <- ape.comp %>% dplyr::filter(Team == team.do)

  points(df.sub$MAPE_Retro,df.sub$APE_2025FC,
         pch=pch.use,col="darkblue",bg=bg.use,cex=1.2)


  flag.idx <- (df.sub$MAPE_Retro > 55 | df.sub$APE_2025FC > 60) &
                  df.sub$MAPE_Retro <120 & df.sub$APE_2025FC  <120
  text(df.sub$MAPE_Retro[flag.idx]+3,
       df.sub$APE_2025FC[flag.idx],
       gsub(" River","",df.sub$Stock[flag.idx]),
       adj=0,xpd=NA
  )



}






