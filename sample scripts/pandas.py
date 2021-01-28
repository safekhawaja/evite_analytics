import pandas as pd

df = pd.read_excel(’my_file.xlsx’) #read the file into a DataFrame

df.shape

df.count()
df.columns
df.dtypes

df["name"] #returns name for every record

df["city"].unique() #returns the unique values in city

df['city'].value_counts() #counts the records for each city

df['category_0'].nunique() #counts the non-null unique values in category_0

import numpy as np
df.groupby(['city']).agg([np.sum, np.mean, np.std])["stars"]
