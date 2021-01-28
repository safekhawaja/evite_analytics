import numpy as np
from sklearn.linear_model import LinearRegression
import matlibplot

x = np.array([5, 15, 25, 35, 45, 55]).reshape((-1, 1))
y = np.array([5, 20, 14, 32, 22, 38])

model = LinearRegression().fit(x, y)

r_sq = model.score(x, y)

print('coefficient of determination:', r_sq)

print('intercept:', model.intercept_)
print('slope:', model.coef_)

y_pred = model.intercept_ + model.coef_ * x
print('predicted response:', y_pred, sep='\n')
