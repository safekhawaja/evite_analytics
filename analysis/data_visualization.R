##############################
## MKTG 401 data visualization

library(tidyverse) # The basics
library(psych) # Factor and cluster analysis
library(dummies) # Indicator variables
library(TSPred) # MAPE
library(pscl) # Zero-inflated Poisson
library(gganimate)
library(gifski)
library(av)

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

top_df <- df[df$ZIP %in% df_bc_grouped[df_bc_grouped$cum >= 0.10,]$ZIP,]
bottom_df <- df[!(df$ZIP %in% df_bc_grouped[df_bc_grouped$cum >= 0.10,]$ZIP),]

top_df_bc <- top_df[top_df$after_covid == 0,] # Before Covid.
top_df_ac <- top_df[top_df$after_covid == 1,] # After Covid.

####################################################################
# Visualizing events by zip code
####################################################################

zipcodes <- read_delim("us-zip-code-latitude-and-longitude.csv", delim=";")
zipcodes$ZIP = as.numeric(zipcodes$Zip)

# Events Decile per Zipcode, before Covid
df_bc_grouped <- df_bc %>% group_by(ZIP) %>% summarise(events = sum(events))
df_bc_grouped <- df_bc_grouped[order(df_bc_grouped$events),] %>% mutate(cum = cumsum(events)/sum(events))
df_bc_grouped$cum_zips <- seq(0, 27428, 1) / 27428
df_bc_grouped <- left_join(df_bc_grouped, df_bc %>% group_by(ZIP, region) %>% count() %>% dplyr::select(ZIP, region), by="ZIP")
df_bc_grouped <- left_join(df_bc_grouped, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")
df_bc_grouped$decile <- dplyr::ntile(df_bc_grouped$cum, 10)
df_bc_grouped

g <- ggplot(data=df_bc_grouped) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Decile per Zipcode, before Covid") + scale_color_gradient(low = 'greenyellow', high = 'forestgreen')

# Events Decile per Zipcode, after Covid
df_ac_grouped <- df_ac %>% group_by(ZIP) %>% summarise(events = sum(events))
df_ac_grouped <- df_ac_grouped[order(df_ac_grouped$events),] %>% mutate(cum = cumsum(events)/sum(events))
df_ac_grouped$cum_zips <- seq(0, 27428, 1) / 27428
df_ac_grouped <- left_join(df_ac_grouped, df_ac %>% group_by(ZIP, region) %>% count() %>% dplyr::select(ZIP, region), by="ZIP")
df_ac_grouped <- left_join(df_ac_grouped, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")
df_ac_grouped$decile <- dplyr::ntile(df_ac_grouped$cum, 10)
df_ac_grouped

g <- ggplot(data=df_ac_grouped) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Decile per Zipcode, after Covid") + scale_color_gradient(low = 'greenyellow', high = 'forestgreen')

# Change in Events Decile per Zipcode
events_per_month_bc <- df_bc %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_bc = events)
events_per_month_ac <- df_ac %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_ac = events)

events_per_month_ac <- events_per_month_ac %>% left_join(events_per_month_bc, by=c("ZIP", "month"))
events_per_month_ac$events_change <- events_per_month_ac$events_ac - events_per_month_ac$events_bc
events_per_month_ac <- left_join(events_per_month_ac, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")

events_pre2020 <- df_bc[df_bc$date < lubridate::ymd("2020-01-01"),] %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_before2020 = events)
events_post2020 <- df_bc[df_bc$date >= lubridate::ymd("2020-01-01"),] %>% group_by(ZIP, month) %>% summarise(events = mean(events)) %>% rename(events_after2020 = events)
events_post2020 <- left_join(events_post2020, events_pre2020, by=c("ZIP", "month"))
events_post2020$events_change <- events_post2020$events_after2020 - events_post2020$events_before2020
events_post2020 <- left_join(events_post2020, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")

events_january_bc <- events_post2020[events_post2020$month==1,]
events_february_bc <- events_post2020[events_post2020$month==2,]

events_january_bc$decile <- dplyr::ntile(events_january_bc$events_change, 11)
events_february_bc$decile <- dplyr::ntile(events_february_bc$events_change, 11)

events_january_bc$decile <- events_january_bc$decile - min(events_january_bc[events_january_bc$events_change>=0,]$decile)
events_february_bc$decile <- events_february_bc$decile - min(events_february_bc[events_february_bc$events_change>=0,]$decile)

events_march_ac <- events_per_month_ac[events_per_month_ac$month==3,]
events_april_ac <- events_per_month_ac[events_per_month_ac$month==4,]
events_may_ac <- events_per_month_ac[events_per_month_ac$month==5,]
events_june_ac <- events_per_month_ac[events_per_month_ac$month==6,]
events_july_ac <- events_per_month_ac[events_per_month_ac$month==7,]
events_august_ac <- events_per_month_ac[events_per_month_ac$month==8,]
events_march_ac$decile <- dplyr::ntile(events_march_ac$events_change, 11)
events_april_ac$decile <- dplyr::ntile(events_april_ac$events_change, 11)
events_may_ac$decile <- dplyr::ntile(events_may_ac$events_change, 11)
events_june_ac$decile <- dplyr::ntile(events_june_ac$events_change, 11)
events_july_ac$decile <- dplyr::ntile(events_july_ac$events_change, 11)
events_august_ac$decile <- dplyr::ntile(events_august_ac$events_change, 11)

events_march_ac$decile <- events_march_ac$decile - min(events_march_ac[events_march_ac$events_change>=0,]$decile)
events_april_ac$decile <- events_april_ac$decile - min(events_april_ac[events_april_ac$events_change>=0,]$decile)
events_may_ac$decile <- events_may_ac$decile - min(events_may_ac[events_may_ac$events_change>=0,]$decile)
events_june_ac$decile <- events_june_ac$decile - min(events_june_ac[events_june_ac$events_change>=0,]$decile)
events_july_ac$decile <- events_july_ac$decile - min(events_july_ac[events_july_ac$events_change>=0,]$decile)
events_august_ac$decile <- events_august_ac$decile - min(events_august_ac[events_august_ac$events_change>=0,]$decile)

g <- ggplot(data=events_january_bc) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Januarys, January 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_february_bc) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Februarys, February 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_march_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Marchs, March 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_april_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Aprils, April 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_may_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Mays, May 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_june_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Junes, June 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_july_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Julys, July 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_august_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Augusts, August 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

events_ac <- events_per_month_ac %>% group_by(ZIP) %>% summarize(events_change=sum(events_change))
events_ac <- left_join(events_ac, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")
events_ac$decile <- dplyr::ntile(events_ac$events_change, 11)
events_ac$decile <- events_ac$decile - min(events_ac[events_ac$events_change>=0,]$decile)

g <- ggplot(data=events_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Events Relative to Previous Mars-Augs, Mar-Aug 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

for_animation <- bind_rows(events_january_bc,
                           events_february_bc,
                           events_march_ac,
                           events_april_ac,
                           events_may_ac,
                           events_june_ac,
                           events_july_ac,
                           events_august_ac)

p <- ggplot(for_animation) +
    geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5) +
    theme_bw() +
    scale_x_continuous(limits = c(-125,-66), breaks = NULL) +
    scale_y_continuous(limits = c(20,55), breaks = NULL) +
    labs(x=NULL, y=NULL) +
    ggtitle("Events Relative to Previous Months, 2020") +
    scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

p + transition_time(month) +
    labs(title = "Events Relative to Previous Months, 2020\n
                  Month: {month.name[frame_time]}")
