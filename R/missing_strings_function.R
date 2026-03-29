#' Pull Strings of Missing Data
#'
#' Creates a `.html` output table identifying when data is missing from the database. Stores the length of the data gap (in hours) as well as the start and end date/time.
#'
#' @param db_name Character: The name of the database
#' @param db_dir The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @export
pull_missing_strings <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data") {
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

    query_script <- paste0("SELECT Station_ID, Year, Month, Day, Time_LST,
                            Temp_C, Dew_Point_C, Rel_Hum, Precip_Amount, Wind_Dir_deg,
                            Wind_Spd_kmh, Visibility_km, Stn_Press_kPa, Hmdx, Wind_Chill
                           FROM Observation")

    message("Querying data ranges...")
    query_results <- DBI::dbGetQuery(con, query_script)

    message("Finding missing strings...")
    data_range_long <- query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      tidyr::pivot_longer(cols = vars,
                          names_to = "Variable",
                          values_to = "Value") |>
      dplyr::mutate(Station_Name = as.factor(Station_Name),
                    Variable = as.factor(Variable)) |>
      dplyr::filter(is.na(Value)) |>
      dplyr::group_by(Station_ID, Variable) |>
      dplyr::mutate(time_val = lubridate::ymd_hm(paste(Year, Month, Day, Time_LST)),
                    diff = as.numeric(difftime(time_val, dplyr::lag(time_val), units = "hours")),
                    new_streak = dplyr::if_else(is.na(diff) | diff > 1, 1, 0),
                    streak_id = cumsum(new_streak)) |>
      dplyr::group_by(Station_Name, Station_ID, Variable, streak_id) |>
      dplyr::summarise("Streak Length (Hours)" =  dplyr::n(),
                      "Streak Start Time" = min(time_val),
                      "Streak End Time" = max(time_val),
                      .groups = "drop") |>
      dplyr::select(-streak_id)

    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    data_range_table <- DT::datatable(data_range_long,
                                      caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                        paste0(table_title_name, " Missing Strings")),
                                      filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                      rownames = FALSE,
                                      extensions = 'Buttons',
                                      options = list(pageLength = 10,
                                                     dom = 'Bfrtip',
                                                     buttons = list(list(extend = 'copy', title = paste0(db_name_clean, "_missing_strings")),
                                                                    list(extend = 'csv', title = paste0(db_name_clean, "_missing_strings")),
                                                                    list(extend = 'pdf', title = paste0(db_name_clean, "_missing_strings")))))

    output_file <- file.path(getwd(), output_dir, paste0(db_name_clean, "_missing_strings_table.html"))

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(data_range_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Missing strings table saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }

}
