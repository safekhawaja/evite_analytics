##################
## MKTG 401 data

library(tidyverse) # The basics
library(psych) # Factor and cluster analysis
library(dummies) # Indicator variables
library(TSPred) # MAPE
library(pscl) # Zero-inflated Poisson

# TODO: testing and training datasets, re-run regressions on only the zipcodes that tend to make purchases,
#       run Poisson regression

####################################################################
# Loading and cleaning data
####################################################################

combined_df <- read_csv("combined_df.csv")
stateRegions <- read_csv("stateRegions.csv")
combined_df <- combined_df %>% left_join(stateRegions, by="state") %>% select(-X_merge)

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

df_bc <- df[df$after_covid == 0,] # Before Covid.
df_ac <- df[df$after_covid == 1,] # After Covid.

####################################################################
# Factor analysis
####################################################################

# There's no detectable change between running the factor analysis with all of the data and running
# the factor aalysis with the data before Covid.

####################
# All numeric fields

for_factor_analysis <- df_bc %>%
  select(c('Pop', 'ZipArea', 'Density', 'SexRatio', 'MedianAge',
           'PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
           'PercAsian', 'PercLatino', 'HousingUnits', 'IncomeBucket1',
           'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
           'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
           'IncomeBucket10',
           'MedianHHIncome', 'MeanHHIncome', 'PercInsured', 'TotalHHs',
           'FamHHs', 'Perc_HHsAbSixtyFive', 'Perc_HHsBelEighteen', 'AvgHHSize',
           'AvgFamSize', 'AvgBirthRate', 'HHwGrandpar', 'HHswComp', 'HHwInt',
           'UnempRate', 'HighschoolRate', 'BachelorsRate',
           'irs_estimated_population_2015')) %>%
  select_if(is.numeric)

# Uncomment if you want to verify that there are nine factors (SS Loadings >= 1)
# principal(for_factor_analysis, nfactors=38, rotate="none", scores=TRUE, missing=TRUE, impute="median")

# Looks like there are nine factors (SS Loadings >= 1)
# Adding missing=TRUE to impute missing values.
pc <- principal(for_factor_analysis, nfactors=9, scores=TRUE, missing=TRUE, impute="median")
pc

# RC3: population (>=0.95: Pop, HousingUnits, TotalHHs, FamHHs, irs_estimated_population_2015)
# RC1: (high) income (>=0.90: MedianHHIncome, MeanHHIncome; >=70: IncomeBucket9, IncomeBucket10, HHwInt, BachelorsRate; IncomeBuckets 1-5 are negatively correlated ~0.50)
# RC5: age (>=0.79: MedianAge, PercPopOver65, Perc_HHsAbSixtyFive)
# RC2: household size (>=0.80: AvgHHSize, AvgFamSize)
# RC4: not IncomeBucket6 (<=-0.90: IncomeBucket6)
# RC6: white (<=-0.75: PercWhite; >=0.85: PercBlack)
# RC8: density / Latino percentage (>=0.49: Density, PercLatino)
# RC7: sex (>=0.80: SexRatio)
# RC9: zip code area (>=-0.70: ZipArea)

pc_scores <- as_tibble(pc$scores)

# Regression using factor scores.
lin <- lm(df_bc.events ~ ., data.frame(df_bc$events,
                                 pc_scores$RC1,
                                 pc_scores$RC2,
                                 pc_scores$RC3,
                                 pc_scores$RC4,
                                 pc_scores$RC5,
                                 pc_scores$RC6,
                                 pc_scores$RC7,
                                 pc_scores$RC8,
                                 pc_scores$RC9))
summary(lin)

df_bc <- bind_cols(df_bc, pc_scores)

###############################
# Income-related numeric fields

# for_factor_analysis <- combined_df %>%
#   select(c('IncomeBucket1',
#            'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
#            'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
#            'IncomeBucket10')) %>%
#   select_if(is.numeric) %>%
#   drop_na()
# principal(for_factor_analysis, nfactors=5, rotate="none")
#
# principal(for_factor_analysis, nfactors=2)

###################
# Percentage fields

# for_factor_analysis <- combined_df %>%
#     select(c('PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
#              'PercAsian', 'PercLatino', 'PercInsured', 'Perc_HHsAbSixtyFive',
#              'Perc_HHsBelEighteen', 'UnempRate', 'HighschoolRate', 'BachelorsRate',
#              'irs_estimated_population_2015')) %>%
#     select_if(is.numeric) %>%
#     drop_na()
# principal(for_factor_analysis, nfactors=8, rotate="none")
#
# principal(for_factor_analysis, nfactors=4)

####################################################################
# Dummy variables for non-location covariates
####################################################################

# Month indicator variables
df_bc <- bind_cols(df_bc, as_tibble(dummy(df_bc$month))) %>% rename(January="month)))1",
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

# Month indicator variables
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

# Regression with month indicator variables.
lin <- lm(events ~ ., df_bc %>% select(events,
                                       RC1, RC2, RC3, RC4, RC5, RC6, RC7,
                                       RC8, RC9,
                                       January, February, March, April,
                                       May, June, July, August, September,
                                       October, November, December)
          )
summary(lin)

MAPE(df_bc$events + 1, lin$fitted.values)
MAPE(df_bc$events + 1, lin$fitted.values %>% sapply(function(x) max(x, 0)))

####################################################################
# Dummy variables for location covariates (e.g. states)
####################################################################

# Filtering down to only the desired covariates and the index (ZIP)
desired_covariates <- df_bc %>% select(ZIP, events,
                                    RC1, RC2, RC3, RC4, RC5, RC6, RC7,
                                    RC8, RC9,
                                    January, February, March, April,
                                    May, June, July, August, September,
                                    October, November, December)

# write_csv(desired_covariates, "df_bc_desiredcovariates.csv")

# Creating indicator variables for states
lin <- lm(events ~ ., bind_cols(desired_covariates,
                                as_tibble(dummy(df_bc$state))
)
)
summary(lin)

# Adding dummy variables for states increases R^2 (good) but increases MAPE (bad.
MAPE(df_bc$events + 1, lin$fitted.values)
MAPE(df_bc$events + 1, lin$fitted.values %>% sapply(function(x) max(x, 0)))

# We cannot create dummy variables for primary_city, county, or ZIP because
# the data is too large to process with the dummy() function.

desired_covariates <- df_bc %>% select(events,
                                       RC1, RC2, RC3, RC4, RC5, RC6, RC7,
                                       RC8, RC9,
                                       January, February, March, April,
                                       May, June, July, August, September,
                                       October, November, December, ZIP)

# This fails to run because of my memory limits.
lin <- lm(events ~ as.character(ZIP) + ., bind_cols(desired_covariates))
summary(lin)

MAPE(df_bc$events + 1, lin$fitted.values)
MAPE(df_bc$events + 1, lin$fitted.values %>% sapply(function(x) max(x, 0)))

####################################################################
# Step-wise regression
####################################################################

##############################
# Forward step-wise regression

intercept_only <- lm(events ~ 1, data=desired_covariates)
all <- lm(events ~ . - ZIP, data=desired_covariates)

forward <- step(intercept_only, direction='forward', scope=formula(all), trace=1)

#view results of forward stepwise regression
forward$anova

# Performance is not much better than using all the covariates in desired_covariates
MAPE(df_bc$events + 1, forward$fitted.values)
MAPE(df_bc$events + 1, forward$fitted.values %>% sapply(function(x) max(x, 0)))

###############################
# Backward step-wise regression

intercept_only <- lm(events ~ 1, data=desired_covariates)
all <- lm(events ~ . - ZIP, data=desired_covariates)

backward <- step(all, direction='backward', scope=formula(all), trace=1)

#view results of backward stepwise regression - in this case, the same as forward step-wise
backward$anova

# These match the forward step-wise because the backward step-wise produces the same model
MAPE(df_bc$events + 1, backward$fitted.values)
MAPE(df_bc$events + 1, backward$fitted.values %>% sapply(function(x) max(x, 0)))

#######################################
# Forward-Backward step-wise regression

intercept_only <- lm(events ~ 1, data=desired_covariates)
all <- lm(events ~ . - ZIP, data=desired_covariates)

both <- step(intercept_only, direction='both', scope=formula(all), trace=1)

#view final model - in this case, the same as forward step-wise
both$coefficients

# These match the previous step-wises because they all produce the same model
MAPE(df_bc$events + 1, both$fitted.values)
MAPE(df_bc$events + 1, both$fitted.values %>% sapply(function(x) max(x, 0)))

#######################################
# Results of step-wise regression

summary(both)

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
# Miscellaneous analysis
####################################################################

df_bc_events <- df_bc %>% group_by(ZIP) %>% summarise(total_events = sum(events))
df_ac_events <- df_ac %>% group_by(ZIP) %>% summarise(total_events = sum(events))

df_ac_events[df_bc_events$total_events < df_ac_events$total_events,]$total_events

####################################################################
# Pareto charts - super cool!
####################################################################

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
    labs(title="Pareto Chart: Percentage of Events by Percentile of Zip Codes, March 2020 onward",x="Percentile of Zip Codes, by events March 2020 onward", y = "Percentage of Sales")

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

####################################################################
# Poisson regression
####################################################################

# Poisson regressions are appropriate here because we are dealing
# with count data with large amounts of zeroes.
hist(df_bc$events)

# Poisson
pm <- glm(events ~ . - ZIP, family="poisson", data=desired_covariates)
summary(pm)

MAPE(df_bc$events + 1, pm$fitted.values)
MAPE(df_bc$events + 1, pm$fitted.values %>% sapply(function(x) max(x, 0)))

# Zero-inflated Poisson
zpm <- zeroinfl(events ~ . - ZIP - June, data = desired_covariates)
summary(zpm)

MAPE(df_bc$events + 1, zpm$fitted.values)
MAPE(df_bc$events + 1, zpm$fitted.values %>% sapply(function(x) max(x, 0)))
