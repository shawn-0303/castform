# Get All Hourly Station Files

Downloads all Environment Canada data from all stations with hourly data
available.

## Usage

``` r
get_all_files(root_folder = "station_data", HLY_station_info = NULL)
```

## Arguments

- root_folder:

  The created download folder and file path. If left unchanged, will
  create a new "station_data" folder in the working directory.

- HLY_station_info:

  Dataframe: Station metadata
