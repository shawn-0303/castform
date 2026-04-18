#' Pull Strings of Repeated Data
#'
#' Identifies when data values are repeated at least three times in a row.
#'
#' @param db_name Character: The name of the database
#' @param db_dir The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param output_name Character: The name of the output file. If left unfilled, the function will name the file "db_name_missingness_table.html"
#'
#' @return a `.html` output table and plot that stores the length of the repeat (in hours) as well as the start and end date/time. Large amounts of data mayt take longer to load and require users to zoom into the plot to see points.
#'
#' @export
pull_repeated_strings <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data", output_name = NULL) {
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

    query_script <- paste0("SELECT Station_ID, Year, Month, Day, Time_LST,
                            Temp_C, Dew_Point_C, Rel_Hum, Precip_Amount, Wind_Dir_deg,
                            Wind_Spd_kmh, Visibility_km, Stn_Press_kPa, Hmdx, Wind_Chill
                           FROM Observation")

    message("Querying data ranges...")
    query_results <- DBI::dbGetQuery(con, query_script)

    message("Finding repeated strings...")
    data_range_long <- query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      tidyr::pivot_longer(cols = vars,
                          names_to = "Variable",
                          values_to = "Value") |>
      dplyr::mutate(Station_Name = as.factor(Station_Name),
                    Variable = as.factor(Variable)) |>
      dplyr::filter(!is.na(Value)) |>
      dplyr::group_by(Station_ID, Variable) |>
      dplyr::mutate(time_val = lubridate::ymd_hm(paste(Year, Month, Day, Time_LST)),
                    val_change = Value != dplyr::lag(Value),
                    time_diff = as.numeric(difftime(time_val, dplyr::lag(time_val), units = "hours")) > 1,
                    new_streak = dplyr::if_else(is.na(val_change) | val_change | time_diff, 1, 0),
                    streak_id = cumsum(new_streak)) |>
      dplyr::group_by(Station_Name, Station_ID, Variable, Value, streak_id) |>
      dplyr::summarise(Streak_Length_Hours  =  dplyr::n(),
                       Start_Time  = min(time_val),
                       End_Time = max(time_val),
                       .groups = "drop") |>
      dplyr::filter(Streak_Length_Hours >= 3) |>
      dplyr::select("Station Name" = Station_Name,
                    "Station ID" = Station_ID,
                    Variable,
                    "Repeated Value" = Value,
                    "Streak Length (Hours)" = Streak_Length_Hours,
                    "Streak Start Time" = Start_Time,
                    "Streak End Time" = End_Time)


    message("Formatting table...")
    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    data_range_table <- DT::datatable(data_range_long,
                                      caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                        paste0(table_title_name, " Repeated Strings")),
                                      filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                      rownames = FALSE,
                                      extensions = 'Buttons',
                                      options = list(pageLength = 10,
                                                     dom = 'Bfrtip',
                                                     buttons = list(list(extend = 'copy', title = paste0(db_name_clean, "_repeated_strings")),
                                                                    list(extend = 'csv', title = paste0(db_name_clean, "_repeated_strings")),
                                                                    list(extend = 'pdf', title = paste0(db_name_clean, "_repeated_strings")))))

    output_path <- file.path(getwd(), output_dir, paste0(db_name_clean, "_outputs"))
    if (!dir.exists(output_path )) dir.create(output_path , recursive = TRUE)

    if (is.null(output_name)) {
      table_output_file <- file.path(output_path, paste0(db_name_clean, "_repeated_strings_table.html"))
    } else {
      table_output_file <- file.path(output_path, paste0(output_name_clean, "_table.html"))
    }

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(data_range_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, table_output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", table_output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Repeated strings table saved to: ", table_output_file)

    message("Formatting plot...")

    shared_data <- crosstalk::SharedData$new(data_range_long)

    station_filter <- crosstalk::filter_select(
      id = "station_selector",
      label = "Select Station:",
      sharedData = shared_data,
      group = ~`Station Name`
    )

    # Gantt-style plot
    interactive_plot <- plotly::plot_ly(shared_data) %>%
      plotly::add_segments(
        x = ~`Streak Start Time`,
        xend = ~`Streak End Time`,
        y = ~paste(`Station Name`, Variable),
        yend = ~paste(`Station Name`, Variable),
        color = ~Variable,
        line = list(width = 15)
      ) %>%
      plotly::layout(
        title = "Repeated String Timeline",
        xaxis = list(title = "Date"),
        yaxis = list(title = ""),
        margin = list(l = 150)
      )

    # Bundle them together
    final_content <- htmltools::tagList(
      htmltools::div(style = "margin-bottom: 20px;", station_filter),
      interactive_plot
    )

    if (is.null(output_name)) {
      plot_output_file <- file.path(output_path, paste0(db_name_clean, "_repeated_strings_plot.html"))
    } else {
      plot_output_file <- file.path(output_path, paste0(output_name_clean, "_plot.html"))
    }

    message("Saving HTML plot...")

    # Use save_html instead of saveWidget to avoid the 'symbol/0' error
    # This correctly handles tag lists (filter + plot)
    htmltools::save_html(final_content, file = plot_output_file)

    message("Repeated strings plot saved to: ", plot_output_file)

  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }

}
