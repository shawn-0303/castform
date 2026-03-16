#' Get Single Station File
#'
#' Downloads a single weather station file from Environment Canada
#'
#' @param station_name Character: The name of the weather station of interest.
#' @param station_id Numeric Integer: The unique station ID of the weather station of interest.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to the first year for data collection for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to January (1).
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @export
get_single_station_file <- function(station_name = NULL, station_id = NULL, year = NULL, month = NULL, root_folder = "station_data") {

  if(!dir.exists(root_folder))
    dir.create(root_folder, recursive = TRUE)

  # No station name or id provided
  if (is.null(station_name) && is.null(station_id))
    stop("Provide a station_name or station_id.")

  if (is.null(station_name) || is.na(station_name)) {
    station_matches <- HLY_station_info[HLY_station_info$Station.ID == station_id, ]
    if (nrow(station_matches) == 0) {
      message("Station ID ", station_id, " not found.");
      return(NULL)
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

  # No year provided
  if (is.null(year) || is.na(year)) {
    year <- min(station_matches$HLY.First.Year, na.rm = TRUE)
    message("No year provided. Defaulting to earliest records: ", year)
  }

  # Character year provided
  if (is.character(year)) {
    message("Invalid input: 'year' must be a number.")
    return(NULL)
  }

  # No month provided
  if (is.null(month) || is.na(month)) {
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

  month <- as.numeric(month)

  # invalid month provided
  if (is.na(month) || month < 1 || month > 12) {
    message("Invalid or missing month. Defaulting to January (1).")
    month <- 1
  }

  # Filter by year activity
  valid_matches <- station_matches[station_matches$HLY.First.Year <= year & station_matches$HLY.Last.Year >= year, ]

  if (nrow(valid_matches) == 0) {
    message("\nNo station matching '", station_name, "' was active in ", year, ".")
    print(station_matches[, c("stationName", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(NULL)

  } else if (nrow(valid_matches) > 1 && is.null(station_id)) {
    message("\nMultiple stations found. Please provide a Station ID:")
    print(valid_matches[, c("stationName", "Station.ID", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(NULL)
  }

  # Finalize station ID
  if (is.null(station_id)) {
    station_id <- valid_matches$Station.ID[1]
    message("Auto-filled Station ID: ", station_id)
  }

  # Grab province for file path
  provinces <- gsub(" ", "_", toupper(valid_matches$Province[1]))

  file_station_name <- gsub(" ", "_", toupper(station_name))
  station_path  <- file.path(root_folder, provinces, paste0(file_station_name, "_", station_id), as.character(year))
  if (!dir.exists(station_path )) dir.create(station_path , recursive = TRUE)

  url <- paste0("https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv",
                "&stationID=", station_id,
                "&Year=", year,
                "&Month=", month,
                "&Day=14&timeframe=1")

  station_downloads <- file.path(station_path , paste0(file_station_name, "_", station_id, "_", year, "_", sprintf("%02d", month), ".csv"))

  if (httr::http_error(url)) {
    warning("URL does not exist or failed to build: ", url)
    return(FALSE)
  }

  tryCatch({
    download.file(url, station_downloads, mode = "wb")
    return(TRUE)
  }, error = function(e) {
    warning("Download failed for URL: ", url);
    return(FALSE)
  })
}











