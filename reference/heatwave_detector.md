# Detect Extreme Heat Events (Heatwaves)

Scan the downloaded data to detect extreme heat events. Produces a
\`.html\` table and plot output summarizing average daily temperatures
and flags extreme heat events based on user input thresholds.

## Usage

``` r
heatwave_detector(
  db_name = NULL,
  max_threshold = NULL,
  min_threshold = NULL,
  db_dir = "station_data",
  output_dir = "station_data"
)
```

## Arguments

- db_name:

  Character: The name of the database

- max_threshold:

  Numeric: Maximum temperature threshold for an extreme heat event

- min_threshold:

  Numeric: Minimum temperature threshold for an extreme heat event

- db_dir:

  The directory of the database, If left unchanged, will default to
  package's default created directory "station_data".

- output_dir:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.
