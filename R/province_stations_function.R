#' Province Station Files
#'
#' Download Environment Canada weather station files by province.
#'
#' @param province Character: The province or territory of interest.
#' @param year Numeric Integer: The year of the data pull. If left empty, will default to the first year for data collection for that particular station.
#' @param month Numeric Integer: The month of the data pull (1 - 12). If left empty, will default to January (1).
#' @param parallel_threshold Numeric Integer: The required number of files to trigger parallel downloads. If left unchanged, parallelization will occur for downloads of 50 files or more.
#'
#' @importFrom future plan multisession sequential
#' @importFrom furrr future_pwalk furrr_options
#' @importFrom purrr pwalk
#'
#' @export
province_station_files <- function(province, year = NULL, month = NULL, parallel_threshold = 50) {

  province = toupper(gsub('"', '', province))
  download_months = if(is.null(month)) 1:12 else month

  HLY_stations <- read.csv(system.file("data", "HLY_station_info.csv", package = "castform"))
  province_subset <- HLY_stations[HLY_stations$Province == province, ]

  if (nrow(province_subset) == 0) {
    message(paste("No stations found in ", province, "."))
    return(NULL)
  }

  if (is.null(year) || is.na(year)) {
    year <- min(province_subset$HLY.First.Year, na.rm = TRUE)
    message("No year provided. Defaulting to earliest records: ", year)
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

  province_matches <- HLY_stations[HLY_stations$Province == province &
                                     HLY_stations$HLY.First.Year <= year &
                                     HLY_stations$HLY.Last.Year >= year, ]

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
    month        = download_months
  )

  total_files <- nrow(task_list)
  file_province_name <- gsub(" ", "_", toupper(province))

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

  if (total_files > parallel_threshold) {
    plan(multisession, workers = 3)

    message("Parallelization threshold met. Using ", 3, " cores to download ", total_files, " files.")

    future_pwalk(task_list, function(station_name, station_id, month) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = year,
                              month = month,
                              root_folder = "station_data")
    }, .options = furrr_options(seed = TRUE))

    plan(sequential)

  } else {
    message("Downloading ", total_files, " files sequentially...")

    pwalk(task_list, function(station_name, station_id, month) {
      get_single_station_file(station_name = station_name,
                              station_id = station_id,
                              year = year,
                              month = month,
                              root_folder = "station_data")
    })
  }
}
