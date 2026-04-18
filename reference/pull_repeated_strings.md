# Pull Strings of Repeated Data

Identifies when data values are repeated at least three times in a row.

## Usage

``` r
pull_repeated_strings(
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

  The directory of the database, If left unchanged, will default to
  package's default created directory "station_data".

- output_dir:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.

- output_name:

  Character: The name of the output file. If left unfilled, the function
  will name the file "db_name_missingness_table.html"

## Value

a \`.html\` output table and plot that stores the length of the repeat
(in hours) as well as the start and end date/time. Large amounts of data
mayt take longer to load and require users to zoom into the plot to see
points.
