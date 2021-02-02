import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt
from datetime import datetime

evite = pd.read_csv("/Users/saif/Downloads/data_cleaned_for_class.csv", index_col=0, parse_dates=True)
evite["date"] = evite.apply(lambda x: datetime.strptime(x["date"][0:7], "%d%b%y"), axis=1)

print(evite.columns.values.tolist())

columns = evite[["date", "events"]].to_numpy()
# evite.head()

# evite.plot()
# evite.plot.box()

x = np.array(columns["date"])
y = np.array(columns["events"])

model = LinearRegression().fit(x, y)

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

'''
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