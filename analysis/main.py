import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures
import matplotlib.pyplot as plt
from sklearn.neighbors import KNeighborsRegressor

# Importing Data

evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/analysis/rollingmeans.csv", index_col=0, parse_dates=True)

# Formatting Data

columns_date = evite["date"].to_numpy()
columns_events = evite["events"].to_numpy()
columns_index = evite.index.to_numpy()

idd = columns_index.reshape(-1, 1)
cd2d = columns_date.reshape(-1, 1)
ce2d = columns_events.reshape(-1, 1)

# Training Regression Models (linear, k-NN, logistic and polynomial regressors)

lin_reg = LinearRegression()
model = lin_reg.fit(idd, ce2d)

r_sq = model.score(idd, ce2d)

print('linear coefficient of determination:', r_sq)

count = 1
knn_scores = []

while count < 33:
    knn = KNeighborsRegressor(n_neighbors=count)
    knn.fit(idd, ce2d)
    print('k = ', count, ' k-NN score:', knn.score(idd, ce2d))
    knn_scores.append([count, knn.score(idd, ce2d)])
    count = count + 1

knns = pd.DataFrame(knn_scores)
knns.to_csv('knns.csv')

poly_reg = PolynomialFeatures(degree=4)
X_poly = poly_reg.fit_transform(ce2d)
poly_reg.fit(idd, ce2d)
lin_reg2 = LinearRegression()
lin_reg2.fit(idd, ce2d)

r_sq = lin_reg2.score(idd, ce2d)
print('polynomial coefficient of determination:', r_sq)

# count = 1
# poly_scores = []
#
# while count < 8:
#     poly_reg = PolynomialFeatures(degree=count)
#     poly_reg.fit(idd, ce2d)
#     print('degree = ', count, ' polynomial coefficient of determination:', lin_reg2.score(idd, ce2d))
#     poly_scores.append([count, lin_reg2.score(idd, ce2d)])
#     count = count + 1
#
# print(poly_scores)

# X_grid = np.arange(min(ce2d),max(ce2d),0.1)
# X_grid = X_grid.reshape((len(X_grid), 1))
#
# plt.scatter(idd, ce2d, color='red')
# plt.plot(idd, lin_reg2.predict(poly_reg.fit_transform(ce2d)), color='blue')
# plt.title('Events on Date (Polynomial Regression)')
# plt.xlabel('Date')
# plt.ylabel('Events')
# plt.show()

'''
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

Any variable of data indexed for time does not follow normal distribution but leaving this here to check

# clf = svm.SVC()
# clf.fit(idd, ce2d)
# print('SVC coefficient of determination:', clf.score(idd, ce2d))
'''
