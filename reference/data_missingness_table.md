# Data Missingness Table

Identifies data missingness from each station within a database.

## Usage

``` r
data_missingness_table(
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

An \`.html\` output table that stores the expected, account, and percent
missing counts for each variable.
