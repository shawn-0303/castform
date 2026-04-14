# Validate Created Database

Used to validate databases created by \`build_station_database\`. This
function will check for tables created within the database, count the
number of records within each table, and print the first five
observation records.

## Usage

``` r
validate_database(db_name = NULL, db_dir = "station_data")
```

## Arguments

- db_name:

  Character: The name of the database

- db_dir:

  The directory of the database, If left unchanged, will default to
  package's default created directory "station_data".
