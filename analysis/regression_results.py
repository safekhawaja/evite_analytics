from sklearn.metrics import mean_squared_error
import pandas as pd
from datetime import datetime
import matplotlib as mpl
import matplotlib.pyplot as plt
from pandas.plotting import autocorrelation_plot
from pandas import DataFrame
from statsmodels.tsa.arima.model import ARIMA
from math import sqrt


# Pull data from CSV
df = pd.read_csv("/Users/saif/Downloads/GOOGL.csv", index_col=0, parse_dates=True)
# df["Date"] = df.apply(lambda x: datetime.strptime(x["Date"][0:7], "%d%b%y"), axis=1)

# Autocorrelation: serial correlation  between elements and others separated by a given interval.

autocorrelation_plot(df.High)
# plt.legend()
# plt.show()

# Rolling Means

# df = df.assign(rs7=df.High.rolling(window=7).std())
# df = df.assign(rm7=df.High.rolling(window=7).mean())
# df = df.assign(rs31=df.High.rolling(window=31).std())
# df = df.assign(rm31=df.High.rolling(window=31).mean())

model = ARIMA(df.High, order=(5, 1, 0))
model_fit = model.fit()
print(model_fit.summary())

# Integration

residuals = DataFrame(model_fit.resid)
residuals.plot()
# plt.show()

residuals.plot(kind='kde')
# plt.show()

print(residuals.describe())
# Note: the mean is very close to 0 and therefore there is not much bias in the residuals.





# Forecasting Function

# Splitting data into test and train set

X = df.High.values
size = int(len(X) * 0.66)
train, test = X[0:size], X[size:len(X)]
history = [x for x in train]
predictions = list()

# Walk-forward validation

for t in range(len(test)):
    model = ARIMA(history, order=(5, 1, 0))
    model_fit = model.fit()
    output = model_fit.forecast()
    yhat = output[0]
    predictions.append(yhat)
    obs = test[t]
    history.append(obs)
    print('predicted=%f, expected=%f' % (yhat, obs))

# Evaluate forecasts

rmse = sqrt(mean_squared_error(test, predictions))
print('Test RMSE: %.3f' % rmse)

# Plot forecasts against actual outcomes

plt.plot(test)
plt.plot(predictions, color='red')
plt.show()
