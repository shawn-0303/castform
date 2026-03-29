#' @keywords internal
#'
#' @description
#'  Downloads hourly weather station data (as csv files) from Environment Canada.
#'  This data is downloaded from: https://climate.weather.gc.ca/historical_data/search_historic_data_e.html
#'
#' @importFrom purrr pwalk
#' @importFrom furrr furrr_options
#' @importFrom furrr future_pwalk
#' @importFrom future multisession
#' @importFrom future plan
#' @importFrom future sequential
#' @importFrom httr http_error
#'
#' @section Metadata:
#' \itemize{
#'   \item \code{\link{get_metadata}}: Downloads and loads the latest station inventory metadata (RUN THIS FIRST)
#'   \item \code{\link{station_lookup}}: Search for available station data by province and year range.
#'   }
#'
#' @section Download Wrappers:
#' \itemize{
#'   \item \code{\link{get_single_station_file}}: The primary function to download one hourly data file.
#'   \item \code{\link{get_multiple_station_files}}: Downloads multiple hourly data files.
#'   \item \code{\link{get_station_files}}: Downloads data files by station
#'   \item \code{\link{province_station_files}}: Downloads data files by province.
#'   \item \code{\link{year_range_station_files}}: Downloads data files by year range.
#'   \item \code{\link{get_all_files}}: Downloads all data files with hourly data available.
#'   }
#'
#' @section Database Building:
#' \itemize{
#'   \item \code{\link{build_station_database}}: Creates a database using a folder of specified weather station data
#'   \item \code{\link{validate_database}}: Validates created database
#' }
#'
#' @section Exploratory Data Analysis:
#' \itemize{
#'   \item \code{\link{data_missingness_table}}: Creates a table summarizing actual, expected, and missing data counts
#'   \item \code{\link{data_ranges}}: Creates a table summarizing variable data ranges
#'   \item \code{\link{plot_yearly_means}}: Creates plots to summarize yearly variable means
#'   \item \code{\link{pull_missing_strings}}: Creates a table summarizing missing data gaps
#'   }
#'
#' @section Heatwave Detector:
#'
#' @name castform
#'
"_PACKAGE"

