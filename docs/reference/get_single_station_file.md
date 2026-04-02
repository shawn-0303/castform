# Get Single Station File

Downloads a single weather station file from Environment Canada

## Usage

``` r
get_single_station_file(
  station_name = NULL,
  station_id = NULL,
  year = NULL,
  month = NULL,
  root_folder = "station_data",
  HLY_station_info = NULL
)
```

## Arguments

- station_name:

  Character: The name of the weather station of interest.

- station_id:

  Numeric Integer: The unique station ID of the weather station of
  interest.

- year:

  Numeric Integer: The year of the data pull. If left empty, will
  default to the first year for data collection for that particular
  station.

- month:

  Numeric Integer: The month of the data pull (1 - 12). If left empty,
  will default to January (1).

- root_folder:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.

- HLY_station_info:

  Dataframe: Station metadata
