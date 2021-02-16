library(tidyverse)

# Approaches

## Time series
## Linear regression
## Logistic regression
## Poisson regression / regression on some other distribution
## Cluster analysis (clustering zip codes?)
## Factor analysis (reducing number of coefficients)
## Customer lifetime value: continuous, non-contractual
### Although our data is discretized.
## Interaction variables
## Decision trees


orig_df <- read_csv("data_cleaned_for_class.csv")
df <- orig_df

###############
# Cleaning data

# Date
df$date <- df$date %>% substr(1, 7) %>% as.Date("%d%b%y")

# Standardizing for regression.  Uncomment the below when needed.
# modelformula <- events ~ var1 + var2, where we want to standardize var1 and var2
# standardized_df <- lapply(df[, all.vars(modelformula)], scale)

df

