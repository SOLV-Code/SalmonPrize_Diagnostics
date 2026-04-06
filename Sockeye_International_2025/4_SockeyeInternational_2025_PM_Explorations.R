# Starting some explorations of performance measure properties

library(tidyverse)

# generic example (using rough numbers)

obs.use <- 4  # using CHilko with Obs ~4mill as example

pm.example.df <- data.frame(FC_mill = c(seq(0.4,3.99,length.out=100),seq(4,40,length.out=100)),
                                Obs_mill = 4) %>%
  mutate(Ratio = FC_mill/Obs_mill,
         PercError = (FC_mill-Obs_mill)/Obs_mill*100)  %>%
  mutate(AbsPercError = abs(PercError))

head(pm.example.df)



png(filename = paste0(folder.use,"/Diagnostics/PercentError_Properties.png"),
    width = 480*5.5, height = 480*3.9, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


x.axis.vals <- c(1/10,1/4,1/2,1,2,4,10)
x.axis.labels <- c("1/10","1/4","1/2","1","2","4","10")

plot(log(pm.example.df$Ratio,base=10),pm.example.df$AbsPercError,bty="n",axes=FALSE,
     ylim=c(0,900),type="p",pch=19,col="darkblue",
     xlab= "Ratio of FC/Obs (Base 10 log-scale)",ylab="Absolute Percent Error (APE)"
     )
title(main = paste0("For a Stock with Observed Run = ",obs.use,"M"),line=3)
axis(2,at = seq(0,900,by=100),las=1)
axis(1,at = log(x.axis.vals,base=10),labels = x.axis.labels )
axis(3, at = log(x.axis.vals,base=10),
     labels = paste0(x.axis.vals*obs.use,"M"))
mtext("Forecast",side=3,line=2)

abline(h=100,col="red",lty=2,lwd=3)

dev.off()



# How about a performance measure expressed as factors and then taking mean?
# If a FC is half of obs return, the factor is 2 , but Perc Error is = - 0.5
# If a FC is double of obs return, the factor is 2 also 2, but Perc Error is = + 1

# A team with forecasts for 3 stocks coming in at Stock A: 0.5, Stock B = 1.5,
# and Stock C = 1.2 has factors of A:  1/0.5 = 2, 1.5, 1.2 -> Mean Factor = 1.56
# Corresponding MAPE would be 0.4


pm.example.df <- pm.example.df %>% mutate(Factor= case_when(Ratio < 1 ~ 1/Ratio,
                                           Ratio >= 1 ~ Ratio))



png(filename = paste0(folder.use,"/Diagnostics/FactorPM_Properties.png"),
    width = 480*5.5, height = 480*3.9, units = "px", pointsize = 14*3.7, bg = "white",  res = NA)


plot(log(pm.example.df$Ratio,base=10),pm.example.df$Factor,bty="n",axes=FALSE,
     ylim=c(0,10),type="p",pch=19,col="darkblue",
     xlab= "Ratio of FC/Obs (Base 10 log-scale)",ylab="Factor"
)
title(main = paste0("For a Stock with Observed Run = ",obs.use,"M"),line=3)
axis(2,at = seq(0,10,by=2),las=1)
axis(1,at = log(x.axis.vals,base=10),labels = x.axis.labels )
axis(3, at = log(x.axis.vals,base=10),
     labels = paste0(x.axis.vals*obs.use,"M"))
mtext("Forecast",side=3,line=2)

dev.off()


















