# Pull Strings of Missing Data

Creates a \`.html\` output table and plot to identify when data is
missing from the database. Stores the length of the data gap (in hours)
as well as the start and end date/time.

## Usage

``` r
pull_missing_strings(
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
