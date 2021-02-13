##################
## MKTG 401 data

library(tidyverse)
library(psych)
library(dummies)
library(TSPred)

####################################################################
# Loading and cleaning data
####################################################################

# Original memory limit was 7919
# I just set it to 56000 by running memory.limit(56000)
# To restore it to the original, run memory.limit(7919)

combined_df = as_tibble(read.csv("combined_df.csv"))

df <- combined_df # Before and after Covid.
df$date <- substr(combined_df$date, 1, 7) %>% lubridate::dmy()
df$month <- lubridate::month(df$date)

df_bc <- df[df$after_covid == 0,] # Before Covid.

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
# RC9: zip code area (<=-0.75: ZipArea)

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

# Filtering down to only the desired covariates
desired_covariates <- df_bc %>% select(events,
                                    RC1, RC2, RC3, RC4, RC5, RC6, RC7,
                                    RC8, RC9,
                                    January, February, March, April,
                                    May, June, July, August, September,
                                    October, November, December)

# Creating indicator variables for states
lin <- lm(events ~ ., bind_cols(desired_covariates,
                                as_tibble(dummy(df_bc$state))
)
)
summary(lin)

# Adding dummy variables for states increases R^2 but decreases MAPE.
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
# Code from MKTG 212

library(tidyverse)
library(psych)

car = read.csv("car_data.csv")
combined_df = as_tibble(read.csv("combined_df.csv"))
# snapshot of the data:
head(car)

#the first time you run this, you may need to install the psych package
#install.packages('psych')

library(psych)

# We want to determine how many factors apply to the dataset for Q1-Q17

principal(car [,4:20],nfactors=17,rotate = "none") # we assume that there n factors for n output
# > observe that there are 14 elements in the output that are less than 1.
# > this implies that they are not significant
# > excluding these values, we would only need 3

# therefore,
principal(car [,4:20],nfactors=3,rotate = "none")
# > observe that all SS loading entries for PC1 -> PC3 are >= 1

# We now assert that there are 3 factors in the dataset.
# This implies that:
# Qx = RC1 * PC1 + RC2 * PC2 + RC3 * PC3
# Qy = RC1 * PC1 + RC2 * PC2 + RC3 * PC3
# Qz = RC1 * PC1 + RC2 * PC2 + RC3 * PC3
# The list of dependent variables are Q1 -> Q17
pc3=principal(car [,4:20],nfactors=3)
pc3

pc3$scores

# We take the summary of the linear model
# for each Qx output versus PC1, RC1, PC2, RC2, PC3 and RC3
# and we observe that all p-values are <= 0.05
# Therefore we declare that the model rejects the null
# hypothesis and that there is a correlation.
summary(lm(car$Q1 ~ pc3$scores))
summary(lm(car$Q2 ~ pc3$scores))
summary(lm(car$Q3 ~ pc3$scores))
summary(lm(car$Q4 ~ pc3$scores))
summary(lm(car$Q5 ~ pc3$scores))
summary(lm(car$Q6 ~ pc3$scores))
summary(lm(car$Q7 ~ pc3$scores))
summary(lm(car$Q8 ~ pc3$scores))
summary(lm(car$Q9 ~ pc3$scores))
summary(lm(car$Q10 ~ pc3$scores))
summary(lm(car$Q11 ~ pc3$scores))
summary(lm(car$Q12 ~ pc3$scores))
summary(lm(car$Q13 ~ pc3$scores))
summary(lm(car$Q14 ~ pc3$scores))
summary(lm(car$Q15 ~ pc3$scores))
summary(lm(car$Q16 ~ pc3$scores))
summary(lm(car$Q17 ~ pc3$scores))

pc3
pc3$scores


car = read.csv("car_data.csv")
library(psych)

principal(car [,4:20],nfactors=17,rotate = "none")
principal(car [,4:20],nfactors=3,rotate = "none")

pc3=principal(car [,4:20],nfactors=3)
RC1 = pc$scores[,1]
RC2 = pc3$scores[,2]
RC3 = pc3$scores[,3]

plot(RC1,RC2,main="RC1 vs RC2")
plot(RC1,RC3,main="RC1 vs RC3")
plot(RC2,RC3,main="RC2 vs RC3")

# Improved regression.
lin <- lm(car.Ideal_Price ~ ., data.frame(car$Ideal_Price, RC1, RC2, RC3))
summary(lin)
