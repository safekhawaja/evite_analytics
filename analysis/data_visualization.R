##############################
## MKTG 401 data visualization

library(tidyverse) # The basics
library(psych) # Factor and cluster analysis
library(dummies) # Indicator variables
library(TSPred) # MAPE
library(pscl) # Zero-inflated Poisson
library(gganimate)
library(gifski)
library(scales)

####################################################################
# Loading and cleaning data
####################################################################

combined_df <- read_csv("combined_df.csv")

df <- combined_df # Before and after Covid.
df$date <- substr(combined_df$date, 1, 7) %>% lubridate::dmy()
df$month <- lubridate::month(df$date)
df$year <- as.character(lubridate::year(df$date))
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
    labs(title="Pareto Chart: 12.5% of zips contribute 75% of events, pre-Covid",x="Percentile of Zip Codes", y = "Percentage of Total Events")

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
# Visualizing events over time
####################################################################

df_bc %>%
    group_by(month, year) %>%
    summarise(events = sum(events)) %>%
    ggplot(aes(x=month, y=events, group=year, color=year)) +
    geom_line(size=1) +
    theme_minimal() +
    scale_x_discrete(name ="Month",
                     limits=as.character(c(1:12))) +
    ylab("Events") +
    ggtitle("Events per Month before Covid") +
    scale_color_brewer(palette="Paired")

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
g1 <- g + ggtitle("Events Relative to Previous Januarys, January 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_february_bc) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g2 <- g + ggtitle("Events Relative to Previous Februarys, February 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_march_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g3 <- g + ggtitle("Events Relative to Previous Marchs, March 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_april_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g4 <- g + ggtitle("Events Relative to Previous Aprils, April 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_may_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g5 <- g + ggtitle("Events Relative to Previous Mays, May 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_june_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g6 <- g + ggtitle("Events Relative to Previous Junes, June 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_july_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g7 <- g + ggtitle("Events Relative to Previous Julys, July 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

g <- ggplot(data=events_august_ac) + geom_point(aes(x=Longitude, y=Latitude, colour=decile), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g8 <- g + ggtitle("Events Relative to Previous Augusts, August 2020") + scale_color_gradient2(low = 'red', mid = 'white', high = 'blue')

library(gridExtra)
grid.arrange(g1, g2,
             g3, g4,
             g5, g6,
             g7, g8,
             nrow = 3)


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

####################################################################
# Visualizing decrease in events
####################################################################

distr_events <- events_per_month_ac %>% group_by(events_change) %>% count()
data.frame(distr_events)

hist(events_per_month_ac$events_change)
hist(events_per_month_ac$events_change[events_per_month_ac$events_change > -200])
hist(events_per_month_ac$events_change[events_per_month_ac$events_change > -50])

# After Covid.
n <- events_per_month_ac %>% group_by(ZIP) %>% summarise(events_change = sum(events_change))
n <- n[order(n$events_change, decreasing=TRUE),] %>% mutate(cum = cumsum(events_change)/sum(events_change))
n$cum_zips <- seq(0, 27428, 1) / 27428
n

ggplot(data=n, aes(x=cum_zips, y=cum)) +
    geom_line() +
    labs(title="Pareto Chart: 12.5% of zips contribute 82% of the decrease in events",x="Percentile of Zip Codes", y = "Percentage of Decrease in Events")

# Responsible for 80% of losses.
top_losers <- n[n$cum_zips >= 0.9375,]
top_losers$events_change %>% summary()

# Responsible for ~15% of losses.
medium_losers <- n[n$cum_zips < 0.9375 & n$cum_zips >= 0.75,]
medium_losers$events_change %>% summary()

# Responsible for ~5% of losses.
small_losers <- n[n$cum_zips < 0.75,]
small_losers$events_change %>% summary()

top_losers <- left_join(top_losers, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")
small_losers <- left_join(small_losers, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")
medium_losers <- left_join(medium_losers, zipcodes %>% dplyr::select(ZIP, Latitude, Longitude), by="ZIP")

top_losers$category = "80% of decrease"
medium_losers$category = "15% of decrease"
small_losers$category = "5% of decrease"

g <- ggplot(data=bind_rows(top_losers, medium_losers, small_losers)) + geom_point(aes(x=Longitude, y=Latitude, colour=category), size=0.5)
g <- g + theme_bw() + scale_x_continuous(limits = c(-125,-66), breaks = NULL)
g <- g + scale_y_continuous(limits = c(20,55), breaks = NULL)
g <- g + labs(x=NULL, y=NULL)
g + ggtitle("Geographic distribution of decrease in events after Covid") + scale_color_manual(values = c("5% of decrease" = "#127c0e", "15% of decrease" = "#0e2df4", "80% of decrease" = "#ef2715"))

####################################################################
# Comparing tranches of zip codes
####################################################################

# 50% of the top 12.5% are top losers; 99% are a top or medium loser
mean(top_twelve_bc$ZIP %in% top_losers$ZIP)

# 90% of the top 6.25% are top losers
mean(top_six_bc$ZIP %in% top_losers$ZIP)

top_six_bc[!(top_six_bc$ZIP %in% top_losers$ZIP),]

bind_rows(top_losers, medium_losers, small_losers) %>%
    left_join(df, by="ZIP") %>%
    select('ZIP', 'Pop', 'ZipArea', 'Density', 'SexRatio', 'MedianAge',
           'PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
           'PercAsian', 'PercLatino', 'HousingUnits', 'IncomeBucket1',
           'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
           'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
           'IncomeBucket10',
           'MedianHHIncome', 'MeanHHIncome', 'PercInsured', 'TotalHHs',
           'FamHHs', 'Perc_HHsAbSixtyFive', 'Perc_HHsBelEighteen', 'AvgHHSize',
           'AvgFamSize', 'AvgBirthRate', 'HHwGrandpar', 'HHswComp', 'HHwInt',
           'UnempRate', 'HighschoolRate', 'BachelorsRate',
           'irs_estimated_population_2015',
           category, COVID_CASES_RUNNING, COVID_DEATHS_NEW, COVID_CASES_NEW,
           COVID_DEATHS_RUNNING) %>%
    group_by(category) %>%
    summarise(
        'Mean_Pop' = mean(Pop),
        'Mean_ZipArea' = mean(ZipArea),
        'Mean_Density' = mean(Density),
        'Mean_SexRatio' = mean(SexRatio),
        'Mean_MedianAge' = mean(MedianAge),
        'Mean_PercPopUnder18' = mean(PercPopUnder18),
        'Mean_PercPopOver65' = mean(PercPopOver65),
        'Mean_PercWhite' = mean(PercWhite),
        'Mean_PercBlack' = mean(PercBlack),
        'Mean_PercAsian' = mean(PercAsian),
        'Mean_PercLatino' = mean(PercLatino),
        'Mean_HousingUnits' = mean(HousingUnits),
        'Mean_IncomeBucket1' = mean(IncomeBucket1),
        'Mean_IncomeBucket2' = mean(IncomeBucket2),
        'Mean_IncomeBucket3' = mean(IncomeBucket3),
        'Mean_IncomeBucket4' = mean(IncomeBucket4),
        'Mean_IncomeBucket5' = mean(IncomeBucket5),
        'Mean_IncomeBucket6' = mean(IncomeBucket6),
        'Mean_IncomeBucket7' = mean(IncomeBucket7),
        'Mean_IncomeBucket8' = mean(IncomeBucket8),
        'Mean_IncomeBucket9' = mean(IncomeBucket9),
        'Mean_IncomeBucket10' = mean(IncomeBucket10),
        'Mean_MedianHHIncome' = mean(MedianHHIncome),
        'Mean_PercInsured' = mean(PercInsured),
        'Mean_TotalHHs' = mean(TotalHHs),
        'Mean_FamHHs' = mean(FamHHs),
        'Mean_Perc_HHsAbSixtyFive' = mean(Perc_HHsAbSixtyFive),
        'Mean_Perc_HHsBelEighteen' = mean(Perc_HHsBelEighteen),
        'Mean_AvgHHSize' = mean(AvgHHSize),
        'Mean_AvgFamSize' = mean(AvgFamSize),
        'Mean_AvgBirthRate' = mean(AvgBirthRate),
        'Mean_HHwGrandpar' = mean(HHwGrandpar),
        'Mean_HHswComp' = mean(HHswComp),
        'Mean_HHwInt' = mean(HHwInt),
        'Mean_UnempRate' = mean(UnempRate),
        'Mean_HighschoolRate' = mean(HighschoolRate),
        'Mean_BachelorsRate' = mean(BachelorsRate),
        'Mean_irs_estimated_population_2015' = mean(irs_estimated_population_2015),
        'Mean_COVID_CASES_RUNNING' = mean(COVID_CASES_RUNNING),
        'Mean_COVID_CASES_NEW' = mean(COVID_CASES_NEW),
        'Mean_COVID_DEATHS_RUNNING' = mean(COVID_DEATHS_RUNNING),
        'Mean_COVID_DEATHS_NEW' = mean(COVID_DEATHS_NEW)
    ) %>% write_csv("differences_between_losers_original.csv")

top_twelve_bc$top_losers <- NA

top_twelve_bc[top_twelve_bc$ZIP %in% top_losers$ZIP,]$top_losers <- "In the top losers"
top_twelve_bc[!(top_twelve_bc$ZIP %in% top_losers$ZIP),]$top_losers <- "Not in the top losers"

top_twelve_bc %>%
    left_join(df, by="ZIP") %>%
    select('ZIP', 'Pop', 'ZipArea', 'Density', 'SexRatio', 'MedianAge',
           'PercPopUnder18', 'PercPopOver65', 'PercWhite', 'PercBlack',
           'PercAsian', 'PercLatino', 'HousingUnits', 'IncomeBucket1',
           'IncomeBucket2', 'IncomeBucket3', 'IncomeBucket4', 'IncomeBucket5',
           'IncomeBucket6', 'IncomeBucket7', 'IncomeBucket8', 'IncomeBucket9',
           'IncomeBucket10',
           'MedianHHIncome', 'MeanHHIncome', 'PercInsured', 'TotalHHs',
           'FamHHs', 'Perc_HHsAbSixtyFive', 'Perc_HHsBelEighteen', 'AvgHHSize',
           'AvgFamSize', 'AvgBirthRate', 'HHwGrandpar', 'HHswComp', 'HHwInt',
           'UnempRate', 'HighschoolRate', 'BachelorsRate',
           'irs_estimated_population_2015',
           'top_losers', COVID_CASES_RUNNING, COVID_DEATHS_NEW, COVID_CASES_NEW,
           COVID_DEATHS_RUNNING) %>%
    group_by(top_losers) %>%
    summarise(
        'Mean_Pop' = mean(Pop),
        'Mean_ZipArea' = mean(ZipArea),
        'Mean_Density' = mean(Density),
        'Mean_SexRatio' = mean(SexRatio),
        'Mean_MedianAge' = mean(MedianAge),
        'Mean_PercPopUnder18' = mean(PercPopUnder18),
        'Mean_PercPopOver65' = mean(PercPopOver65),
        'Mean_PercWhite' = mean(PercWhite),
        'Mean_PercBlack' = mean(PercBlack),
        'Mean_PercAsian' = mean(PercAsian),
        'Mean_PercLatino' = mean(PercLatino),
        'Mean_HousingUnits' = mean(HousingUnits),
        'Mean_IncomeBucket1' = mean(IncomeBucket1),
        'Mean_IncomeBucket2' = mean(IncomeBucket2),
        'Mean_IncomeBucket3' = mean(IncomeBucket3),
        'Mean_IncomeBucket4' = mean(IncomeBucket4),
        'Mean_IncomeBucket5' = mean(IncomeBucket5),
        'Mean_IncomeBucket6' = mean(IncomeBucket6),
        'Mean_IncomeBucket7' = mean(IncomeBucket7),
        'Mean_IncomeBucket8' = mean(IncomeBucket8),
        'Mean_IncomeBucket9' = mean(IncomeBucket9),
        'Mean_IncomeBucket10' = mean(IncomeBucket10),
        'Mean_MedianHHIncome' = mean(MedianHHIncome),
        'Mean_PercInsured' = mean(PercInsured),
        'Mean_TotalHHs' = mean(TotalHHs),
        'Mean_FamHHs' = mean(FamHHs),
        'Mean_Perc_HHsAbSixtyFive' = mean(Perc_HHsAbSixtyFive),
        'Mean_Perc_HHsBelEighteen' = mean(Perc_HHsBelEighteen),
        'Mean_AvgHHSize' = mean(AvgHHSize),
        'Mean_AvgFamSize' = mean(AvgFamSize),
        'Mean_AvgBirthRate' = mean(AvgBirthRate),
        'Mean_HHwGrandpar' = mean(HHwGrandpar),
        'Mean_HHswComp' = mean(HHswComp),
        'Mean_HHwInt' = mean(HHwInt),
        'Mean_UnempRate' = mean(UnempRate),
        'Mean_HighschoolRate' = mean(HighschoolRate),
        'Mean_BachelorsRate' = mean(BachelorsRate),
        'Mean_irs_estimated_population_2015' = mean(irs_estimated_population_2015),
        'Mean_COVID_CASES_RUNNING' = mean(COVID_CASES_RUNNING),
        'Mean_COVID_CASES_NEW' = mean(COVID_CASES_NEW),
        'Mean_COVID_DEATHS_RUNNING' = mean(COVID_DEATHS_RUNNING),
        'Mean_COVID_DEATHS_NEW' = mean(COVID_DEATHS_NEW)
    ) %>% write_csv("differences_between_top_twelve_original.csv")

top_losers$events_change_for_regr <- top_losers$events_change * -1 - min(top_losers$events_change * -1)
hist(top_losers$events_change_for_regr)

pm <- glm(events_change_for_regr ~ . - ZIP, family="poisson", data=top_losers %>%
              left_join(df, by="ZIP") %>%
              select(
                  ZIP, events_change_for_regr, RC1, RC2, RC3, RC4, RC5, RC6, RC7, RC8, RC9,
                  February, March, April, May, June, July, August, September,
                  October, November, December, region
              ))
summary(pm)

library(reshape2)
df <- data.frame(fitted = pm$fitted.values,
                 actual = top_losers$events_change_for_regr)
ggplot(melt(df), aes(value, fill = variable)) + geom_histogram(position = "dodge")

####################################################################
# Visualizing events by region
####################################################################

ggplot(data=df_bc %>%
           group_by(region) %>%
           summarise(events = sum(events)),
       aes(x=region, y=events)) +
    scale_y_continuous(limits = c(0,3000000)) +
    geom_bar(stat="identity") + ggtitle("Events by region, before Covid")

ggplot(data=df_ac %>%
           group_by(region) %>%
           summarise(events = sum(events)),
       aes(x=region, y=events)) +
    scale_y_continuous(limits = c(0,3000000)) +
    geom_bar(stat="identity") + ggtitle("Events by region, after Covid")

df_bc %>% group_by(region) %>% summarise(events = sum(events))
df_ac %>% group_by(region) %>% summarise(events = sum(events))

####################################################################
# Visualizing virtual and physical events over time
####################################################################

ggplot(data=df %>%
           dplyr::group_by(date) %>%
           dplyr::summarise(virtual = sum(virtual),
                            physical = sum(physical)
           ), aes(x=date)) +
    geom_line(aes(y = virtual, colour = "red")) +
    geom_line(aes(y = physical, colour = "blue")) +
    geom_vline(xintercept=as.Date("2020-03-01")) +
    scale_color_manual(labels = c("Physical", "Virtual"),
                       values = c("red", "blue")) +
    labs(y = "Events", x = "Date") +
    ggtitle("Physical and Virtual Events over Time")

####################################################################
# Visualizing types of events over time
####################################################################

ggplot(data=df %>%
           dplyr::group_by(date) %>%
           dplyr::summarise(Birthday_for_Kids = sum(Birthday_for_Kids),
                            Graduation = sum(Graduation),
                            Religious = sum(Religious),
                            Birthday_for_Him = sum(Birthday_for_Him),
                            Birthday_for_Her = sum(Birthday_for_Her),
                            Pool_Party = sum(Pool_Party),
                            Birthday_for_Teens = sum(Birthday_for_Teens),
                            Dinner_Party = sum(Dinner_Party),
                            Birthday_Milestones = sum(Birthday_Milestones)) %>%
           gather(key=`Event Type`,
                  value=events,
                  Birthday_for_Kids:Birthday_Milestones,
                  factor_key=FALSE),
       aes(x=date, y=events, group=`Event Type`, color=`Event Type`)) +
    geom_line() +
    geom_vline(xintercept=as.Date("2020-03-01")) +
    labs(y = "Events", x = "Date") +
    ggtitle("Events Types over Time") +
    scale_y_continuous(labels = comma)

ggplot(data=df_bc %>%
           dplyr::group_by(month) %>%
           dplyr::summarise(Birthday_for_Kids = sum(Birthday_for_Kids),
                            Graduation = sum(Graduation),
                            Religious = sum(Religious),
                            Birthday_for_Him = sum(Birthday_for_Him),
                            Birthday_for_Her = sum(Birthday_for_Her),
                            Pool_Party = sum(Pool_Party),
                            Birthday_for_Teens = sum(Birthday_for_Teens),
                            Dinner_Party = sum(Dinner_Party),
                            Birthday_Milestones = sum(Birthday_Milestones)) %>%
           gather(key=`Event Type`,
                  value=events,
                  Birthday_for_Kids:Birthday_Milestones,
                  factor_key=FALSE),
       aes(x=month, y=events, group=`Event Type`, color=`Event Type`)) +
    geom_line() +
    labs(y = "Events", x = "Date") +
    ggtitle("Events by Type by Month, before Covid") +
    scale_y_continuous(labels = comma) +
    scale_x_discrete(name ="Month",
                     limits=as.character(c(1:12)))

####################################################################
# TODO
####################################################################

# Event types over time
# Proportion of event types per month
