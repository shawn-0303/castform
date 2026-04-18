# Introduction to castform

## Overview

![castform hex sticker](../reference/figures/castform_logo.png)

This document is an introduction to the castform package. It has
everything you need to download and analyze historical climate data from
the Department of Environment and Climate Change Canada (ECCC).

<https://climate.weather.gc.ca/historical_data/search_historic_data_e.html>

When doing weather station analyses you need to:

- Download weather station data
- Put the data into executable databases
- Pull the data for analysis
- Print user friendly outputs

The castform package provides you with functions for a complete
analysis.

  

``` r
library(castform)
```

## Loading Metadata

``` r
get_metadata()
```

The function
[`get_metadata()`](https://shawn-0303.github.io/castform/reference/get_metadata.md)
downloads the latest station inventory list from ECCC. No input
parameters are required to run this function. When run, this function
will download the station inventory list as a `.csv` file and save it as
a backup `.rda` file.

[`get_metadata()`](https://shawn-0303.github.io/castform/reference/get_metadata.md)
will automatically update `HLY_station_info` to store the latest
download after filtering for stations that contain hourly data (stations
where `HLY.First.Year` and `HLY.First.Year` are not NA values).
`HLY_station_info` is automatically loaded into the user’s global
environment.

`HLY_station_info` is expected to include these key columns:

- `stationName`: The name of the station. (**Note:** some stations have
  the same name but different station ids.)
- `Station.ID`: The unique identifier for each station
- `Province`: The Canadian province or territory the station is located.
- `HLY.First.Year`: The first year with available hourly data
- `HLY.Last.Year`: The last year with available hourly data

This station inventory list is required for all download wrappers so it
must be the first thing that is run before any analysis.

## Searching for Station Information

All the download wrappers require specific information about the
station(s) the user wants to download. This information can be pulled
from the metadata using
[`station_lookup()`](https://shawn-0303.github.io/castform/reference/station_lookup.md).

``` r
station_lookup(province = "prince edward island",
               start_year = 1953,
               end_year = 2001)
```

You can search for stations by `Province` as well as the `start_year`
and `end_year` of hourly data collection.

## Downloading Hourly Station Data

The following are walk-throughs of the different download wrappers.

### Download a Single Station File

[`get_single_station_file()`](https://shawn-0303.github.io/castform/reference/get_single_station_file.md)
will download a single `.csv` file from a specified station that stores
a month of hourly weather data.

If your goal is a larger download, it is a good idea to verify your
station information and output directories using this function.

``` r
get_single_station_file(station_name =  "discovery island",
                        station_id = 27226,
                        year = 1997,
                        month = 1,
                        root_folder = "station_data")
```

To download a station file you must input either a valid `station_name`
or `station_id`.

If the other parameters are left unspecified, the function will make the
following defaults:

- `year`: Defaults to the first year of hourly data collection (for that
  station)
- `month`: Defaults to January (month = 1)
- `root_folder`: Defaults to creating a new folder called “station_data”
  in your current working directory

This function will be called by all other download wrappers, resulting
in similar defaults across the package.

There are cases where multiple stations have the same name. If this
occurs, R will return a list of the station names with their associated
IDs. Then, re-run the function and input both `station_name` and
`station_id` to specify a match.

### Downloading Multiple Station Files

[`get_multiple_station_files()`](https://shawn-0303.github.io/castform/reference/get_multiple_station_files.md)
will download multiple `.csv` files from a specified station. The number
of files to download is specified using `number_of_files` and the
download starting point is specified using `year` and `month`.

Here we are downloading 10 files for Discovery Island in British
Columbia with the download starting point of January 1997.

``` r
get_multiple_station_files(station_name = "discovery island",
                           station_id = 27226,
                           number_of_files = 10,
                           year = 1997,
                           month = 1,
                           parallel_threshold = 50,
                           root_folder = "station_data")
```

In cases where a large amount of files are being downloaded, R will
return a list of the estimated number of files to be downloaded, an
estimation of the space required, and ask for user confirmation before
the download proceeds.

If the total number of files exceeds the `parallel_threshold` (default =
50), the download will be parallelized across several cores to speed up
the download.

### Download Files by Station

Here we are downloading all available hourly station data from Discovery
Island in British Columbia from October 1999

``` r
get_station_files(station_name = "discovery island",
                  station_id = 27226,
                  year = 1997,
                  month = 10,
                  parallel_threshold = 50,
                  root_folder = "station_data")
```

If `year` and `month` are left empty, it will default to all years with
available data for that province and for every month (1-12).

This downloads all available hourly station data from Discovery Island

``` r
get_station_files(station_name = "discovery island",
                  station_id = 27226,
                  parallel_threshold = 50,
                  root_folder = "station_data")
```

### Download Files by Province

Province and territory can be input as full or abbreviated names.

Here we are downloading all available hourly station data from Prince
Edward Island from February 1980

``` r
province_station_files(province = "prince edward island",
                       year = 1980,
                       month = "february",
                       parallel_threshold = 50,
                       root_folder = "station_data")
```

If `year` and `month` are left empty, it will default to all years with
available data for that province and for every month (1-12).

This downloads all available hourly station data from Prince Edward
Island

``` r
province_station_files(province = "prince edward island",
                       parallel_threshold = 50,
                       root_folder = "station_data")
```

### Download Files by Year Range

Here, we are downloading hourly station data from Discovery Island in
British Columbia from 1997 to 1999.

``` r
year_range_station_files(station_name = "discovery island",
                         station_id = 27226,
                         start_year = 1997,
                         end_year = 1999,
                         parallel_threshold = 50,
                         root_folder = "station_data")
```

If `start_year` and `end_year` are left empty, `start_year` will default
to to the first year hourly data is available data and `end_year` will
default to `start_year`, resulting in one year of downloads.

### Download All Available Hourly Station Data

This function downloads all available historical hourly weather station
data from Canada and will **result in a very large download**.

``` r
get_all_files(root_folder = "station_data")
```

### Additional Download Information

If the user has run
[`get_metadata()`](https://shawn-0303.github.io/castform/reference/get_metadata.md),
download wrapper functions will default to using the resulting
`Hourly_Station_Info`. If a past version of the station list needs to be
used, the user can edit the `Hourly_Station_Info` parameter within each
function.

``` r
province_station_files(province = "prince edward island",
                       parallel_threshold = 50,
                       root_folder = "station_data",
                       HLY_station_info = "station_inventory_2026-03-23.rda")
```

## Making Databases

[`build_station_database()`](https://shawn-0303.github.io/castform/reference/build_station_database.md)
can be used to create a searchable database with a specified folder of
hourly weather station data.

Input database names will automatically have spaces replaced with
underscores and be turned to uppercase.

``` r
build_station_database <- function(db_name = "BC station data") 
```

If `output_dir` and `root_folder` are left empty, data will be pulled
from the package’s default data storage folder (“station_data”) in the
user’s working directory and the database will be stored in the same
folder.

Input and output directories can be specified editing these parameters

``` r
build_station_database <- function(db_name = "BC_STATION_DATA", 
                                   output_dir = "castform_outputs", 
                                   root_folder = "downloaded_data/British_Columbia") 
```

This function builds an database with three tables:

- `Weather`: Stores weather conditions and their associated numeric
  codes
- `Station`: Stores weather station information using `HLY_station_info`
- `Observation`: Stores information from downloaded station data (.csv)
  files

### Validating Database Creation

After the database is created, users can use
[`validate_database()`](https://shawn-0303.github.io/castform/reference/validate_database.md).
This will check for the created tables, list the number of observations
within each table, and lists the first five observations within the
`Observation` table.

``` r
validate_database(db_name = "BC_STATION_DATA",
                  db_dir = "castform_outputs")
```

There should be three tables: `Weather`, `Station`, and `Observation`.

- `Weather` should have 54 records
- `Station` should have as many records as `HLY_Station_Info`
- `Observation` should have as many records as stored in the downloaded
  data files

## Exploratory Data Analysis

After data is downloaded and loaded onto a database, users should always
perform exploratory data analyses. castform provides functions to
summarize and visualize the data. All outputs are exported as `.html`
files, but users can copy the results or download them as `.csv` or
`.pdf` files.

Input database names will automatically have spaces replaced with
underscores and be turned to uppercase.

Every EDA function has the same three parameters:

- `db_name` = The name of the database
- `db_dir` = The directory where the database is stored (default =
  “station_data_name_outputs”)
- `output_dir` = The directory where produced outputs will be stored
  (default = “station_data_name_outputs”)
- `output_name` = The name of the produced `.html` and `.png` outputs.
  If left empty. the default file name will start with “db_name” and end
  with the related EDA function.

### Station Map

[`station_map()`](https://shawn-0303.github.io/castform/reference/station_map.md)
creates a `.png` that plots the stations of interest on a map of Canada.

``` r
station_map(db_name =  "BC_STATION_DATA",
            output_name = "bc station map")
```

If `metadata_stations` is set to `TRUE`, `db_name` must be left empty.
The function will use `HLY_Station_Info` to plot and visualize all
stations with hourly data available.

``` r
station_map(metadata_stations = TRUE,
            output_name = "metadata station map")
```

### Data Missingness Table

[`data_missingness_table()`](https://shawn-0303.github.io/castform/reference/data_missingness_table.md)
creates a table outlining the expected and actual data counts, along
with the percentage of missing data for each variable in each station.

``` r
data_missingness_table(db_name =  "BC_STATION_DATA")
```

### Data Range Table

[`data_ranges()`](https://shawn-0303.github.io/castform/reference/data_ranges.md)
creates a table outlining the average, minimum, and maximum values for
each variable in each station.

``` r
data_ranges(db_name =  "BC_STATION_DATA")
```

### Yearly Means Plots

[`plot_yearly_means()`](https://shawn-0303.github.io/castform/reference/plot_yearly_means.md)
creates plots outlining the values for each variable over time for every
year the station is active.

``` r
plot_yearly_means(db_name =  "BC_STATION_DATA")
```

### Identify Data Gaps

[`pull_missing_strings()`](https://shawn-0303.github.io/castform/reference/pull_missing_strings.md)
identifies gaps or missing strings of data. It creates a table to
identify when data is missing and stores the length (in hours), as well
as the start and end date/time for each gap. It will also create an
interactive plot to visualize these gaps

``` r
pull_missing_strings(db_name =  "BC_STATION_DATA")
```

### Identify Repeated Strings

Hours of repeated data values can indicate faulty machinery during data
collection.
[`pull_repeated_strings()`](https://shawn-0303.github.io/castform/reference/pull_repeated_strings.md)
identifies strings of repeated values that occur for three hours or
more. This can indicate faulty machinery in data collection. The table
stores the length (in hours) and start and end date/time of the repeated
strings. It will also create an interactive plot to visualize these
strings.

``` r
pull_repeated_strings(db_name =  "BC_STATION_DATA")
```

**NOTE:** This will take longer to run on larger datasets. Large
datasets will also require zooming into plots to see outputs or else the
plot will look empty.

## Heat Wave Indicator

After verifying the data, you can now perform an analysis to detect
extreme weather events.
[`heatwave_detector()`](https://shawn-0303.github.io/castform/reference/heatwave_detector.md)
allows for the detection of extreme heat events using user input
temperature thresholds (in Celcius).

This function uses ECCC’s definition of extreme heat events, which
defines them as “events during which daily temperatures have reached
heat warning thresholds on 2 or more consecutive days with no relief
overnight”.

To use ECCC temperature thresholds, leave `max_threshold` and
`min_threshold` blank and they will be automatically applied.
Temperature thresholds and station climate rgions were last updated on
**April 18, 2026**, using:

<https://www.canada.ca/en/environment-climate-change/services/environmental-indicators/extreme-heat-events.html>.

``` r
heatwave_detector(db_name =  "BC_STATION_DATA")
```

If `max_threshold` and `min_threshold` are specified by the user, input
values will take priority and be applied.

``` r
heatwave_detector(db_name =  "BC_STATION_DATA",
                  max_threshold = 28,
                  min_threshold = 13)
```

This function will a table and plot summarizing daily temperature
averages. The table stores logical information on whether that day
crosses the temperature thresholds and whether it is considered a
heatwave. The plot visualizes this information by plotting daily
temperatures and highlighting when heatwave events occur.
