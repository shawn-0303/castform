# Province Station Files

Download Environment Canada weather station files by province.

## Usage

``` r
province_station_files(
  province = NULL,
  year = NULL,
  month = NULL,
  parallel_threshold = 50,
  out_dir = "station_data",
  HLY_station_info = NULL
)
```

## Arguments

- province:

  Character: The province or territory of interest.

- year:

  Numeric Integer: The year of the data pull. If left empty, will
  default to downloading all years with hourly data for that particular
  station.

- month:

  Numeric Integer: The month of the data pull (1 - 12). If left empty,
  will default to downloading data for all months (1-12).

- parallel_threshold:

  Numeric Integer: The required number of files to trigger parallel
  downloads. If left unchanged, parallelization will occur for downloads
  of 50 files or more.

- out_dir:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.

- HLY_station_info:

  Dataframe: Station metadata
