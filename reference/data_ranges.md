# Data Ranges Table

Creates a \`.html\` output table with data ranges from each station
within a database. Stores the average, minimum, and maximum values for
each variable.

## Usage

``` r
data_ranges(
  db_name = NULL,
  db_dir = "station_data",
  output_dir = "station_data"
)
```

## Arguments

- db_name:

  Character: The name of the database

- db_dir:

  The directory of the database, If left unchanged, will default to
  package's default created directory "station_data".

- output_dir:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.
