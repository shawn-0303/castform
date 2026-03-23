#' Download Station Metadata
#'
#' Download the latest station inventory list from Environment Canada. This will download the latest .csv file and needs to be loaded in FIRST to ensure the other functions have data to work with. This will automatically load the latest station inventory into the global environment as `HLY_Station_Info.` If past data file needs to be used, change the `HLY_station_info` parameter within each function.
#'
#' @export
get_metadata <- function() {
  current_date <- Sys.Date()

  csv_destination <- file.path("inst", "extdata",
                           paste0("station_inventory_", current_date, ".csv"))

  rda_destination <- file.path("data",
                               paste0("station_inventory_", current_date, ".rda"))

  working_file_destination <- file.path("data",
                                        paste0("HLY_station_info.rda"))


  if (!dir.exists("inst/extdata")) dir.create("inst/extdata", recursive = TRUE)
  if (!dir.exists("data")) dir.create("data", recursive = TRUE)

  url <- paste("https://collaboration.cmc.ec.gc.ca/cmc/climate/Get_More_Data_Plus_de_donnees/Station%20Inventory%20EN.csv")

  tryCatch({
    download.file(url, csv_destination, mode = "wb")

    station_metadata <- read.csv(csv_destination, skip = 3, fileEncoding = "latin1", check.names = FALSE)

    HLY_station_info <- station_metadata
    names(HLY_station_info)[names(HLY_station_info) == "Name"] <- "stationName"
    names(HLY_station_info)[names(HLY_station_info) == "Station ID"] <- "Station.ID"
    names(HLY_station_info)[names(HLY_station_info) == "HLY First Year"] <- "HLY.First.Year"
    names(HLY_station_info)[names(HLY_station_info) == "HLY Last Year"]  <- "HLY.Last.Year"

    HLY_station_info <- HLY_station_info[!is.na(HLY_station_info$HLY.First.Year) &
                                           !is.na(HLY_station_info$HLY.Last.Year), ]

    save(station_metadata, file = rda_destination)
    save(HLY_station_info, file = working_file_destination)
    message("Downloaded latest station inventory from Environment Canada. \nSaved at: ", rda_destination)

  }, error = function(e) {
    if (file.exists(csv_destination)) unlink(csv_destination)
    message("Download failed: ", e$message)
  })

  assign("HLY_station_info", HLY_station_info, envir = .GlobalEnv)
  message("Loaded into Global Environment")
}
