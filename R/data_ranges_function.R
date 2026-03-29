data_ranges <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data") {

  db_path <- file.path(db_dir, paste0(db_name, ".sqlite"))

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

    query_aggregates <- paste0("MIN(", vars, ") AS min_", vars, ",",
                               "MAX(", vars, ") AS max_", vars, ",",
                               "AVG(" , vars, ") AS avg_", vars,
                               collapse = ",\n  ")

    query_script <- paste0("SELECT Station_ID, \n  ",
                           query_aggregates,
                           "\nFROM Observation
                           GROUP BY Station_ID")

    message("Querying data ranges...")
    query_results <- DBI::dbGetQuery(con, query_script)

    message("Reformatting raw data...")
    data_range_long <- query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      dplyr::mutate(Station_Name = as.factor(Station_Name)) |>
      dplyr::relocate(Station_Name, .before = Station_ID) |>
      tidyr::pivot_longer(cols = starts_with(c("min_", "max_", "avg_")),
                          names_to = c(".value", "Variable"),
                          names_pattern = "(min|max|avg)_(.*)") |>
      dplyr::select(`Station Name` = Station_Name,
                    `Station ID` = Station_ID,
                    Variable,
                    `Average` = avg,
                    `Minimum Value` = min,
                    `Maximum Value` = max)

    data_range_table <- DT::datatable(data_range_long,
                                       caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                         paste0(db_name, " Data Ranges")),
                                       filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                       rownames = FALSE,
                                       extensions = 'Buttons',
                                       options = list(pageLength = 10,
                                                      dom = 'Bfrtip',
                                                      buttons = list(list(extend = 'copy', title = paste0(db_name, "_Data_Ranges")),
                                                                     list(extend = 'csv', title = paste0(db_name, "_Data_Ranges")),
                                                                     list(extend = 'pdf', title = paste0(db_name, "_Data_Ranges")))))

    output_file <- file.path(getwd(), output_dir, paste0(db_name, "_data_range_table.html"))

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(data_range_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Data missingness table saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}




