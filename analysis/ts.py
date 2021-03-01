import statistics
import pandas as pd
from datetime import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt

# Rolling averages

head = 1000

pre_evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
pre_evite["date"] = pre_evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

pre_evite = pre_evite.head(head)

pre_evite_7 = pre_evite.assign(rm7=pre_evite.events.rolling(window=7).mean())
pre_evite_30 = pre_evite_7.assign(rm30=pre_evite.events.rolling(window=30).mean())
pre_evite_365 = pre_evite_30.assign(rm365=pre_evite.events.rolling(window=365).mean())
pre_evite_dow = pre_evite_365.assign(dayofweek=pre_evite_365.date.dt.day_name())

mpl.rcParams['agg.path.chunksize'] = 10000
plt.plot(pre_evite.date, pre_evite_dow.rm7, color='#444444', linestyle='-', label='7-Day Moving Average')
plt.plot(pre_evite.date, pre_evite_dow.rm30, color='#444444', linestyle='--', label='30-Day Moving Average')
plt.plot(pre_evite.date, pre_evite_dow.rm365, color='#444444', linestyle=':', label='365-Day Moving Average')
plt.legend()
plt.show()
