#Jonas Schmitten & Noah Angara
#Economics in Practice
#March 2021

#packages
library("readxl")
library("dplyr")
library("purrr")
library("stringr")
library("xts")
library("ggplot2")
library("ggthemes")
library("zoo")
library("tibble")
library("mixtools")
library("stargazer")
library("alphastable")
library("midasr")
library("data.table")

#setting working directory
Paths = c("/Users/jonasschmitten/Desktop/FS 2021/Economics in Practice/Clean Data", 
          "/Users/noahangara/Documents/Master's/8th Semester/Economics in Practice")
names(Paths) = c("jonasschmitten", "noahangara")
setwd(Paths[Sys.info()[7]])

#Read in Data Prepared by Data_Cleaning.R
bid_ask = read.csv('Bid_Ask_Clean.csv')
spot_rates = read.csv('Spot_Rates_Clean.csv')
spot_rates$dates <- as.Date(spot_rates$dates)
spot_rates_returns = read.csv('Spot_Rates_Returns_Clean.csv')
spot_rates_returns$dates <- as.Date(spot_rates_returns$dates)
daily_independent_returns = read.csv('Daily_Independent_Returns_Clean.csv')

# Data Visualization ------------------------------------------------------

#setting new working directory for graphs
Paths = c("/Users/jonasschmitten/Desktop/FS 2021/Economics in Practice/Graphs", 
          "/Users/noahangara/Documents/Master's/8th Semester/Economics in Practice/Graphs")
names(Paths) = c("jonasschmitten", "noahangara")
setwd(Paths[Sys.info()[7]])

# US Recession Start and End as per FRED St. Louis
recessions.df = read.table(textConnection(
  "Peak, Trough, Type
1973-11-01, 1975-03-01, Recession
1980-01-01, 1980-07-01, Recession
1981-07-01, 1982-11-01, Recession
1990-07-01, 1991-03-01, Recession
2001-03-01, 2001-11-01, Recession
2007-12-01, 2009-06-01, Recession
2009-10-01, 2013-05-01, Euro-Crisis
2020-02-01, 2021-03-18, Recession"), sep=',', colClasses=c('Date', 'Date', 'character'), header=TRUE)
recessions.trim = subset(recessions.df, Peak >= "2000-03-17")
rm(recessions.df)

# Loop to Create Plots of Spot Rates With Recession Shading
plot_list = list()
for (i in colnames(spot_rates[2:ncol(spot_rates)])) {
  z = zoo(spot_rates[, i], order.by = spot_rates$dates)
  g = ggplot(fortify(z,melt=T)) +
    geom_rect(data=recessions.trim, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=+Inf, color = recessions.trim$Type, fill=recessions.trim$Type), alpha=0.5)+
    geom_line(aes(x=Index,y=Value))+ 
    labs(y = "Spot Rate", x= "", color = "", fill = "") + theme_economist_white(gray_bg = F)+ ggtitle(" ") + labs(y = "Spot Rate", x= "", fill = "", color = "") + 
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0)) + 
    scale_color_manual(values = c("1" = "black", "2" = "black")) + scale_fill_manual(values = c(" Euro-Crisis" = "#000099", " Recession" = "gray69"))
  plot_list[[i]] = g
  ggsave(g, file=paste0("plot_", i,".png"), width = 14, height = 10, units = "cm")
}
rm(i)
rm(z)

#plotting GDP expenditure side from SECO
gdp <- read_excel("expendituregdp.xlsx")
colnames(gdp)[4] = "Gov. Exp."
gdp_line = gdp[,c(1,2)]
gdp <- gdp[,-2]
gdp$Imports = gdp$Imports*-1
gdp = melt(gdp, "Year")
gdpplot = ggplot(data = gdp, aes(x = gdp$Year, y = gdp$value, fill = gdp$variable))+ 
  geom_bar(stat = "identity") + labs(x = "", y = "CHF (Millions)", fill = "") + scale_y_continuous(labels = comma)+theme_economist_white(gray_bg = F)+
  theme(legend.position="bottom", legend.box="vertical", legend.box.margin=margin(-20,30, 0, 0),legend.key.width=unit(0.1,"cm"),
        plot.title = element_text(hjust = 0.5), text = element_text(size = 10, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)))
ggsave(gdpplot, file=paste0("gdpplot_", i,".png"), width = 14, height = 10, units = "cm")

#plotting monthly SNB sight deposits 
sight_deposits = read_excel("sightdeposits.xlsx")
sight_deposits$Total = sight_deposits$`Liabilities - Sight deposits of domestic banks`+
  sight_deposits$`Liabilities - Amounts due to the Confederation`+
  sight_deposits$`Liabilities - Sight deposits of foreign banks and institutions`+
  sight_deposits$`Liabilities - Other sight liabilities`
sight_deposits$Overview = as.Date(paste(sight_deposits$Overview,"-01",sep=""))
sight = ggplot(data = sight_deposits, aes(y = sight_deposits$Total, x = as.Date(sight_deposits$Overview)))+
  geom_area(fill = "#7ca3c6")+ theme_economist_white(gray_bg = F)+ ggtitle(" ") + labs(y = "CHF (Millions)", x= "", fill = "", color = "") + 
  theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
        legend.box.margin=margin(-20,0, 0, 0)) + scale_y_continuous(labels = comma)
ggsave(sight, file=paste0("sightdeposits_", i,".png"), width = 14, height = 10, units = "cm")


# Data Exploration --------------------------------------------------------

#summary statistics for spot returns
summary_spot <- summarise_all(spot_rates_returns[,c("CHF.USD", "CHF.GBP", "CHF.EUR", "CHF.JPY")],
                               funs(min, mean, max, count = length))
summary_spot_clean <- data.frame(min = 100*c(summary_spot[1,1], summary_spot[1,2], summary_spot[1,3], summary_spot[1,4]),
                            mean = 100*c(summary_spot[1,5], summary_spot[1,6], summary_spot[1,7], summary_spot[1,8]),
                            max = 100*c(summary_spot[1,9], summary_spot[1,10], summary_spot[1,11], summary_spot[1,12]),
                            count = c(summary_spot[1,13], summary_spot[1,14], summary_spot[1,15], summary_spot[1,16]))
rownames(summary_spot_clean) <- c("CHF.USD", "CHF.GBP", "CHF.EUR", "CHF.JPY")
stargazer(summary_spot_clean, summary = F)

#summary statistics for daily independent variables
summary_independent <- summarise_all(daily_independent_returns[,c("PUT.CALL", "JPM_GLOBAL_FX_VOLA", "VSTOXX", "MSCI")],
                                     funs(min, mean, max, count = length))
summary_independent_clean <- data.frame(min = 100*c(summary_independent[1,1], summary_independent[1,2], summary_independent[1,3], summary_independent[1,4]),
                                 mean = 100*c(summary_independent[1,5], summary_independent[1,6], summary_independent[1,7], summary_independent[1,8]),
                                 max = 100*c(summary_independent[1,9], summary_independent[1,10], summary_independent[1,11], summary_independent[1,12]),
                                 count = c(summary_independent[1,13], summary_independent[1,14], summary_independent[1,15], summary_independent[1,16]))
rownames(summary_independent_clean) <- c("Put Call Ratio", "JPM FX Vola", "VSTOXX", "MSCI")
stargazer(rbind(summary_spot_clean,summary_independent_clean), summary = F, no.space = T, notes = "\\textit{Note:}", notes.align = "l")


#histogram of FX returns
hist_plots = list()
for (i in colnames(spot_rates_returns[,2:ncol(spot_rates_returns)])) {
  n = ggplot(spot_rates_returns, aes(x=spot_rates_returns[,i])) +
  geom_histogram(color="black", fill="red", alpha = 0.5, bins = 100) +
    geom_vline(xintercept = mean(spot_rates_returns[,i])) + theme_economist_white(gray_bg = F) + xlab("") + 
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0))
  hist_plots[[i]] = n
  ggsave(n, file=paste0("hist_", i,".png"), width = 14, height = 10, units = "cm")
}

#qq-plots of FX returns
qq_plots = list()
for (i in colnames(spot_rates_returns[,2:ncol(spot_rates_returns)])) {
  j = ggplot(spot_rates_returns, aes(sample=spot_rates_returns[,i])) +
  stat_qq(color = "red", alpha = 0.5) + stat_qq_line() + theme_economist_white(gray_bg = F) + 
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0))
  qq_plots[[i]] <- j
  ggsave(j, file=paste0("qq_", i,".png"), width = 14, height = 10, units = "cm")
}

#significant dates
significant_dates <- read.table(textConnection(
"Date, Event
2001-09-11, Terrorist
2004-03-11, Terrorist
2005-07-07, Terrorist
2010-05-06, Flash Crash
2013-04-23, Flash Crash
2015-01-15, SNB Floor
2015-11-13, Terrorist
2017-05-22, Terrorist"), sep=',', colClasses = c("Date", "character"), header=TRUE)

#plots to show different components in spot returns with recession shading and significant dates
mixture_plots <- list("CHF.USD", "CHF.GBP", "CHF.EUR")
for (i in mixture_plots) {
  assign(paste0(i, "_mix"), normalmixEM(spot_rates_returns[1:5479, i], k = 2))
  assign(paste0(i, "_mix_df"), spot_rates_returns[,c(i, "dates")])
  toAssign <- paste0(i, "_mix_df", "[,'component']")
  str1 <- paste0(toAssign, "<-", "ifelse(eval(parse(text = paste0(i, '_mix', '$posterior[, 1]')))<0.5, '2', '1')")
  eval(parse(text=str1))
  #recession shading
  mix_plot = ggplot() +
    geom_rect(data = recessions.trim, aes(xmin=Peak, xmax=Trough, ymin=-Inf, ymax=+Inf, fill=recessions.trim$Type), alpha = 0.5)+
    geom_point(data = eval(parse(text = paste0(i, "_mix_df"))), aes(x = dates, y = eval(parse(text = paste0(i, "_mix_df[,1]")))), color = eval(parse(text = paste0(i, "_mix_df[,3]"))), size = 1)+ 
    theme_economist_white(gray_bg = F)+ ggtitle(" ") + labs(y = "Spot Rate Return", x= "", fill = "", color = "") + 
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0)) + 
    scale_color_manual(values = c("2" = "black", "1" = "red")) + scale_fill_manual(values = c(" Euro-Crisis" = "#000099", " Recession" = "gray69"))
  ggsave(mix_plot, file=paste0("mixplot_", i,".png"), width = 14, height = 10, units = "cm")
  #significant dates (terrorist dates etc.)
  significant_dates_plot = ggplot()+ 
    geom_point(data = eval(parse(text = paste0(i, "_mix_df"))), aes(x = dates, y = eval(parse(text = paste0(i, "_mix_df[,1]")))), color = eval(parse(text = paste0(i, "_mix_df[,3]"))), size = 1)+ geom_vline(data = significant_dates, size = 1,alpha = 0.6, aes(xintercept = significant_dates$Date, color = significant_dates$Event))+
    theme_economist_white(gray_bg = F)+ ggtitle(" ") + labs(y = "Spot Rate Return", x= "", fill = "", color = "") + 
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0)) + 
    scale_color_manual(values = c(" SNB Floor" = "#FF0000", " Terrorist" = "gray14", " Flash Crash" = "darkorchid"))
  ggsave(significant_dates_plot, file=paste0("significantdateplot_", i,".png"), width = 14, height = 10, units = "cm")
}

CHF.NOK_plot = normalmixEM(spot_rates_returns[1:5479, 7], k = 2)
sdnorm = function(x, mean=0, sd=1, lambda=1){lambda*dnorm(x, mean=mean, sd=sd)}
ggplot(spot_rates_returns, aes(x = CHF.NOK)) + 
  stat_function(fun = dnorm, 
                args = list(mean = CHF.NOK_plot[["mu"]][[1]], 
                            sd = CHF.NOK_plot[["sigma"]][[1]]), geom  = "area", alpha = 0.5, fill = "dodgerblue") +
  stat_function(fun = dnorm, 
                args = list(mean = CHF.NOK_plot[["mu"]][[2]], 
                            sd = CHF.NOK_plot[["sigma"]][[2]]), geom = "area", alpha = 0.5, fill = "firebrick") + 
  geom_line(data = data.frame(x = c(CHF.NOK_plot[["mu"]][[2]], CHF.NOK_plot[["mu"]][[2]]), y = c(0, 100)), aes(x = x , y = y), color = "firebrick4")  + 
  geom_line(data = data.frame(x = c(CHF.NOK_plot[["mu"]][[1]], CHF.NOK_plot[["mu"]][[1]]), y = c(0, 100)), aes(x = x , y = y), color = "dodgerblue4") +
  labs(x = "", y = "") +
  theme_economist_white(gray_bg = F) + theme(text = element_text(size = 12, family = "Palatino"))


# Finite Gaussian Mixture  ------------------------------------------------

#state dependent regression models
for (i in c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")){
  #split data into regimes to run separate regressions
  normalmix = normalmixEM(spot_rates_returns[1:5479, i])
  segmented = as.data.frame(spot_rates_returns[1:5479, c(i, "dates")])
  #normalmixEM is not consistent in naming components, hene we need to check if it is consistent
  if(normalmix$lambda[1] > normalmix$lambda[2]){
    normalmix$posterior = normalmix$posterior[,c(2,1)]
  }
  #separate spot returns into component 1 and 2 via posterior likelihoods
  segmented$component = ifelse(normalmix$posterior[,1]<0.5, "1", "2")
  segmented$matching_col = as.Date(ifelse(segmented$component== "1", segmented$dates, 0))
  #separate independent vars into component 1 and 2
  reg1 = segmented[segmented$component == "1",]
  reg2 = segmented[segmented$component == "2",]
  independent_comp1 = daily_independent_returns[which(segmented$matching_col == head(daily_independent_returns$dates,5479)),]
  independent_comp2 = daily_independent_returns[which(segmented$matching_col != head(daily_independent_returns$dates,5479)),]
  
  #Analyse independent variables between the two componenets
  assign(paste0(i, "_threshold_vars"), data.frame(up1 = sapply(independent_comp1[,2:ncol(independent_comp1)], function(x) mean(x[which(x>0)],na.rm = T)), 
                                                  down1 = sapply(independent_comp1[,2:ncol(independent_comp1)], function(x) mean(x[which(x<0)],na.rm = T) )))
  
  
  if (i %in% c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL")){
    #add bid_ask to independent variables
    independent_comp1$Bid_ask = bid_ask[which(segmented$matching_col == bid_ask$Date), paste0("X.",i)]
    independent_comp2$Bid_ask = bid_ask[which(segmented$matching_col != bid_ask$Date), paste0("X.",i)]
  
    #run regressions on each data set
    assign(paste0(i,"reg_model1_2000"), lm(formula = reg1[,i] ~ MSCI  + PUT.CALL  + MOVE_3M + VIX + VSTOXX + TED_SPREAD + GOLD +JPM_GLOBAL_FX_VOLA + X10Y_BREAKEVEN + BARC_US_CORP_HY_10Y + Bid_ask,  data = independent_comp1))
    assign(paste0(i, 'reg_model2_2000'), lm(formula = reg2[,i] ~ MSCI  + PUT.CALL  + MOVE_3M + VIX + VSTOXX + TED_SPREAD + GOLD +JPM_GLOBAL_FX_VOLA + X10Y_BREAKEVEN + BARC_US_CORP_HY_10Y + Bid_ask, data = independent_comp2))

  } else {
    assign(paste0(i,"reg_model1_2000"), lm(formula = reg1[,i] ~ MSCI  + PUT.CALL  + MOVE_3M + VIX + VSTOXX + TED_SPREAD + GOLD +JPM_GLOBAL_FX_VOLA + X10Y_BREAKEVEN + BARC_US_CORP_HY_10Y ,  data = independent_comp1))
    assign(paste0(i, 'reg_model2_2000'), lm(formula = reg2[,i] ~ MSCI + PUT.CALL  + MOVE_3M + VIX + VSTOXX + TED_SPREAD + GOLD +JPM_GLOBAL_FX_VOLA + X10Y_BREAKEVEN + BARC_US_CORP_HY_10Y , data = independent_comp2))
    } 
  rm(normalmix, independent_comp1, independent_comp2, segmented, reg1, reg2)
}


#Rename component 1 as crisis and component 2 as business as usual
for (i in c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")){
  if(summary(get(paste0(i, "reg_model1_2000")))$fstatistic[3] > summary(get(paste0(i, "reg_model2_2000")))$fstatistic[3]){
    
    assign(paste0(i, "reg_model2"), get(paste0(i, "reg_model1_2000")))
    assign(paste0(i, "reg_model1"), get(paste0(i, "reg_model2_2000")))
  
    }else { 
      assign(paste0(i, "reg_model1"), get(paste0(i, "reg_model1_2000")))
      assign(paste0(i, "reg_model2"), get(paste0(i, "reg_model2_2000")))
    }
rm(list = c(paste0(i, "reg_model1_2000"),paste0(i, "reg_model2_2000") ))
    }

#Save Lambda and Sigma Parameters of Mixture
comp1_list = list()
comp2_list = list()
for (i in c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")){
  mix_object = normalmixEM(spot_rates_returns[1:5479, i], k = 2)
  if(mix_object$lambda[1] > mix_object$lambda[2]){
    mix_object$lambda = mix_object$lambda[c(2,1)]
    mix_object$sigma = mix_object$sigma[c(2,1)]
  }
  comp1_list[[i]] = c(mix_object$lambda[1], mix_object$sigma[1])
  comp2_list[[i]] = c(mix_object$lambda[2], mix_object$sigma[2])
}
#format lambda and sigma into table to present results
final_table = do.call(rbind, Map(data.frame, A=comp1_list, B=comp2_list))
colnames(final_table) = c("Component 1", "Component 2")
row.names(final_table)[seq(1,18,2)] = paste0(row.names(final_table)[seq(1,18,2)], "lambda")
row.names(final_table)[seq(2,19,2)] = paste(row.names(final_table)[seq(2,19,2)],"sigma")
row.names(final_table) = gsub('[0-9]+', '', row.names(final_table))

#Lambda and Ligma for Crisis Period
table_crisis = as.data.frame(rbind(final_table[seq(1,18,2),1], final_table[seq(2,19,2),1])) #first component
names(table_crisis) = c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")
row.names(table_crisis) = c('Lambda', "Sigma")
table_normal = as.data.frame(rbind(final_table[seq(1,18,2),2], final_table[seq(2,19,2),2])) #second component
names(table_normal) = c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")
row.names(table_normal) = c('Lambda', "Sigma")

#CREATE LAMBDA AND SIGMA LATEX TABLE
stargazer(table_crisis, no.space = T, summary = F, title = 'Lambda and Sigma Parameter Gaussian Mixture Crisis State')
stargazer(table_normal, no.space = T, summary = F, title = 'Lambda and Sigma Parameter Gaussian Mixture Non-Crisis State')



#stargazer to create LaTeX table of results
#CRISIS TABLE
stargazer(CHF.EURreg_model1, CHF.GBPreg_model1, CHF.USDreg_model1, CHF.JPYreg_model1, CHF.BRLreg_model1, CHF.INRreg_model1, CHF.NOKreg_model1, JPY.USDreg_model1, BRL.USDreg_model1, 
          column.labels=c("CHF/EUR","CHF/GBP", "CHF/USD", "CHF/JPY", "CHF/BRL", "CHF/INR", "CHF/NOK", "JPY/USD", "BRL/USD"), no.space = T, df = F, model.numbers = F, object.names=F, model.names = F, align = T, title = "Regressions crisis period", 
          column.sep.width = "-15pt")


#NON-CRISIS TABLE
stargazer(CHF.EURreg_model2, CHF.GBPreg_model2, CHF.USDreg_model2, CHF.JPYreg_model2, CHF.BRLreg_model2, CHF.INRreg_model2, CHF.NOKreg_model2, JPY.USDreg_model2, BRL.USDreg_model2, 
          column.labels=c("CHF/EUR","CHF/GBP", "CHF/USD", "CHF/JPY", "CHF/BRL", "CHF/INR", "CHF/NOK", "JPY/USD", "BRL/USD"), no.space = T, df = F,  model.numbers = F, object.names=F, model.names = F, align = T, title = "Regressions non-crisis period", 
          column.sep.width = "-15pt")


#threshold values in latex
rel_thres = c( 'PUT.CALL', 'VIX', "VSTOXX", 'TED_SPREAD', 'GOLD', 'JPM_GLOBAL_FX_VOLA', 'BARC_US_CORP_HY_10')
stargazer(cbind(CHF.EUR_threshold_vars[rel_thres,][,1]*100, CHF.GBP_threshold_vars[rel_thres,][,1]*100, CHF.USD_threshold_vars[rel_thres,][,1]*100, CHF.JPY_threshold_vars[rel_thres,][,1]*100, CHF.BRL_threshold_vars[rel_thres,][,1]*100, CHF.INR_threshold_vars[rel_thres,][,1]*100,
                CHF.NOK_threshold_vars[rel_thres,][,1]*100, JPY.USD_threshold_vars[rel_thres,][,1]*100, BRL.USD_threshold_vars[rel_thres,][,1]*100)
          , summary = F, column.labels = c("CHF/EUR","CHF/GBP", "CHF/USD", "CHF/JPY", "CHF/BRL", "CHF/INR", "CHF/NOK", "JPY/USD", "BRL/USD"), no.space = T, title = 'Positive Treshold Values')
stargazer(cbind(CHF.EUR_threshold_vars[rel_thres,][,2]*100, CHF.GBP_threshold_vars[rel_thres,][,2]*100, CHF.USD_threshold_vars[rel_thres,][,2]*100, CHF.JPY_threshold_vars[rel_thres,][,2]*100, CHF.BRL_threshold_vars[rel_thres,][,2]*100, CHF.INR_threshold_vars[rel_thres,][,2]*100,
                CHF.NOK_threshold_vars[rel_thres,][,2]*100, JPY.USD_threshold_vars[rel_thres,][,2]*100, BRL.USD_threshold_vars[rel_thres,][,2]*100)
          , summary = F, column.labels = c("CHF/EUR","CHF/GBP", "CHF/USD", "CHF/JPY", "CHF/BRL", "CHF/INR", "CHF/NOK", "JPY/USD", "BRL/USD"), no.space = T, title = 'Negative Treshold Values')

 
#threshold plot for all independent vars for CHF.EUR
threshold_mix = normalmixEM(spot_rates_returns[1:5479, "CHF.EUR"], k = 2)
threshold_df = spot_rates_returns[,c("CHF.EUR", "dates")]
threshold_df$component = ifelse(threshold_mix$posterior[,1]<0.5, '2', '1')
threshold_df$matching_col = as.Date(ifelse(threshold_df$component== "1", threshold_df$dates, 0))
threshold_plots = list()
for (i in colnames(daily_independent_returns[,2:ncol(daily_independent_returns)])) {
  independent_thresh1 = daily_independent_returns[which(threshold_df$matching_col == head(daily_independent_returns$dates,5479)), c(i, "dates")]
  independent_thresh2 = daily_independent_returns[which(threshold_df$matching_col != head(daily_independent_returns$dates,5479)), c(i, "dates")]
  independent_thresh1$component = 1
  independent_thresh2$component = 2
  final_thresh = rbind(independent_thresh1, independent_thresh2)
  final_thresh = final_thresh[order(final_thresh$dates),]
  threshold_plot = ggplot(data = final_thresh, aes(x = as.Date(dates), y = final_thresh[,1])) +
    geom_point(color = final_thresh$component, size = 1)+ geom_hline(yintercept = c(CHF.EUR_threshold_vars[i,1], CHF.EUR_threshold_vars[i,2]), color = "firebrick", size = 1.5) +theme_economist_white(gray_bg = F)+
    ggtitle(i) + labs(y = "Return", x= "", color = "", title = "") + theme(legend.position="bottom", plot.title = element_text(hjust = 0.5)) +
    theme(legend.position="bottom", plot.title = element_text(hjust = 0.5), text = element_text(size = 12, family = "Palatino"), axis.title.y = element_text(margin = margin(t = 0, r = 10, b = 0, l = 0)),
          legend.box.margin=margin(-20,0, 0, 0))+ scale_color_manual(values = c("1" = "red", "2" = "black"))
  threshold_plots[[i]] = threshold_plot
  ggsave(threshold_plot, file=paste0("threshold_", i,".png"), width = 14, height = 10, units = "cm")
}


#table of proportions of deviations from threshold (loop through currencies and independent vars)
currency_thresh_list = list()
independent_var_thresh_list = list()
for (i in c("CHF.EUR", "CHF.USD", "CHF.GBP", "CHF.JPY", "CHF.NOK", "CHF.INR", "CHF.BRL", "JPY.USD", "BRL.USD")){
  proportion_mix = normalmixEM(spot_rates_returns[1:5479, i], k = 2)
  #check for consistentcy in component naming again
  if(proportion_mix$lambda[1] > proportion_mix$lambda[2]){
    proportion_mix$posterior = proportion_mix$posterior[,c(2,1)]
  }
  #separate spot and independent vars into components to pipe into proportion calculations below
  proportion_df = spot_rates_returns[,c(i, "dates")]
  proportion_df$component = ifelse(proportion_mix$posterior[,1]<0.5, '2', '1')
  proportion_df$matching_col = as.Date(ifelse(proportion_df$component== "1", proportion_df$dates, 0))
  independent_thresh1 = daily_independent_returns[which(proportion_df$matching_col == head(daily_independent_returns$dates,5479)), ]
  independent_thresh2 = daily_independent_returns[which(proportion_df$matching_col != head(daily_independent_returns$dates,5479)), ]
  independent_thresh1$component = 1
  independent_thresh2$component = 2
  final_thresh = rbind(independent_thresh1, independent_thresh2)
  final_thresh = final_thresh[order(final_thresh$dates),]
  for (j in colnames(daily_independent_returns[,2:ncol(daily_independent_returns)])) {
    
    #proportion of deviations in crisis period
    deviation_crisis = c(
      length(which(independent_thresh1[,j]>eval(parse(text = paste(i,"_threshold_vars", "[", paste("'",j,"'", sep = ""), ",1]", sep = "")))))/nrow(independent_thresh1),
      length(which(independent_thresh1[,j]<eval(parse(text = paste(i,"_threshold_vars", "[", paste("'",j,"'", sep = ""), ",2]", sep = "")))))/nrow(independent_thresh1)
    )
    #proportion of deviations in normal period
    deviation_normal = c(
    length(which(independent_thresh2[,j]>eval(parse(text = paste(i,"_threshold_vars", "[", paste("'",j,"'", sep = ""), ",1]", sep = "")))))/nrow(independent_thresh2),
    length(which(independent_thresh2[,j]<eval(parse(text = paste(i,"_threshold_vars", "[", paste("'",j,"'", sep = ""), ",2]", sep = "")))))/nrow(independent_thresh2)
    )
    #add threshold proportions of all independent vars
    independent_var_thresh_list[[j]] = c(deviation_crisis, deviation_normal)
  }
  #add independent threshold proportions per currency
  currency_thresh_list[[i]] = independent_var_thresh_list
}
