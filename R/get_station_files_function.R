#' Get Station Files
#'
#' Download Environment Canada weather data by station
#'
#' @param station_name Character: The name of the weather station of interest.
#' @param station_id Numeric Integer: The unique station ID of the weather station of interest.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to downloading all years with hourly data for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to downloading data for all months (1-12).
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param HLY_station_info Dataframe: Station metadata
#'
#' @export
get_station_files <- function(station_name = NULL, station_id = NULL, year = NULL, month = NULL, parallel_threshold = 50, root_folder = "station_data", HLY_station_info = NULL) {
  progressr::handlers(global = TRUE)
  progressr::handlers("progress")

  if(!dir.exists(root_folder))
    dir.create(root_folder, recursive = TRUE)

  # No metadata provided
  if (is.null(HLY_station_info)) {
    if (exists("HLY_station_info", envir = .GlobalEnv)) {
      HLY_station_info <- get("HLY_station_info", envir = .GlobalEnv)
    } else {
      stop("HLY_station_info not found. Please run get_metadata() first.")
    }
  }

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
      return(invisible(NULL))
    }
  }

  # No year provided
  if (is.null(year) || is.na(year)) {
    year_min <- min(station_matches$HLY.First.Year, na.rm = TRUE)
    year_max <- max(station_matches$HLY.Last.Year, na.rm = TRUE)
    year <- seq(year_min, year_max)
    message(sprintf("No year provided. Downloading all available records: %d to %d", year_min, year_max))
  }

  # Character year provided
  if (all(is.na(year))) {
    message("Invalid input: 'year' must be a number or a numeric string.")
    return(NULL)
  }

  if (is.null(month) || is.na(month)) {
    month <- 1:12
    message("No month provided. Downloading all months (1-12).")
  } else {
    # Existing month cleaning logic for single/specific months
    month_clean <- tolower(trimws(as.character(month)))
    if (month_clean %in% tolower(month.name)) {
      month <- match(month_clean, tolower(month.name))
    } else if (month_clean %in% tolower(month.abb)) {
      month <- match(month_clean, tolower(month.abb))
    }
    month <- as.numeric(month)
    if (any(is.na(month)) || any(month < 1) || any(month > 12)) {
      message("Invalid month input. Defaulting to January (1).")
      month <- 1
    }
  }

  valid_matches <- station_matches[station_matches$HLY.First.Year <= max(year) &
                                    station_matches$HLY.Last.Year >= min(year), ]

  if (nrow(valid_matches) == 0) {
    message("\nNo records found for '", station_name, "' during the requested years.")
    message(station_name, " was active during")
    print(station_matches[, c("stationName", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(invisible(NULL))
  }

    # For stations with the same name
  if (nrow(valid_matches) > 1 && is.null(station_id)) {
    message("\nMultiple stations found. Please provide a Station ID:")
    print(valid_matches[, c("stationName", "Station.ID", "HLY.First.Year", "HLY.Last.Year")], row.names = FALSE)
    return(invisible(NULL))
  }

  message(paste("Found files for ", station_name, ". Starting download..."))

  stations_to_download <- data.frame(station_name = valid_matches$stationName,
                                     station_id   = valid_matches$Station.ID)

  task_list <- tidyr::expand_grid(
    stations_to_download,
    year         = year,
    month        = month
  )

  total_files <- nrow(task_list)

  total_bytes <- total_files * 130000
  est_size_mb <- total_bytes / (1024 ^ 2)
  est_size_gb <- total_bytes / (1024 ^ 3)

  estimate_size <- if (est_size_gb >= 1) {
    paste0(round(est_size_gb, 2), " GB")
  } else {
    paste0(round(est_size_mb, 2), " MB")
  }

  if (total_files >= 50) {
    if (interactive()) {
      msg <- paste("You are about to download", total_files,
                   "files which will take up approximately", estimate_size,
                   ". Continue to download?")
      ans <- utils::askYesNo(msg)

      if (!isTRUE(ans)) {
        message("Download cancelled by user.")
        return(invisible(NULL))
      }
    }
  }

  progressr::with_progress({
    p <- progressr::progressor(steps = total_files)

    if (total_files > parallel_threshold) {

      message("Parallelization threshold met. Using ", 3, " cores to download ", total_files, " files.")

      future::plan(future::multisession, workers = 3)

      furrr::future_pwalk(task_list, function(station_name, station_id, year, month, ...) {
        p(sprintf("Downloading %s (%d-%02d)", station_name, year, month))

        get_single_station_file(station_name = station_name,
                                station_id = station_id,
                                year = year,
                                month = month,
                                root_folder = root_folder,
                                HLY_station_info = HLY_station_info)
      }, .options = furrr::furrr_options(seed = TRUE))

      future::plan(future::sequential)

    } else {
      message(paste("Downloading ", total_files, " files sequentially..."))

      purrr::pwalk(task_list, function(station_name, station_id, year, month, ...) {
        p(sprintf("Downloading %s (%d-%02d)", station_name, year, month))

        get_single_station_file(station_name = station_name,
                                station_id = station_id,
                                year = year,
                                month = month,
                                root_folder = root_folder,
                                HLY_station_info = HLY_station_info)
      })
    }
  })
  message("Download Complete.")
}

