import statistics
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt

# Rolling averages

head = 1000

pre_evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
pre_evite["date"] = pre_evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

pre_evite = pre_evite.head(head)
pre_evite_dow = pre_evite.assign(dayofweek=pre_evite.date.dt.day_name())

# Event activity for days of the week

mondays = []
tuesdays = []
wednesdays = []
thursdays = []
fridays = []
saturdays = []
sundays = []

# Monday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Monday"]
# weekly.append(Monday_df.events.mean())
#
# Tuesday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Tuesday"]
# weekly.append(uesday_df.events.mean())
#
# Wednesay_df = pre_evite_365[pre_evite_365['date'].day_name() == "Wednesday"]
# weekly.append(Wednesay_df.events.mean())
#
# Thursday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Thursday"]
# weekly.append(Thursday_df.events.mean())
#
# Friday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Friday"]
# weekly.append(Friday_df.events.mean())
#
# Saturday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Saturday"]
# weekly.append(Saturday_df.events.mean())
#
# Sunday_df = pre_evite_365[pre_evite_365['date'].day_name() == "Sunday"]
# weekly.append(Sunday_df.events.mean())

index = 10

while index < 1001:
    if pre_evite_dow.loc[index, "dayofweek"] == "Monday":
        mondays.append(pre_evite_dow.loc[index, "events"])
    elif pre_evite_dow.loc[index, "dayofweek"] == "Tuesday":
        tuesdays.append(pre_evite_dow.loc[index, "events"])
    elif pre_evite_dow.loc[index, "dayofweek"] == "Wednesday":
        wednesdays.append(pre_evite_dow.loc[index, "events"])
    elif pre_evite_dow.loc[index, "dayofweek"] == "Thursday":
        thursdays.append(pre_evite_dow.loc[index, "events"])
    elif pre_evite_dow.loc[index, "dayofweek"] == "Friday":
        fridays.append(pre_evite_dow.loc[index, "events"])
    elif pre_evite_dow.loc[index, "dayofweek"] == "Saturday":
        saturdays.append(pre_evite_dow.loc[index, "events"])
    else:
        sundays.append(pre_evite_dow.loc[index, "events"])
    index = index + 1

weeklymean = [statistics.mean(mondays), statistics.mean(tuesdays), statistics.mean(wednesdays), statistics.mean(thursdays), statistics.mean(fridays), statistics.mean(saturdays), statistics.mean(sundays)]
weeklymedian = [statistics.median(mondays), statistics.median(tuesdays), statistics.median(wednesdays), statistics.median(thursdays), statistics.median(fridays), statistics.median(saturdays), statistics.median(sundays)]

plt.plot(range(1, 7, 1), weeklymean, color='#444444', linestyle='-', label='Weekly Mean')
plt.plot(range(1, 7, 1), weeklymedian, color='#444444', linestyle='--', label='Weekly Median')
