#' @keywords internal
#'
#' @importFrom purrr pwalk
#' @importFrom furrr furrr_options
#' @importFrom furrr future_pwalk
#' @importFrom future multisession
#' @importFrom future plan
#' @importFrom future sequential
#'
#' @section Main functions:
#' \itemize{
#'   \item \code{\link{get_single_station_file}}: The primary function to download one hourly data file.
#'   \item \code{\link{get_multiple_station_files}}: Downloads multiple hourly data files.
#'   \item \code{\link{province_station_files}}: Downloads data files by province.
#'   \item \code{\link{year_range_station_files}}: Downloads data files by year range.
#'   \item \code{\link{get_all_files}}: Downloads all data files with hourly data available.
#' }
#'
#' @name castform
#'
"_PACKAGE"

