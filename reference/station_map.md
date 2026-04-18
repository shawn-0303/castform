# Plot Stations on Map

Allows for users to plot all metadata stations or selected stations on a
map of Canada.

## Usage

``` r
station_map(
  db_name = NULL,
  db_dir = "station_data",
  output_dir = "station_data",
  output_name = NULL,
  metadata_stations = FALSE
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

  Character: The chosen name of the output \`png\` object.

- metadata_stations:

  Logical: Plot all stations in the metadata (default = FALSE)

## Value

A \`.png\` of the created map
