import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt

pre_evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
pre_evite["date"] = evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

pre_evite.rollingmean2 = pre_evite.events.rolling(window=2).mean()
pre_evite.rollingmean3 = pre_evite.events.rolling(window=3).mean()
pre_evite.rollingmean4 = pre_evite.events.rolling(window=4).mean()
pre_evite.rollingmean5 = pre_evite.events.rolling(window=5).mean()
pre_evite.rollingmean6 = pre_evite.events.rolling(window=6).mean()
pre_evite.rollingmean7 = pre_evite.events.rolling(window=7).mean()
pre_evite.rollingmean30 = pre_evite.events.rolling(window=30).mean()
pre_evite.rollingmean365 = pre_evite.events.rolling(window=365).mean()

print(pre_evite.rollingmean5)

plt.scatter(pre_evite.date, pre_evite.events, color='#444444', linestyle='--', label='Total Events')
plt.plot(pre_evite.date, pre_evite.rollingmean5, color='#444444', linestyle='-', label='5-Day Moving Average')
plt.show()

