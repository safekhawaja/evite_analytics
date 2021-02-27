import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures
import matplotlib.pyplot as plt
from datetime import datetime
from sklearn.neighbors import KNeighborsRegressor
from sklearn.metrics import r2_score
from sklearn import svm
import sorting_functions

# Importing Data

evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/data/before_covid.csv", index_col=0, parse_dates=True)
evite["date"] = evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)
evite.date = evite.date.apply(pd.to_datetime)

# Formatting Data

evite['day'] = pd.DatetimeIndex(evite['date']).day
evite['month'] = pd.DatetimeIndex(evite['date']).month
evite['year'] = pd.DatetimeIndex(evite['date']).year

dateday = list(zip(evite.day.values, evite.month.values))
dates = np.array(dateday)

plt.scatter(evite.date, evite.events, color='#444444', linestyle='--', label='')
plt.show()

# columns_date = evite["date"].to_numpy()
# columns_events = evite["events"].to_numpy()
# col_ind = evite.index.to_numpy()

# idd = col_ind.reshape(-1, 1)
# cd2d = columns_date.reshape(-1, 1)
# ce2d = columns_events.reshape(-1, 1)

# Training Regression Models (linear, k-NN, logistic and polynomial regressors)

# lin_reg = LinearRegression()
# model = lin_reg.fit(idd, ce2d)
#
# r_sq = model.score(idd, ce2d)
#
# print('coefficient of determination:', r_sq)
#
# knn = KNeighborsRegressor(n_neighbors=3)
# knn.fit(idd, ce2d)
#
# print(knn.predict(cd2d[:3]))
# print(knn.score(cd2d, ce2d))


# X = [[0, 0], [1, 1]]
# y = [0, 1]
# clf = svm.SVC()
# clf.fit(X, y)
# SVC()
# clf.predict([[2., 2.]])


'''
# regression = linear_model.LinearRegression(degree=2) or:
# poly = PolynomialFeatures(degree=2)
# X_ = poly.fit_transform(X)
# predict_ = poly.fit_transform(predict)


# print('intercept:', model.intercept_)
# print('slope:', model.coef_)

# y_pred = model.intercept_ + model.coef_ * x
# print('predicted response:', y_pred, sep='\n')

# plt.plot(x, y, color='#444444', linestyle='--', label='')
plt.xlabel('date')
plt.ylabel('events')
plt.title('Test Regression')

# plt.savefig('plot.png')
# plt.show()

Pandas commands:

evite.shape
evite.count()
evite.columns
evite.dtypes
evite['city'].value_counts() #counts the records for each city
evite['category_0'].nunique() #counts the non-null unique values in category_0
'''

'''
import statsmodels.api as sm
fig = sm.qqplot(evite.events, line='45')
plt.show()

Any vartiable of data indexed for time does not follow normal distribution but leaving this here to check
'''
