#' Get Multiple Station Files
#'
#' Downloads a multiple weather station files from Environment Canada
#'
#' @param station_name Character: The name of the weather station of interest.
#' @param station_id Numeric Integer: The unique station ID of the weather station of interest.
#' @param number_of_files Numeric Integer: The number of files the user wishes to download.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to the first year for data collection for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to January (1).
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#'
#' @importFrom future plan multisession sequential
#' @importFrom furrr future_pwalk furrr_options
#' @importFrom purrr pwalk
#'
#' @export
get_multiple_station_files <- function(station_name = NULL, station_id = NULL, number_of_files = NULL, year = NULL, month = NULL, parallel_threshold = 50) {

  # No station name or id provided
  if (is.null(station_name) && any(is.null(station_id)))
    stop("Provide station_name or station_id.")

  # No station name provided
  if (is.null(station_name) || any(is.na(station_name))) {
    station_matches <- HLY_station_info[HLY_station_info$Station.ID == station_id, ]
    if (nrow(station_matches) == 0) {
      message("Station ID ", station_id, " not found."); return(NULL)
    }
    station_name <- station_matches$stationName[1]

  } else {
    station_name <- toupper(gsub('"', '', station_name))
    station_matches <- HLY_station_info[toupper(HLY_station_info$stationName) == station_name, ]

    # No station id provided
    if (nrow(station_matches) == 0) {
      message("No station matching '", station_name, "'. Check spelling.");
      return(NULL)
    }
  }

  if (is.null(year) || is.na(year)) {
    year <- min(station_matches$HLY.First.Year, na.rm = TRUE)
    message(paste("No year provided. Starting from earliest records in", year))
  }

  # No month provided
  if (is.null(month) || is.na(month) || month < 1 || month > 12) {
    message("Invalid or missing month. Defaulting to January (1).")
    month <- 1
  }

  # Character month provided
  month_clean <- tolower(trimws(as.character(month)))

  if (month_clean %in% tolower(month.name)) {
    month <- match(month_clean, tolower(month.name))
  } else if (month_clean %in% tolower(month.abb)) {
    month <- match(month_clean, tolower(month.abb))
  }

  # No number of files provided
  if (is.null(number_of_files)) {
    message("Unspecified number of files. Defaulting to download 1 file.")
    number_of_files <- 1
  }

  # For spelling errors
  if (nrow(station_matches) == 0) {
    message(paste0("\nNo station matching '", station_name, ". Please check spelling."))
    return(NULL)
  }

  valid_matches <- station_matches[station_matches$HLY.First.Year <= year & station_matches$HLY.Last.Year >= year, ]

  # For years with no data
  if (nrow(valid_matches) == 0) {
    message(paste0("\nNo station matching '", station_name, "' was active in ", year, "."))
    message(paste("'", station_name, "' has hourly data for the following periods:"))
    print(station_matches[, c("stationName", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(NULL)

    # For stations with the same name
  } else if (nrow(valid_matches) > 1) {
    message("\nMultiple stations found. Please provide a Station ID:")
    print(valid_matches[, c("stationName", "Station.ID")], row.names = FALSE)
    return(NULL)

  } else {
    station_id <- valid_matches$Station.ID
    message(paste("Auto-filled unique Station ID:", station_id, "for", valid_matches$stationName))
  }

  total_months <- (year * 12) + (month - 1) + (0:(number_of_files - 1))
  task_list <- data.frame(
    yr = total_months %/% 12,
    mo = (total_months %% 12) + 1
  )

  if (number_of_files  >= parallel_threshold) {

    message(paste("Parallelization threshold met. Using ", 3, " cores to download ", number_of_files, "files"))

    plan(multisession, workers = 3)

    future_pwalk(task_list, function(yr, mo) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = yr,
                              month = mo,
                              root_folder = "station_data")
    }, .options = furrr_options(seed = TRUE))

    plan(sequential)

  } else {
    message(paste("Downloading ", number_of_files, " files sequentially."))

    pwalk(task_list, function(yr, mo) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = yr,
                              month = mo,
                              root_folder = "station_data")
    })
  }
}
