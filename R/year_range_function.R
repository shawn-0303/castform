#' Download Stations by Year Range
#'
#' Downloads a multiple weather station files collected between a specified time period from Environment Canada
#'
#' @param station_name Character: The name of the weather station of interest.
#' @param station_id Numeric Integer: The unique station ID of the weather station of interest.
#' @param start_year Numeric Integer: The start year of the data pull. If left empty, will default to the first year for data collection for that particular station.
#' @param end_year Numeric Integer: The end year of the data pull. If left empty, it will default to only downloading one year of data from the start_year
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#'
#' @importFrom future plan multisession sequential
#' @importFrom furrr future_pwalk furrr_options
#' @importFrom purrr pwalk
#'
#' @export
year_range_station_files <- function(station_name = NULL, station_id = NULL, start_year = NULL, end_year = NULL, parallel_threshold = 50, root_folder = "station_data") {

  if(!dir.exists(root_folder))
    dir.create(root_folder, recursive = TRUE)

  # No station name or id provided
  if (is.null(station_name) && is.null(station_id)) {
    stop("Provide station_name or station_id.")
  }

  # No station name provided
  if (is.null(station_name) || is.na(station_name)) {
    match_index <- HLY_station_info[HLY_station_info$Station.ID == station_id, ]
    if (nrow(match_index) == 0) {
      message("Station ID ", station_id, " not found."); return(NULL)
    }
    station_name <- match_index$stationName[1]

  } else {
    station_name <- toupper(gsub('"', '', station_name))
    match_index <- HLY_station_info[toupper(HLY_station_info$stationName) == station_name, ]

    # No station id provided
    if (nrow(match_index) == 0) {
      message("No station matching '", station_name, "'. Check spelling.");
      return(NULL)
    }
  }

  # No start year provided
  if (is.null(start_year) || is.na(start_year)) {
    start_year <- min(match_index$HLY.First.Year, na.rm = TRUE)
    message("No start year provided. Defaulting to earliest records: ", start_year)
  }

  # No end year provided
  if (is.null(end_year) || is.na(end_year)) {
    message("No end year provided. Defaulting to download a single year")
    end_year <- start_year
  }

  # Character year provided
  if (is.character(start_year) || is.character(end_year)) {
    message("Invalid input: 'start_year' and `end_year` must be a number.")
    return(NULL)
  }

  valid_range <- match_index[match_index$HLY.First.Year <= start_year & match_index$HLY.Last.Year >= end_year, ]

  # For years with no data
  if (nrow(valid_range) == 0) {
    message(paste0("\nNo station matching '", station_name, "' was active between ", start_year, " and ", end_year, "."))
    message(paste("'", station_name, "' has hourly data for the following periods:"))
    print(match_index[, c("stationName", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(NULL)

    # For stations with the same name
  } else if (nrow(valid_range) > 1) {
    message("\nMultiple stations found. Please provide a Station ID:")
    print(valid_range[, c("stationName", "Station.ID")], row.names = FALSE)
    return(NULL)

  } else {
    station_id <- valid_range$Station.ID
    message(paste("Auto-filled unique Station ID:", station_id, "for", valid_range$stationName))
  }

  task_list <- tidyr::expand_grid(
    yr = start_year:end_year,
    mo = 1:12
  )
  total_files <- nrow(task_list)

  if (total_files >= 50) {
    if (interactive()) {
      msg <- paste("You are about to download ", total_files, " files. Continue to download?")
      ans <- utils::askYesNo(msg)

      if (!isTRUE(ans)) {
        message("Download cancelled by user.")
        return(invisible(NULL))
      }
    }
  }

  file_station_name <- gsub(" ", "_", toupper(station_name))

  message(paste("Starting download for", station_name, "from", start_year, "to", end_year))

  if (total_files > parallel_threshold) {

    plan(multisession, workers = 3)
    message("Parallel download for ", total_files, " files.")

    future_pwalk(task_list, function(yr, mo) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = yr,
                              month = mo,
                              root_folder = root_folder)
    }, .options = furrr_options(seed = TRUE))

    plan(sequential)

  } else {
    message(paste("Downloading ", total_files, " files sequentially."))

    pwalk(task_list, function(yr, mo) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = yr,
                              month = mo,
                              root_folder = root_folder)
    })
  }
}
