import matplotlib.pyplot as plt


def first(n):
    return n[0]


def sort(tuples):
    return sorted(tuples, key=first)


# sorted_dates = sort(dateday)
# plt.show()
# print(sorted_dates)
