import pandas as pd
from datetime import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt

# Rolling averages

pre_evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
pre_evite["date"] = pre_evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

pre_evite_7 = pre_evite.assign(rm7=pre_evite.events.rolling(window=7).mean())
pre_evite_30 = pre_evite_7.assign(rm30=pre_evite.events.rolling(window=30).mean())
pre_evite_365 = pre_evite_30.assign(rm365=pre_evite.events.rolling(window=365).mean())

print(pre_evite_365.rm7)
print(pre_evite_365.rm30)
print(pre_evite_365.rm365)

# Activity for days of the week

mondays = []
tuesdays = []
wednesdays = []
thursdays = []
fridays = []
saturdays = []
sundays = []

for row in pre_evite_365:
    if pre_evite_365.loc[row, "date"].day_name() == "Monday":
        mondays.append(pre_evite_365.loc[row, "events"])
    elif pre_evite_365.loc[row, "date"].day_name() == "Tuesday":
        tuesdays.append(pre_evite_365.loc[row, "events"])
    elif pre_evite_365.loc[row, "date"].day_name() == "Wednesday":
        wednesdays.append(pre_evite_365.loc[row, "events"])
    elif pre_evite_365.loc[row, "date"].day_name() == "Thursday":
        thursdays.append(pre_evite_365.loc[row, "events"])
    elif pre_evite_365.loc[row, "date"].day_name() == "Friday":
        fridays.append(pre_evite_365.loc[row, "events"])
    elif pre_evite_365.loc[row, "date"].day_name() == "Saturday":
        saturdays.append(pre_evite_365.loc[row, "events"])
    else:
        sundays.append(pre_evite_365.loc[row, "events"])

weekdays = [mondays.mean(), tuesdays.mean(), wednesdays.mean(), thursdays.mean(), fridays.mean(), saturdays.mean(), sundays.mean()]

print(weekdays)
# mpl.rcParams['agg.path.chunksize'] = 10000
# plt.plot(pre_evite.date, pre_evite_365.rm7, color='#444444', linestyle='-', label='7-Day Moving Average')
# plt.plot(pre_evite.date, pre_evite_365.rm30, color='#444444', linestyle='--', label='30-Day Moving Average')
# plt.plot(pre_evite.date, pre_evite_365.rm365, color='#444444', linestyle=':', label='365-Day Moving Average')
# plt.legend()
# plt.show()
