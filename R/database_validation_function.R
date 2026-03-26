#' Validate Created Database
#'
#' Used to validate databases created by `build_station_database`. This function will check for tables created within the database, count the number of records within each table, and print the first five observation records.
#'
#' @param db_name Character: The name of the database
#' @param db_dir The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#'
#' @export
validate_database <- function(db_name = NULL, db_dir = "station_data") {

 db_path <- file.path(db_dir, paste0(db_name, ".sqlite"))

 if (file.exists(db_path)) {
   con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
   on.exit(DBI::dbDisconnect(con))

   tbl_list <- DBI::dbListTables(con)
   message(paste0("Database contains tables: ", paste(tbl_list, collapse = ", ")))

   message("Printing table summaries:")

   for (tbl in tbl_list) {
     tbl_obs_count <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", tbl))$n
     cat(sprintf("Table: %-12s | Number of Records: %d\n", tbl, tbl_obs_count))
     }

   message("Previewing the first five observations")

   first_five_obs <- DBI::dbGetQuery(con, "SELECT * FROM Observation LIMIT 5;")
   if (nrow(first_five_obs) == 0) {
     message("No observations stored in table. Please double check your download and database creation parameters")
   } else {
     first_five_obs
   }

   first_five_obs

 } else {
   message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
 }
}
