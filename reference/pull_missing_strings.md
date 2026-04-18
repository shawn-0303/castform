# Pull Strings of Missing Data

Identifies when data is missing from the database.

## Usage

``` r
pull_missing_strings(
  db_name = NULL,
  db_dir = "station_data",
  output_dir = "station_data",
  output_name = NULL
)
```

## Arguments

- db_name:

  Character: The name of the database

- db_dir:

  Character: The directory of the database, If left unchanged, will
  default to package's default created directory "station_data".

- output_dir:

  Character: The created download folder and file path. If left
  unchanged, will create a new "station_data" folder in the working
  directory.

- output_name:

  Character: The name of the output file. If left unfilled, the function
  will name the file "db_name_missingness_table.html"

## Value

A \`.html\` output table and plot that displays the length of the data
gap (in hours) as well as the start and end date/time.
