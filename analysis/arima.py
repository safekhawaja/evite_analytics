import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from statsmodels.tsa.stattools import adfuller
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.arima_model import ARIMA
from pandas.plotting import register_matplotlib_converters

register_matplotlib_converters()

df = pd.read_csv('air_passengers.csv', parse_dates=['Month'], index_col=['Month'])

df.head()

plt.xlabel('Date')
plt.ylabel('Number of air passengers')
plt.plot(df)

rolling_mean = df.rolling(window = 12).mean()
rolling_std = df.rolling(window = 12).std()plt.plot(df, color = 'blue', label = 'Original')

plt.plot(rolling_mean, color = 'red', label = 'Rolling Mean')
plt.plot(rolling_std, color = 'black', label = 'Rolling Std')
plt.legend(loc = 'best')
plt.title('Rolling Mean & Rolling Standard Deviation')
plt.show()

result = adfuller(df['Passengers'])print('ADF Statistic: {}'.format(result[0]))

print('p-value: {}'.format(result[1]))
print('Critical Values:')

for key, value in result[4].items():
    print('\t{}: {}'.format(key, value))

df_log = np.log(df)
plt.plot(df_log)


def get_stationarity(timeseries):
    # rolling statistics
    rolling_mean = timeseries.rolling(window=12).mean()
    rolling_std = timeseries.rolling(window=12).std()

    # rolling statistics plot
    original = plt.plot(timeseries, color='blue', label='Original')
    mean = plt.plot(rolling_mean, color='red', label='Rolling Mean')
    std = plt.plot(rolling_std, color='black', label='Rolling Std')
    plt.legend(loc='best')
    plt.title('Rolling Mean & Standard Deviation')
    plt.show(block=False)

    # Dickey–Fuller test:
    result = adfuller(timeseries['Passengers'])
    print('ADF Statistic: {}'.format(result[0]))
    print('p-value: {}'.format(result[1]))
    print('Critical Values:')
    for key, value in result[4].items():
        print('\t{}: {}'.format(key, value))

rolling_mean = df_log.rolling(window=12).mean()
df_log_minus_mean = df_log - rolling_mean
df_log_minus_mean.dropna(inplace=True)get_stationarity(df_log_minus_mean)

rolling_mean_exp_decay = df_log.ewm(halflife=12, min_periods=0, adjust=True).mean()
df_log_exp_decay = df_log - rolling_mean_exp_decay
df_log_exp_decay.dropna(inplace=True)get_stationarity(df_log_exp_decay)

df_log_shift = df_log - df_log.shift()
df_log_shift.dropna(inplace=True)get_stationarity(df_log_shift)