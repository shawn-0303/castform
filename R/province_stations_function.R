#' Province Station Files
#'
#' Download Environment Canada weather station files by province.
#'
#' @param province Character: The province or territory of interest.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to downloading all years with hourly data for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to downloading data for all months (1-12).
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#' @param out_dir The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param HLY_station_info Dataframe: Station metadata
#'
#' @importFrom future plan multisession sequential
#' @importFrom furrr future_pwalk furrr_options
#' @importFrom purrr pwalk
#' @importFrom utils askYesNo
#' @importFrom utils download.file
#'
#' @export
province_station_files <- function(province = NULL, year = NULL, month = NULL, parallel_threshold = 50, out_dir = "station_data", HLY_station_info = NULL) {
  progressr::handlers(global = TRUE)
  progressr::handlers("progress")

  if(!dir.exists(out_dir))
    dir.create(out_dir, recursive = TRUE)

  # No metadata provided
  if (is.null(HLY_station_info)) {
    if (exists("HLY_station_info", envir = .GlobalEnv)) {
      HLY_station_info <- get("HLY_station_info", envir = .GlobalEnv)
    } else {
      stop("HLY_station_info not found. Please run get_metadata() first.")
    }
  }

  # No station name or id provided
  if (is.null(province) || is.na(province))
    stop("Provide a province or territory")

  province = toupper(gsub('"', '', province))

  # If province abbreviation provided
  province_lookup <- c("AB" = "ALBERTA", "BC" = "BRITISH COLUMBIA", "MB" = "MANITOBA",
                       "NB" = "NEW BRUNSWICK", "NL" = "NEWFOUNDLAND", "NS" = "NOVA SCOTIA",
                       "NT" = "NORTHWEST TERRITORIES", "NU" = "NUNAVUT", "ON" = "ONTARIO",
                       "PE" = "PRINCE EDWARD ISLAND", "QC" = "QUEBEC", "SK" = "SASKATCHEWAN",
                       "YT" = "YUKON")

  if (province %in% names(province_lookup)) {
    province <- province_lookup[province]
  } else {
    province <- province
  }

  province_subset <- HLY_station_info[HLY_station_info$Province == province, ]

  # Province misspelling
  if (nrow(province_subset) == 0) {
    message(paste("No stations found in ", province, "."))
    return(NULL)
  }

  # No year provided
  if (is.null(year) || is.na(year)) {
    year_min <- min(province_subset$HLY.First.Year, na.rm = TRUE)
    year_max <- max(province_subset$HLY.Last.Year, na.rm = TRUE)
    year_pull <- seq(year_min, year_max)
    message(sprintf("No year provided. Downloading all available records: %d to %d", year_min, year_max))
  } else {
    year_pull <- year
  }

  # Character year provided
  if (is.character(year)) {
    message("Invalid input: 'year' must be a number or a numeric string.")
    return(NULL)
  }

  # Month Clean Up
  if (is.null(month) || is.na(month)) {
    message("No month provided. Downloading all months (1-12).")
    month_pull <- 1:12
  } else {
    month_clean <- tolower(trimws(as.character(month)))
    if (month_clean %in% tolower(month.name)) {
      month_pull <- match(month_clean, tolower(month.name))
    } else if (month_clean %in% tolower(month.abb)) {
      month_pull <- match(month_clean, tolower(month.abb))
    } else {
      month_pull <- as.numeric(month)
    }
  }

  task_list <- tidyr::expand_grid(
    province_subset,
    year         = year_pull,
    month        = month_pull
  )

  task_list <- task_list[task_list$year >= task_list$HLY.First.Year &
                           task_list$year <= task_list$HLY.Last.Year, ]

  total_files <- nrow(task_list)

  if (total_files == 0) {
    message("No active stations found for the requested timeframe.")
    return(NULL)
  }

  file_province_name <- gsub(" ", "_", toupper(province))

  task_list$station_name <- task_list$stationName
  task_list$station_id   <- task_list$Station.ID

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
                              out_dir = out_dir,
                              HLY_station_info = HLY_station_info)
    }, .options = furrr_options(seed = TRUE))

    future::plan(future::sequential)

  } else {
    message(paste("Downloading ", total_files, " files sequentially..."))

    purrr::pwalk(task_list, function(station_name, station_id, year, month, ...) {
      p(sprintf("Downloading %s (%d-%02d)", station_name, year, month))

      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = year,
                              month = month,
                              out_dir = out_dir,
                              HLY_station_info = HLY_station_info)
    })
  }
})
  message("Download Complete.")
}
