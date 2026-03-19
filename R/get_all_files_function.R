#' Get All Hourly Station Files
#'
#' Downloads all Environment Canada data from all stations with hourly data available.
#'
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @importFrom utils download.file
#'
#' @export
get_all_files <- function(root_folder = "station_data") {

  total_files_overall <- 0
  for (i in seq_len(nrow(HLY_station_info))) {
    row <- HLY_station_info[i,]
    begin_year <- max(1980, row$HLY.First.Year, na.rm = TRUE)
    end_year <- min(2020, row$HLY.Last.Year, na.rm = TRUE)
    if (begin_year <= end_year) {
      total_files_overall <- total_files_overall + ((end_year - begin_year + 1) * 12)
    }
  }

  if (interactive() && total_files_overall > 0) {
    msg <- paste0("You are about to download up to ", total_files_overall, " hourly files. Continue?")
    ans <- utils::askYesNo(msg)
    if (!isTRUE(ans)) {
      message("Download cancelled by user.")
      return(invisible(NULL))
    }
  }

  for (i in seq_len(nrow(HLY_station_info))) {
    row = HLY_station_info[i,]
    station_id = row$Station.ID
    station_name = gsub(" ", "_", row$stationName)
    province = gsub(" ", "_", row$Province)
    begin_year = row$HLY.First.Year
    end_year = row$HLY.Last.Year

    # Ensure we only pull data from 1980-2020
    if (is.na(begin_year) || begin_year  < 1980) begin_year <- 1980
    if (is.na(end_year) || end_year > 2020) end_year <- 2020

    if (begin_year > end_year) next

    # Create download directory if one doesn't exist
    station_downloads <- file.path(root_folder, province, paste0(station_name, "_", station_id), begin_year)
    if (!dir.exists(station_downloads)) dir.create(station_downloads, recursive = TRUE)

    for (year in begin_year:end_year) {
      for (month in 1:12) {

        url <- paste0("https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv",
                      "&stationID=", station_id,
                      "&Year=", year,
                      "&Month=", sprintf("%02d", month),
                      "&Day=14&timeframe=1")

        destination <- file.path(station_downloads, paste0(station_name, "_", station_id, "_", year, "_", sprintf("%02d", month), ".csv"))

        tryCatch({
          download.file(url, destination, mode = "wb")
          # if download fails, return the file that failed and remove the partial file.
        }, error = function(e) {
          if (file.exists(destination)) unlink(destination)
          message("Download failed. Skipped: ", year, "-", month, " for ", station_name, ".")
        })
      }
    }
  }
  message("Download Complete.")
}




