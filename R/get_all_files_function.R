#' Get All Hourly Station Files
#'
#' Downloads all Environment Canada data from all stations with hourly data available.
#'
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param HLY_station_info Dataframe: Station metadata
#'
#' @importFrom utils download.file
#'
#' @export
get_all_files <- function(root_folder = "station_data", HLY_station_info = NULL) {
  progressr::handlers(global = TRUE)
  progressr::handlers("progress")

  # No metadata provided
  if (is.null(HLY_station_info)) {
    if (exists("HLY_station_info", envir = .GlobalEnv)) {
      HLY_station_info <- get("HLY_station_info", envir = .GlobalEnv)
    } else {
      stop("HLY_station_info not found. Please run get_metadata() first.")
    }
  }

  total_files_overall <- 0
  for (i in seq_len(nrow(HLY_station_info))) {
    row <- HLY_station_info[i,]
    begin_year <- max(1980, row$HLY.First.Year, na.rm = TRUE)
    end_year <- min(2020, row$HLY.Last.Year, na.rm = TRUE)
    if (begin_year <= end_year) {
      total_files_overall <- total_files_overall + ((end_year - begin_year + 1) * 12)
    }
  }

  if (total_files_overall == 0)
    return(message("No files found to download."))

  total_bytes <- total_files_overall * 130000
  est_size_mb <- total_bytes / (1024 ^ 2)
  est_size_gb <- total_bytes / (1024 ^ 3)

  estimate_size <- if (est_size_gb >= 1) {
    paste0(round(est_size_gb, 2), " GB")
  } else {
    paste0(round(est_size_mb, 2), " MB")
  }

  if (interactive() && total_files_overall > 0) {
    msg <- paste0("You are about to download ", total_files_overall,
                  " files which will take up approximately ", estimate_size,
                  " Continue to download?")
    ans <- utils::askYesNo(msg)
    if (!isTRUE(ans)) {
      message("Download cancelled by user.")
      return(invisible(NULL))
    }
  }

  progressr::with_progress({
    p <- progressr::progressor(steps = total_files_overall)

    for (i in seq_len(nrow(HLY_station_info))) {
      row = HLY_station_info[i,]
      station_id = row$Station.ID
      station_name = gsub(" ", "_", row$stationName)
      province = gsub(" ", "_", row$Province)
      begin_year <- max(1980, row$HLY.First.Year, na.rm = TRUE)
      end_year <- min(2020, row$HLY.Last.Year, na.rm = TRUE)

    # Ensure we only pull data from 1980-2020
      if (is.na(begin_year) || begin_year  < 1980) begin_year <- 1980
      if (is.na(end_year) || end_year > 2020) end_year <- 2020

      if (begin_year > end_year) next

    # Create download directory if one doesn't exist
      station_downloads <- file.path(root_folder, province, paste0(station_name, "_", station_id), begin_year)
      if (!dir.exists(station_downloads)) dir.create(station_downloads, recursive = TRUE)

      for (year in begin_year:end_year) {

        for (month in 1:12) {

          p(message = sprintf("Downloading %s (%d-%02d)", station_name, year, month))
          if (interactive()) flush.console()

        url <- paste0("https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv",
                      "&stationID=", station_id,
                      "&Year=", year,
                      "&Month=", sprintf("%02d", month),
                      "&Day=14&timeframe=1")

        destination <- file.path(station_downloads, paste0(station_name, "_", station_id, "_", year, "_", sprintf("%02d", month), ".csv"))

        tryCatch({
          download.file(url, destination, mode = "wb", quiet = TRUE)
          # if download fails, return the file that failed and remove the partial file.
        }, error = function(e) {
          if (file.exists(destination)) unlink(destination)
          message("Download failed. Skipped: ", year, "-", month, " for ", station_name, ".")
        })
      }
    }
  }
})
  message("Download Complete.")
}




