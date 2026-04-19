#' Plot Stations on Map
#'
#' Allows for users to plot all metadata stations or selected stations on a map of Canada.
#'
#' @param db_name Character: The name of the database
#' @param db_dir Character: The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir Character: The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param output_name Character: The chosen name of the output `png` object.
#' @param metadata_stations Logical: Plot all stations in the metadata (default = FALSE)
#'
#' @returns A `.png` of the created map
#'
#' @export
station_map <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data", output_name = NULL, metadata_stations = FALSE) {
  db_name_clean <- if (!is.null(db_name)) gsub(" ", "_", toupper(db_name)) else "NULL"
  output_name_clean <- if (!is.null(output_name)) gsub(" ", "_", toupper(output_name)) else paste0(db_name_clean, "_STATION_MAP")

  output_path <- file.path(getwd(), output_dir, paste0(db_name_clean, "_outputs"))
  if (!dir.exists(output_path )) dir.create(output_path , recursive = TRUE)

  output_file <- file.path(output_path, paste0(output_name_clean, ".png"))

  db_path <- file.path(db_dir, paste0(db_name_clean, ".sqlite"))

  if (metadata_stations == TRUE) {
    if (exists("HLY_station_info", envir = .GlobalEnv)) {
      HLY_station_info <- get("HLY_station_info", envir = .GlobalEnv)
    } else {
      stop("HLY_station_info not found. Please run get_metadata() first.")
    }

    message("Mapping metadata stations...")
    metadata_station_env <- .mapping(input_df = HLY_station_info, file_path = output_file)

    message("Metadata station map successfully saved to: ", output_file)
  }

  else if (file.exists(db_path) && metadata_stations == FALSE) {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
    on.exit(DBI::dbDisconnect(con))

    message("Querying stations in database...")
    observation_stations <- DBI::dbGetQuery(con,
                                            "SELECT DISTINCT Longitude, Latitude
                                            FROM Observation")

    if (nrow(observation_stations) == 0) {
      message("No station data found in the database Observation table.")
      return(NULL)
    }

    message("Mapping metadata stations...")
    observation_station_env <- .mapping(input_df = observation_stations, file_path = output_file)

    message("Observation station map successfully saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }

}
