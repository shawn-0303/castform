#' Province Station Files
#'
#' Download Environment Canada weather station files by province.
#'
#' @param province Character: The province or territory of interest.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to the first year for data collection for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to January (1).
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param HLY_station_info Dataframe: Station metadata
#'
#' @importFrom future plan multisession sequential
#' @importFrom furrr future_pwalk furrr_options
#' @importFrom purrr pwalk
#' @importFrom utils askYesNo
#' @importFrom utils download.file
#'
#' @export
province_station_files <- function(province = NULL, year = NULL, month = NULL, parallel_threshold = 50, root_folder = "station_data", HLY_station_info = NULL) {

  if(!dir.exists(root_folder))
    dir.create(root_folder, recursive = TRUE)

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
    year <- min(province_subset$HLY.First.Year, na.rm = TRUE)
    message("No year provided. Defaulting to earliest records: ", year)
  }

  # Character year provided
  if (is.character(year)) {
    message("Invalid input: 'year' must be a number or a numeric string.")
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

  province_matches <- HLY_station_info[HLY_station_info$Province == province &
                                         HLY_station_info$HLY.First.Year <= year &
                                         HLY_station_info$HLY.Last.Year >= year, ]

  province_station_count <- nrow(province_matches)
  if (province_station_count == 0) {
    message(paste("No active hourly stations found in", province, "for the year", year))
    return(NULL)
  }

  message(paste("Found", province_station_count, "stations in", province, ". Starting download..."))

  stations_to_download <- data.frame(station_name = province_matches$stationName,
                                     station_id   = province_matches$Station.ID)

  task_list <- tidyr::expand_grid(
    stations_to_download,
    month        = month
  )

  total_files <- nrow(task_list)
  file_province_name <- gsub(" ", "_", toupper(province))

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

  if (total_files > parallel_threshold) {

    message("Parallelization threshold met. Using ", 3, " cores to download ", total_files, " files.")

    plan(multisession, workers = 3)

    future_pwalk(task_list, function(station_name, station_id, month, ...) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = year,
                              month = month,
                              root_folder = root_folder,
                              HLY_station_info = HLY_station_info)
    }, .options = furrr_options(seed = TRUE))

    plan(sequential)

  } else {
    message(paste("Downloading ", total_files, " files sequentially..."))

    pwalk(task_list, function(station_name, station_id, month, ...) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = year,
                              month = month,
                              root_folder = root_folder,
                              HLY_station_info = HLY_station_info)
    })
  }
}
