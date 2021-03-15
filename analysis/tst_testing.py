import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt

# Rolling Averages

df_evite_f = pd.read_csv("rollingmeans.csv", index_col=0, parse_dates=True)

df_evite_m = df_evite_f.assign(adj1=df_evite_f.events - df_evite_f.rm2)
df_evite_n = df_evite_m.assign(adj2=df_evite_f.events - df_evite_f.rm3)
df_evite_o = df_evite_n.assign(adj3=df_evite_f.events - df_evite_f.rs3)
df_evite_p = df_evite_o.assign(adj4=df_evite_f.events - df_evite_f.rs2)

mpl.rcParams['agg.path.chunksize'] = 10000
plt.plot(df_evite_m.date, df_evite_m.adj1, color='#000000', linestyle='-', label='Events - Bimonthly RM')
plt.plot(df_evite_p.date, df_evite_p.adj2, color='#000000', linestyle='-', label='Events - Seasonal RM')
plt.plot(df_evite_p.date, df_evite_p.adj3, color='#444444', linestyle='-', label='Events - Seasonal RS')
plt.plot(df_evite_p.date, df_evite_p.adj4, color='#444444', linestyle='--', label='Events - Bimonthly RS')
plt.legend()
plt.show()
