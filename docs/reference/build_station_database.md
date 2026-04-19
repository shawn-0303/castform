# Create Station Databases

Creates a database using a folder of specified weather station data.
This will automatically create three tables. A Station information table
using HLY_station_info, a Weather table to look up weather conditions
and their associated numeric code, and an Observation table made using
downloaded station data (.csv) files.

## Usage

``` r
build_station_database(
  db_name = NULL,
  HLY_station_info = NULL,
  out_dir = "station_data",
  root_folder = "station_data"
)
```

## Arguments

- db_name:

  Character: The name of the database

- HLY_station_info:

  Station metadata

- out_dir:

  The created output directory of the database. If left unchanged, will
  store the database within the default root_folder

- root_folder:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.
