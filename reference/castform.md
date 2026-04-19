# castform: Download Environment Canada Weather Station Data

Downloads hourly weather station data (as csv files) from Environment
Canada. This data is downloaded from:
https://climate.weather.gc.ca/historical_data/search_historic_data_e.html

## Metadata

- [`get_metadata`](get_metadata.md): Downloads and loads the latest
  station inventory metadata (RUN THIS FIRST)

- [`station_lookup`](station_lookup.md): Search for available station
  data by province and year range.

## Download Wrappers

- [`get_single_station_file`](get_single_station_file.md): The primary
  function to download one hourly data file.

- [`get_multiple_station_files`](get_multiple_station_files.md):
  Downloads multiple hourly data files.

- [`get_station_files`](get_station_files.md): Downloads data files by
  station

- [`province_station_files`](province_station_files.md): Downloads data
  files by province.

- [`year_range_station_files`](year_range_station_files.md): Downloads
  data files by year range.

- [`get_all_files`](get_all_files.md): Downloads all data files with
  hourly data available.

## Database Building

- [`build_station_database`](build_station_database.md): Creates a
  database using a folder of specified weather station data

- [`validate_database`](validate_database.md): Validates created
  database

## Exploratory Data Analysis

- [`station_map`](station_map.md): Creates a map visualizing stations of
  interest

- [`data_missingness_table`](data_missingness_table.md): Creates a table
  summarizing actual, expected, and missing data counts

- [`data_ranges`](data_ranges.md): Creates a table summarizing variable
  data ranges

- [`plot_yearly_means`](plot_yearly_means.md): Creates plots to
  summarize yearly variable means

- [`pull_missing_strings`](pull_missing_strings.md): Creates a plot and
  table summarizing missing data gaps

- [`pull_repeated_strings`](pull_repeated_strings.md): Creates a plot
  and table summarizing repeated data strings

## Heatwave Detector

- [`heatwave_detector`](heatwave_detector.md): Identifies extreme heat
  events (heatwaves) based on set temperature thresholds.

## See also

Useful links:

- <https://shawn-0303.github.io/castform/>

## Author

**Maintainer**: Shawn Yip <shawniceyip@trentu.ca>
