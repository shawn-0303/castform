#' Data Ranges Table
#'
#' Identifies the data ranges from each station within a database.
#'
#' @param db_name Character: The name of the database
#' @param db_dir Character: The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir Character: The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param output_name Character: The name of the output file. If left unfilled, the function will name the file "db_name_missingness_table.html"
#' @param write_csv Logical: If TRUE prints a csv copy of the results
#'
#' @returns Creates a `.html` output table that stores the average, minimum, and maximum values for each variable.
#'
#' @export
data_ranges <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data", output_name = NULL, write_csv = FALSE) {
  db_name_clean <- gsub(" ", "_", toupper(db_name))
  output_name_clean <- gsub(" ", "_", toupper(output_name))

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

    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    data_range_table <- DT::datatable(data_range_long,
                                       caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                         paste0(table_title_name, " Data Ranges")),
                                       filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                       rownames = FALSE,
                                       extensions = 'Buttons',
                                       options = list(pageLength = 10,
                                                      dom = 'Bfrtip',
                                                      buttons = list(list(extend = 'copy', title = paste0(db_name_clean, "_Data_Ranges")),
                                                                     list(extend = 'csv', title = paste0(db_name_clean, "_Data_Ranges")),
                                                                     list(extend = 'pdf', title = paste0(db_name_clean, "_Data_Ranges")))))

    output_path <- file.path(getwd(), output_dir, paste0(db_name_clean, "_outputs"))
    if (!dir.exists(output_path )) dir.create(output_path , recursive = TRUE)

    if (is.null(output_name)) {
      output_file <- file.path(output_path, paste0(db_name_clean, "_data_ranges_table.html"))
    } else {
      output_file <- file.path(output_path, paste0(output_name_clean, ".html"))
    }
    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(data_range_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Data missingness table saved to: ", output_file)

    if (write_csv == TRUE) {
      message("Writing data to csv....")

      if (is.null(output_name)) {
        csv_output_file <- file.path(output_path, paste0(db_name_clean, "_data_ranges_table.csv"))
      } else {
        csv_output_file <- file.path(output_path, paste0(output_name_clean, "_table.csv"))
      }

      write.csv(data_range_long, file = csv_output_file)
      message("Repeated strings csv saved to: ", csv_output_file)
    }

    return(data_range_table)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}




