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
RC1 = pc3$scores[,1]
RC2 = pc3$scores[,2]
RC3 = pc3$scores[,3]

plot(RC1,RC2,main="RC1 vs RC2")
plot(RC1,RC3,main="RC1 vs RC3")
plot(RC2,RC3,main="RC2 vs RC3")

# Improved regression.
lin <- lm(car.Ideal_Price ~ ., data.frame(car$Ideal_Price, RC1, RC2, RC3))
summary(lin)

##################
## MKTG 401 data
##################
combined_df = as_tibble(read.csv("combined_df.csv"))
combined_df

# First, step-wise to choose predictors
# Then, narrow down further with factor analysis to remove collinearity
# Then, validate that it makes sense from a narrative perspective

# Second, factor analysis to narrow down collinearity
# Then, step-wise to choose predictors
# Then, validate that it makes sense from a narrative perspective

# Excluding COVID stuff.
for_factor_analysis <- combined_df %>%
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
  select_if(is.numeric) %>%
  drop_na()
principal(for_factor_analysis, nfactors=5, rotate="none")


for_factor_analysis <- combined_df %>%
  select(c('IncomeBucket1',
           'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
           'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
           'IncomeBucket10')) %>%
  select_if(is.numeric) %>%
  drop_na()
principal(for_factor_analysis, nfactors=5, rotate="none")

for_factor_analysis <- combined_df %>%
  select(c('PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
           'PercAsian', 'PercLatino', 'PercInsured', 'Perc_HHsAbSixtyFive',
           'Perc_HHsBelEighteen', 'UnempRate', 'HighschoolRate', 'BachelorsRate',
           'irs_estimated_population_2015')) %>%
  select_if(is.numeric) %>%
  drop_na()
principal(for_factor_analysis, nfactors=5, rotate="none")

