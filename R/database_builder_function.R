build_station_database <- function(db_name = NULL, root_folder = "station_data") {

  if (is.null(db_name) || is.na(db_name))
    stop("Please provided a database name")

  files <- list.files(root_folder, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)

  if (length(files) == 0)
    stop("No .csv files found in the root folder. Cannot make database.")

  message(paste0("Importing ", length(files) ," files into ", paste0(db_name, ".sqlite")))

  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = paste0(db_name, ".sqlite"))
  on.exit(DBI::dbDisconnect(con))

  purrr::walk(files, function(r) {
    station_data <- read.csv(r)

    DBI::dbWriteTable(con, "hourly_station_data", station_data, append = TRUE)
    })

  message(paste0("Database build complete. Data stored in ", paste0(db_name, ".sqlite")))
}
