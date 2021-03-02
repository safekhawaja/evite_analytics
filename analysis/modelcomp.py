from sklearn.ensemble import RandomForestRegressor
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import TimeSeriesSplit, cross_val_score
import sklearn.metrics as metrics
from sklearn.neighbors import KNeighborsRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.svm import SVR

'''
How well does a time series trained on pre-COVID event occurences predict current events?
'''


def regression_results(y_true, y_pred):
    # Regression Metrics
    explained_variance = metrics.explained_variance_score(y_true, y_pred)
    mean_absolute_error = metrics.mean_absolute_error(y_true, y_pred)
    mse = metrics.mean_squared_error(y_true, y_pred)
    mean_squared_log_error = metrics.mean_squared_log_error(y_true, y_pred)
    median_absolute_error = metrics.median_absolute_error(y_true, y_pred)
    r2 = metrics.r2_score(y_true, y_pred)

    print('explained_variance: ', round(explained_variance, 4))
    print('mean_squared_log_error: ', round(mean_squared_log_error, 4))
    print('r2: ', round(r2, 4))
    print('MAE: ', round(mean_absolute_error, 4))
    print('MSE: ', round(mse, 4))
    print('RMSE: ', round(np.sqrt(mse), 4))


evite = pd.read_csv("/Users/saif/Documents/GitHub/mktg401/analysis/rollingmeans.csv", index_col=0, parse_dates=True)

# Formatting Data

evite['day'] = pd.DatetimeIndex(evite['date']).day
evite['month'] = pd.DatetimeIndex(evite['date']).month
evite['year'] = pd.DatetimeIndex(evite['date']).year

dateday = list(zip(evite.day.values, evite.month.values))
dates = np.array(dateday)

X_train = evite.events[:'2020'].drop(['Events'], axis=1)
y_train = evite.events.loc[:'2020', 'Events']

# Spot Check Algorithms
models = []
models.append(('LR', LinearRegression()))
models.append(('NN', MLPRegressor(solver='lbfgs')))  # neural network
models.append(('KNN', KNeighborsRegressor()))
models.append(('RF', RandomForestRegressor(n_estimators=10)))  # Ensemble method - collection of many decision trees
models.append(('SVR', SVR(gamma='auto')))  # kernel = linear

# Evaluate each model in turn
results = []
names = []

for name, model in models:
    # TimeSeries Cross validation
    tscv = TimeSeriesSplit(n_splits=10)

    cv_results = cross_val_score(model, X_train, y_train, cv=tscv, scoring='r2')
    results.append(cv_results)
    names.append(name)
    print('%s: %f (%f)' % (name, cv_results.mean(), cv_results.std()))

# Compare Algorithms
plt.boxplot(results, labels=names)
plt.title('Algorithm Comparison')
plt.show()
