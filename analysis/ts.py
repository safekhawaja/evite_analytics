import pandas as pd
from datetime import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt

# Rolling Averages

df_evite = pd.read_csv("/Users/saif/Downloads/data_cleaned_for_class.csv", index_col=0, parse_dates=True)
df_evite["date"] = df_evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)
df_evite.sort_values(by='date')
df_evite = df_evite.groupby('date')['events'].sum().reset_index()

df_evite_65 = df_evite.assign(rs6=df_evite.events.rolling(window=6).std())
df_evite_6 = df_evite_65.assign(rm6=df_evite.events.rolling(window=6).mean())
df_evite_35 = df_evite_6.assign(rm3=df_evite.events.rolling(window=3).mean())
df_evite_3 = df_evite_35.assign(rs3=df_evite.events.rolling(window=3).std())
df_evite_2 = df_evite_3.assign(rm2=df_evite.events.rolling(window=2).mean())
df_evite_f = df_evite_2.assign(rs2=df_evite.events.rolling(window=2).std())

df_evite_f.to_csv('rollingmeans.csv', index=True)

mpl.rcParams['agg.path.chunksize'] = 10000
plt.plot(df_evite.date, df_evite_f.events, color='#000000', linestyle='-', label='Total Events')
plt.plot(df_evite.date, df_evite_f.rm6, color='#444444', linestyle='-', label='Semi-Annual Moving Mean')
plt.plot(df_evite.date, df_evite_f.rm3, color='#444444', linestyle='--', label='Seasonal Moving Mean')
plt.plot(df_evite.date, df_evite_f.rm2, color='#444444', linestyle=':', label='Bimonthly Moving Mean')
plt.legend()
plt.show()

plt.plot(df_evite.date, df_evite_f.events, color='#000000', linestyle='-', label='Total Events')
plt.plot(df_evite.date, df_evite_f.rs6, color='#444444', linestyle='-', label='Semi-Annual Moving Standard Deviation')
plt.plot(df_evite.date, df_evite_f.rs3, color='#444444', linestyle='--', label='Seasonal Moving Standard Deviation')
plt.plot(df_evite.date, df_evite_f.rs2, color='#444444', linestyle=':', label='Bimonthly Moving Standard Deviation')
plt.legend()
plt.show()

# fig, axs = plt.subplots(2)
# fig.suptitle('Time Series Analysis')
# axs[0].plot(df_evite.date, df_evite_f.events, color='#000000', linestyle='-', label='Total Events')
# axs[0].plot(df_evite.date, df_evite_f.rm6, color='#444444', linestyle='-', label='Semi-Annual Moving Mean')
# axs[0].plot(df_evite.date, df_evite_f.rm3, color='#444444', linestyle='--', label='Seasonal Moving Mean')
# axs[0].plot(df_evite.date, df_evite_f.rm2, color='#444444', linestyle=':', label='Bimonthly Moving Mean')
# axs[0].set_title("Moving Means")
# # plt.legend()
# axs[1].plot(df_evite.date, df_evite_f.events, color='#000000', linestyle='-', label='Total Events')
# axs[1].plot(df_evite.date, df_evite_f.rs6, color='#444444', linestyle='-', label='Semi-Annual Moving Standard Deviation')
# axs[1].plot(df_evite.date, df_evite_f.rs3, color='#444444', linestyle='--', label='Seasonal Moving Standard Deviation')
# axs[1].plot(df_evite.date, df_evite_f.rs2, color='#444444', linestyle=':', label='Bimonthly Moving Standard Deviation')
# axs[1].set_title("Standard Deviations")
# # plt.legend()
# plt.show()
