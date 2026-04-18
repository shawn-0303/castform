# castform: Download Environment Canada Weather Station Data

Downloads hourly weather station data (as csv files) from Environment
Canada. This data is downloaded from:
https://climate.weather.gc.ca/historical_data/search_historic_data_e.html

## Metadata

- [`get_metadata`](https://shawn-0303.github.io/castform/reference/get_metadata.md):
  Downloads and loads the latest station inventory metadata (RUN THIS
  FIRST)

- [`station_lookup`](https://shawn-0303.github.io/castform/reference/station_lookup.md):
  Search for available station data by province and year range.

## Download Wrappers

- [`get_single_station_file`](https://shawn-0303.github.io/castform/reference/get_single_station_file.md):
  The primary function to download one hourly data file.

- [`get_multiple_station_files`](https://shawn-0303.github.io/castform/reference/get_multiple_station_files.md):
  Downloads multiple hourly data files.

- [`get_station_files`](https://shawn-0303.github.io/castform/reference/get_station_files.md):
  Downloads data files by station

- [`province_station_files`](https://shawn-0303.github.io/castform/reference/province_station_files.md):
  Downloads data files by province.

- [`year_range_station_files`](https://shawn-0303.github.io/castform/reference/year_range_station_files.md):
  Downloads data files by year range.

- [`get_all_files`](https://shawn-0303.github.io/castform/reference/get_all_files.md):
  Downloads all data files with hourly data available.

## Database Building

- [`build_station_database`](https://shawn-0303.github.io/castform/reference/build_station_database.md):
  Creates a database using a folder of specified weather station data

- [`validate_database`](https://shawn-0303.github.io/castform/reference/validate_database.md):
  Validates created database

## Exploratory Data Analysis

- [`station_map`](https://shawn-0303.github.io/castform/reference/station_map.md):
  Creates a map visualizing stations of interest

- [`data_missingness_table`](https://shawn-0303.github.io/castform/reference/data_missingness_table.md):
  Creates a table summarizing actual, expected, and missing data counts

- [`data_ranges`](https://shawn-0303.github.io/castform/reference/data_ranges.md):
  Creates a table summarizing variable data ranges

- [`plot_yearly_means`](https://shawn-0303.github.io/castform/reference/plot_yearly_means.md):
  Creates plots to summarize yearly variable means

- [`pull_missing_strings`](https://shawn-0303.github.io/castform/reference/pull_missing_strings.md):
  Creates a plot and table summarizing missing data gaps

- [`pull_repeated_strings`](https://shawn-0303.github.io/castform/reference/pull_repeated_strings.md):
  Creates a plot and table summarizing repeated data strings

## Heatwave Detector

- [`heatwave_detector`](https://shawn-0303.github.io/castform/reference/heatwave_detector.md):
  Identifies extreme heat events (heatwaves) based on set temperature
  thresholds.

## See also

Useful links:

- <https://shawn-0303.github.io/castform/>

## Author

**Maintainer**: Shawn Yip <shawniceyip@trentu.ca>
