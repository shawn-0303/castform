#' Station Look-Up
#'
#' Search for Canadian weather stations with hourly data by filtering by province and year range. Users can search through a single parameter or a combination of multiple.
#'
#' @param province Character. The Canadian province or territory of interest.
#' @param start_year Numeric Integer. The start year of the data pull.
#' @param end_year Numeric Integer. The end year of the data pull
#' @param HLY_station_info Dataframe: Station metadata
#'
#' @export
station_lookup <- function(province = NULL, start_year = NULL, end_year = NULL, HLY_station_info = NULL) {

  # No search parameters provided
  if (is.null(province) && is.null(start_year) && is.null(end_year)) {
    stop("Provide at least one station search parameter (province, start_year, or end_year).")
  }

  search_matches <- HLY_station_info

  # Province provided
  if (!is.null(province)) {
    province <- toupper(gsub('"', '', province))
    search_matches <- search_matches[search_matches$Province == province, ]
  }

  # Start year provided
  if (!is.null(start_year)) {
    if (!is.numeric(start_year)) stop("`start_year` must be numeric.")
    search_matches <- search_matches[search_matches$HLY.First.Year == start_year, ]
  }

  # End year provided
  if (!is.null(end_year)) {
    if (!is.numeric(end_year)) stop("`end_year` must be numeric.")
    search_matches <- search_matches[search_matches$HLY.Last.Year == end_year, ]
  }

  # No matches
  if (nrow(search_matches) == 0) {
    message("No matching stations found. Check spelling or try other parameters.")
    return(NULL)
  }

  message(paste("Found", nrow(search_matches), "station(s)."))
  return(search_matches[, c("stationName", "Station.ID", "Province", "HLY.First.Year", "HLY.Last.Year")])
}
