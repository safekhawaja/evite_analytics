import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt

evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
evite["date"] = evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

# for i in range(2, 10):
#     evite['MA{}'.format(i)] = evite.rolling(window=i).mean()

# evite[[f for f in list(evite) if "MA" in f]].mean(axis=1)

evite.rollingmean5 = evite.events.rolling(window=5).mean()

print(evite.rollingmean5)

plt.scatter(evite.date, evite.events, color='#444444', linestyle='--', label='Total Events')
plt.plot(evite.date, evite.rollingmean5, color='#444444', linestyle='-', label='5-Day Moving Average')
plt.show()

