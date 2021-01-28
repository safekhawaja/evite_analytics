import csv

"""
my_file = open('my_file_path / my_file.csv', 'r')  # open the file

reader = csv.DictReader(my_file)

# do stuff

my_file.close()
"""

def is_valid_year(string):
    try:
        year = int(string)  # try casting string to an integer named year
    except ValueError:
        return False  # return False if a ValueError is generated
    else:
        return year > 1400 # otherwise, return the year value

with open('_______') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')

    print(reader.fieldnames)

    line_count = 0

    for row in csv_reader:
        if line_count == 0:
            print(f'Column names are {", ".join(row)}')
            line_count += 1
        else:
            print(f'\t{row[0]} works in the {row[1]} department, and was born in {row[2]}.')
            line_count += 1

        albums[]
        albums.append(row)
        # albums_1974 = [row for row in albums if row[“Year”] == "1974”]

        print("Number albums:", len(albums))

        rock_albums = [row for row in albums if
            (row["Genre"] == "Rock" and ("Pop Rock" in row["Subgenre"] or "Fusion" in row["Subgenre"]))]
        for album in rock_albums:
            print(album["Album"], album["Artist"], album["Genre"], album["Subgenre”])

        release_years = [int(row['Year']) for row in albums if is_valid_year(row['Year'])]
        print(release_years)

        min_release_year = min(release_years)
        print(min_release_year)

    print(f'Processed {line_count} lines.')
