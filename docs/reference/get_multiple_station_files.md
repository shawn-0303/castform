# Get Multiple Station Files

Downloads a multiple weather station files from Environment Canada

## Usage

``` r
get_multiple_station_files(
  station_name = NULL,
  station_id = NULL,
  number_of_files = NULL,
  year = NULL,
  month = NULL,
  parallel_threshold = 50,
  out_dir = "station_data",
  HLY_station_info = NULL
)
```

## Arguments

- station_name:

  Character: The name of the weather station of interest.

- station_id:

  Numeric Integer: The unique station ID of the weather station of
  interest.

- number_of_files:

  Numeric Integer: The number of files the user wishes to download.

- year:

  Numeric Integer: The year of the data pull. If left empty, will
  default to the first year for data collection for that particular
  station.

- month:

  Numeric Integer: The month of the data pull (1 - 12). If left empty,
  will default to January (1).

- parallel_threshold:

  Numeric Integer: The required number of files to trigger parallel
  downloads. If left unchanged, parallelization will occur for downloads
  of 50 files or more.

- out_dir:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.

- HLY_station_info:

  Dataframe: Station metadata
