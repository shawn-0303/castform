#' Data Missingness Table
#'
#' Identifies data missingness from each station within a database.
#'
#' @param db_name Character: The name of the database
#' @param db_dir Character: The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir Character: The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @return An `.html` output table that stores the expected, account, and percent missing counts for each variable.
#'
#' @export
data_missingness_table <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data") {
  db_name_clean <- gsub(" ", "_", toupper(db_name))

  db_path <- file.path(db_dir, paste0(db_name_clean, ".sqlite"))

  if (file.exists(db_path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
    on.exit(DBI::dbDisconnect(con))

    message("Querying stations in database...")
    stations_in_database <- DBI::dbGetQuery(con,
                                       "SELECT DISTINCT Station_Name, Station_ID
                                       FROM Station
                                       ORDER BY rowid")

    vars <- c("Temp_C", "Dew_Point_C", "Rel_Hum", "Precip_Amount", "Wind_Dir_deg",
              "Wind_Spd_kmh", "Visibility_km", "Stn_Press_kPa", "Hmdx", "Wind_Chill")

    query_aggregates <- paste0("COUNT(", vars, ") AS actual_", vars,
                              collapse = ",\n  ")

    query_script <- paste0("SELECT Station_ID,
                           COUNT(*) AS expected_total, \n  ",
                           query_aggregates,
                           "\nFROM Observation
                           GROUP BY Station_ID")

    message("Querying data missingness...")
    query_results <- DBI::dbGetQuery(con, query_script)

    message("Reformatting raw data...")
    missingness_long <- query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      dplyr::mutate(Station_Name = as.factor(Station_Name)) |>
      dplyr::relocate(Station_Name, .before = Station_ID) |>
      tidyr::pivot_longer(cols = starts_with("actual_"),
                          names_to = "Variable",
                          values_to = "actual",
                          names_prefix = "actual_") |>
      dplyr::mutate(`Percent Missing` = (1.0 - (actual / expected_total)) * 100) |>
      dplyr::select(`Station Name` = Station_Name,
                    `Station ID` = Station_ID,
                     Variable,
                    `Expected Number of Observations` = expected_total,
                    `Actual Number of Observations` = actual,
                    `Percent Missing`)

    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    missingness_table <- DT::datatable(missingness_long,
                                      caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                        paste0(table_title_name, " Data Missingness")),
                                      filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                      rownames = FALSE,
                                      extensions = 'Buttons',
                                      options = list(pageLength = 10,
                                                     dom = 'Bfrtip',
                                                     buttons = list(list(extend = 'copy', title = paste0(db_name_clean, "_Data_Missingness")),
                                                                    list(extend = 'csv', title = paste0(db_name_clean, "_Data_Missingness")),
                                                                    list(extend = 'pdf', title = paste0(db_name_clean, "_Data_Missingness")))))

    output_file <- file.path(getwd(), output_dir, paste0(db_name_clean, "_missingness_table.html"))

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(missingness_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Data missingness table saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}
