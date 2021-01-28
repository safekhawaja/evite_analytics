import numpy as np
from sklearn.linear_model import LinearRegression
from matplotlib import pyplot as plt

x = np.array([5, 15, 25, 35, 45, 55]).reshape((-1, 1))
y = np.array([5, 20, 14, 32, 22, 38])

model = LinearRegression().fit(x, y)

r_sq = model.score(x, y)

print('coefficient of determination:', r_sq)

print('intercept:', model.intercept_)
print('slope:', model.coef_)

y_pred = model.intercept_ + model.coef_ * x
print('predicted response:', y_pred, sep='\n')

plt.plot(x, y, color='#444444', linestyle='--', label='')

plt.xlabel('x')
plt.ylabel('y')
plt.title('Test Data')

plt.savefig('plot.png')
plt.show()
