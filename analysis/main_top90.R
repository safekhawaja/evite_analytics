##################
## MKTG 401 data: top 90% of zip codes by events

library(tidyverse) # The basics
library(psych) # Factor and cluster analysis
library(dummies) # Indicator variables
library(TSPred) # MAPE
library(pscl) # Zero-inflated Poisson
library(reshape2)

####################################################################
# Loading and cleaning data
####################################################################

combined_df <- read_csv("combined_df.csv")

df <- combined_df # Before and after Covid.
df$date <- substr(combined_df$date, 1, 7) %>% lubridate::dmy()
df$month <- lubridate::month(df$date)
df$UnempRate <- as.numeric(df$UnempRate) / 100

# Standardizing numeric fields.  mean zero, variance one.
df <- df %>% mutate_at(c('Pop', 'ZipArea', 'Density', 'SexRatio', 'MedianAge',
                         'PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
                         'PercAsian', 'PercLatino', 'HousingUnits', 'IncomeBucket1',
                         'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
                         'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
                         'IncomeBucket10',
                         'MedianHHIncome', 'MeanHHIncome', 'PercInsured', 'TotalHHs',
                         'FamHHs', 'Perc_HHsAbSixtyFive', 'Perc_HHsBelEighteen', 'AvgHHSize',
                         'AvgFamSize', 'AvgBirthRate', 'HHwGrandpar', 'HHswComp', 'HHwInt',
                         'UnempRate', 'HighschoolRate', 'BachelorsRate',
                         'irs_estimated_population_2015'),
                       ~(scale(.) %>% as.vector))

pc <- readRDS("pca.rds")
pc_scores <- as_tibble(pc$scores)
df <- bind_cols(df, pc_scores)

df <- bind_cols(df, as_tibble(dummy(df$month))) %>% rename(January="month)))1",
                                                           February="month)))2",
                                                           March="month)))3",
                                                           April="month)))4",
                                                           May="month)))5",
                                                           June="month)))6",
                                                           July="month)))7",
                                                           August="month)))8",
                                                           September="month)))9",
                                                           October="month)))10",
                                                           November="month)))11",
                                                           December="month)))12")

df_bc <- df[df$after_covid == 0,]
df_ac <- df[df$after_covid == 1,]

# Before Covid.
df_bc_grouped <- df_bc %>% group_by(ZIP) %>% summarise(events = sum(events))

df_bc_grouped <- df_bc_grouped[order(df_bc_grouped$events),] %>% mutate(cum = cumsum(events)/sum(events))
df_bc_grouped$cum_zips <- seq(0, 27428, 1) / 27428
df_bc_grouped

ggplot(data=df_bc_grouped, aes(x=cum_zips, y=cum)) +
    geom_line() +
    labs(title="Pareto Chart: Percentage of Events by Percentile of Zip Codes, before March 2020",x="Percentile of Zip Codes, by events before March 2020", y = "Percentage of Sales")

# After Covid.
df_ac_grouped <- df_ac %>% group_by(ZIP) %>% summarise(events = sum(events))

df_ac_grouped <- df_ac_grouped[order(df_ac_grouped$events),] %>% mutate(cum = cumsum(events)/sum(events))
df_ac_grouped$cum_zips <- seq(0, 27428, 1) / 27428
df_ac_grouped

ggplot(data=df_ac_grouped, aes(x=cum_zips, y=cum)) +
    geom_line() +
    labs(title="Pareto Chart: March 2020 and onward",x="Percentile of Zip Codes", y = "Percentage of Total Events")

df_bc_grouped[df_bc_grouped$cum_zips >= 0.75,]

# The top 12.5% of zip codes, which were responsible for ~75% of Evite's events.
top_twelve_bc <- df_bc_grouped[df_bc_grouped$cum_zips >= 0.875,]
top_twelve_ac <- df_ac_grouped[df_ac_grouped$cum_zips >= 0.875,]

# 90.5% of zip codes in the top 12.5% remained in the top 12.5% from before to after Covid.
mean((top_twelve_bc$ZIP %in% top_twelve_ac$ZIP) == TRUE)

# The top 6.25% of zip codes, which were responsible for ~50% of Evite's events.
top_six_bc <- df_bc_grouped[df_bc_grouped$cum_zips >= 0.9375,]
top_six_ac <- df_ac_grouped[df_ac_grouped$cum_zips >= 0.9375,]

# 86% of zip codes in the top 6.25% remained in the top 6.25% from before to after Covid.
mean((top_six_bc$ZIP %in% top_six_ac$ZIP) == TRUE)

top_df <- df[df$ZIP %in% df_bc_grouped[df_bc_grouped$cum >= 0.10,]$ZIP,]
bottom_df <- df[!(df$ZIP %in% df_bc_grouped[df_bc_grouped$cum >= 0.10,]$ZIP),]

top_df_bc <- top_df[top_df$after_covid == 0,] # Before Covid.
top_df_ac <- top_df[top_df$after_covid == 1,] # After Covid.

####################################################################
# Cluster analysis
####################################################################

# Please note that the cluster analyis will create the same clusters
# each time if run on the same dataset, but it may create them in
# different orders.

# Before Covid.
ctr <- kmeans(df_bc %>% group_by(ZIP) %>%
           summarise(IncomeBucket1 = mean(IncomeBucket1),
                     IncomeBucket2 = mean(IncomeBucket2),
                     IncomeBucket3 = mean(IncomeBucket3),
                     IncomeBucket4 = mean(IncomeBucket4),
                     IncomeBucket5 = mean(IncomeBucket5),
                     IncomeBucket6 = mean(IncomeBucket6),
                     IncomeBucket7 = mean(IncomeBucket7),
                     IncomeBucket8 = mean(IncomeBucket8),
                     IncomeBucket9 = mean(IncomeBucket9),
                     IncomeBucket10 = mean(IncomeBucket10)
           ), centers = 3)
ctr

df_bc$cluster <- ctr$cluster

# Low-income, middle-income, and high-income clusters.

by_cluster <- df_bc %>% group_by(date, cluster) %>% summarise(total_events = sum(events))
# by_cluster$cluster <- sapply(by_cluster$cluster, function(x) ifelse(x==1, "High-income", ifelse(x==2, "Low-income", "Middle-income")))

ggplot(data = by_cluster, aes(x=date, y=total_events)) + geom_line(aes(colour=cluster))

# Before and after Covid.
ctr <- kmeans(df %>% group_by(ZIP) %>%
                  summarise(IncomeBucket1 = mean(IncomeBucket1),
                            IncomeBucket2 = mean(IncomeBucket2),
                            IncomeBucket3 = mean(IncomeBucket3),
                            IncomeBucket4 = mean(IncomeBucket4),
                            IncomeBucket5 = mean(IncomeBucket5),
                            IncomeBucket6 = mean(IncomeBucket6),
                            IncomeBucket7 = mean(IncomeBucket7),
                            IncomeBucket8 = mean(IncomeBucket8),
                            IncomeBucket9 = mean(IncomeBucket9),
                            IncomeBucket10 = mean(IncomeBucket10)
                  ), centers = 3)
ctr

df$cluster <- ctr$cluster

# Low-income, middle-income, and high-income clusters.

by_cluster <- df %>% group_by(date, cluster) %>% summarise(total_events = sum(events))
# by_cluster$cluster <- sapply(by_cluster$cluster, function(x) ifelse(x==1, "High-income", ifelse(x==3, "Middle-income", "Low-income")))

ggplot(data = by_cluster, aes(x=date, y=total_events)) + geom_line(aes(colour=cluster))

####################################################################
# Poisson regression
####################################################################

# Poisson regressions are appropriate here because we are dealing
# with count data with large amounts of zeroes.
hist(top_df_ac$events)
hist(top_df_bc$events)

# Poisson
pm <- glm(events ~ 1, family="poisson", data=top_df_bc %>% dplyr::select(
    ZIP, events
))
summary(pm)

pm <- glm(events ~ . - ZIP, family="poisson", data=top_df_bc %>% dplyr::select(
    ZIP, events, RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8, RC9,
    February, March, April, May, June, July, August, September,
    October, November, December, region
))
summary(pm)

MAPE(top_df_bc$events + 1, pm$fitted.values + 1)

df <- data.frame(fitted = pm$fitted.values,
                 actual = top_df_bc_minus_one$events)
ggplot(melt(df), aes(value, fill = variable)) + geom_histogram(position = "dodge")

top_df_bc_minus_one <- top_df_bc
top_df_bc_minus_one$events <- top_df_bc$events - 1

pm <- glm(events ~ . - ZIP, family="poisson", data=top_df_bc_minus_one %>% dplyr::select(
    ZIP, events, RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8, RC9,
    February, March, April, May, June, July, August, September,
    October, November, December, region
))
summary(pm)

MAPE(top_df_bc_minus_one$events + 1, pm$fitted.values + 1)

floor(top_df_bc$events / 50)


# NBD
library(MASS)

nbd <- glm.nb(events ~ 1, data=top_df_bc %>% dplyr::select(
    ZIP, events
))
summary(nbd)

nbd <- glm.nb(events ~ . - ZIP, data=top_df_bc %>% dplyr::select(
    ZIP, events, RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8, RC9,
    February, March, April, May, June, July, August, September,
    October, November, December, region
))
summary(nbd)

MAPE(top_df_bc$events + 1, nbd$fitted.values)
MAPE(top_df_bc$events + 1, nbd$fitted.values %>% sapply(function(x) max(x, 0)))

# Estimated lambda
pm$terms
mean(top_df_bc$events)

# Zero-inflated Poisson isn't an improvement on the Poisson, so I've deleted the code here.

####################################################################
# Drop in events before and after Covid
####################################################################

events_per_month_bc <- df_bc %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_bc = events)
events_per_month_ac <- df_ac %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_ac = events)

events_per_month_ac <- events_per_month_ac %>% left_join(events_per_month_bc, by=c("ZIP", "month"))
events_per_month_ac$events_change <- events_per_month_ac$events_ac - events_per_month_ac$events_bc
events_per_month_ac

df_ac <- left_join(df_ac, events_per_month_ac, by=c("ZIP", "month")) %>% select(-events_ac, -events_bc)

lin <- lm(events_change ~ ., df_ac %>%
              select(RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8, RC9,
                     March, April, May, June, July, August, events_change))
summary(lin)
