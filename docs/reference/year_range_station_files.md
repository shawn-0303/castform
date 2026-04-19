# Download Stations by Year Range

Downloads a multiple weather station files collected between a specified
time period from Environment Canada

## Usage

``` r
year_range_station_files(
  station_name = NULL,
  station_id = NULL,
  start_year = NULL,
  end_year = NULL,
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

- start_year:

  Numeric Integer: The start year of the data pull. If left empty, will
  default to the first year for data collection for that particular
  station.

- end_year:

  Numeric Integer: The end year of the data pull. If left empty, it will
  default to only downloading one year of data from the start_year

- parallel_threshold:

  Numeric Integer: The required number of files to trigger parallel
  downloads. If left unchanged, parallelization will occur for downloads
  of 50 files or more.

- HLY_station_info:

  Dataframe: Station metadata

- root_folder:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.
