#' Get All Files
#'
#' Downloads all Environment Canada data from all stations with hourly data available.
#'
#' @export
get_all_files <- function( ) {
  download_dir <- "all_station_data"

  global_task_list <- tidyr::expand_grid(HLY_station_info,
                                         year = 1980:2020,
                                         month = 1:12) %>%
    dplyr::filter(year >= HLY.First.Year,
                  year <= HLY.Last.Year)

  total_files_overall <- nrow(global_task_list)

  for (i in seq_len(nrow(HLY_station_info))) {
    row = HLY_station_info[i,]
    station_id = row$Station.ID
    station_name = gsub(" ", "_", row$stationName)
    province = gsub(" ", "_", row$Province)
    begin_year = row$HLY.First.Year
    end_year = row$HLY.Last.Year

    # Ensure we only pull data from 1980-2020
    if (is.na(end_year) || end_year > 2020) end_year <- 2020
    if (is.na(begin_year) || begin_year  < 1980) begin_year <- 1980

    if (begin_year > end_year) next

    if (total_files_overall >= 50 && interactive()) {
      msg <- paste0("You are about to download ", total_files_overall, " files in total. Continue?")
      ans <- utils::askYesNo(msg)
      if (!isTRUE(ans)) {
        message("Download cancelled by user.")
        return(invisible(NULL))
      }
    }

    # Create download directory if one doesn't exist
    station_downloads <- file.path(download_dir, province, paste0(station_name, "_", station_id))
    if (!dir.exists(station_downloads)) dir.create(station_downloads, recursive = TRUE)

    for (year in begin_year:end_year) {
      for (month in 1:12) {

        url <- paste0("https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv",
                      "&stationID=", station_id,
                      "&Year=", year,
                      "&Month=", sprintf("%02d", month),
                      "&Day=14&timeframe=1")

        destination <- file.path(station_downloads, paste0(station_name, "_", station_id, "_", year, "_", sprintf("%02d", month), ".csv"))

        download.file(url, destination, mode = "wb")
      }
    }
  }
}
