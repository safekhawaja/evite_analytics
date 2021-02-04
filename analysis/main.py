import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
# from sklearn.preprocessing import PolynomialFeatures
import matplotlib.pyplot as plt
from datetime import datetime

# https://scikit-learn.org/stable/supervised_learning.html#supervised-learning
# https://scikit-learn.org/stable/modules/generated/sklearn.cluster.KMeans.html

evite = pd.read_csv("/Users/saif/Downloads/data_cleaned_for_class.csv", index_col=0, parse_dates=True)
evite["date"] = evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)
 
# print(evite.columns.values.tolist())

# evite.describe()

columns_date = evite["date"].to_numpy()
columns_events = evite["events"].to_numpy()

breakpoint()

cd2d = columns_date.reshape(-1, 1)
ce2d = columns_events.reshape(-1, 1)

lin_reg = LinearRegression()
model = lin_reg.fit(cd2d, ce2d)

# r2_score(x, y)

'''
# regression = linear_model.LinearRegression(degree=2) or:
# poly = PolynomialFeatures(degree=2)
# X_ = poly.fit_transform(X)
# predict_ = poly.fit_transform(predict)

# r_sq = model.score(x, y)

# print('coefficient of determination:', r_sq)

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

evite.shape

evite.count()
evite.columns
evite.dtypes

evite["name"] #returns name for every record

evite["city"].unique() #returns the unique values in city

evite['city'].value_counts() #counts the records for each city

evite['category_0'].nunique() #counts the non-null unique values in category_0

evite.groupby(['city']).agg([np.sum, np.mean, np.std])["stars"]
'''