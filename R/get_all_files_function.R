#' Get All Files
#'
#' Downloads all Rnvironment Canada data from all stations with hourly data available.
#'
#' @export
get_all_files <- function( ) {
  input_file <- "HLY_station_info.csv"
  HLY_stations <- read.csv(system.file("data", "HLY_station_info.csv", package = "castform"))
  download_dir <- "all_station_data"

  for (i in seq_len(nrow(HLY_stations))) {
    row = HLY_stations[i,]
    station_id = row$Station.ID
    station_name = gsub(" ", "_", row$stationName)
    province = gsub(" ", "_", row$Province)
    begin_year = row$HLY.First.Year
    end_year = row$HLY.Last.Year

    # Ensure we only pull data from 1980-2020
    if (is.na(end_year) || end_year > 2020) end_year <- 2020
    if (begin_year < 1980) begin_year <- 1980

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
