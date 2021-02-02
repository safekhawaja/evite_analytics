import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

evite = pd.read_csv("data/air_quality_no2.csv", index_col=0, parse_dates=True)

evite.head()

evite.plot()

evite.plot.box()

fig, axs = plt.subplots(figsize=(12, 4))

evite.plot.area(ax=axs)

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