#' Yearly Mean Plots
#'
#' Summarizes the average of each variable over time.
#'
#' @param db_name Character: The name of the database
#' @param db_dir Character: The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir Character: The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @return An `.html` output line plot visualizing the data.
#'
#' @export
plot_yearly_means <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data") {

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

    query_aggregates <- paste0("AVG(" , vars, ") AS avg_", vars,
                               collapse = ",\n  ")

    query_script <- paste0("SELECT Station_ID, Year, \n  ",
                           query_aggregates,
                           "\nFROM Observation
                           GROUP BY Station_ID, Year")

    message("Querying yearly averages...")
    query_results <- DBI::dbGetQuery(con, query_script)

    message("Reformatting raw data...")
    yearly_means <-query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      dplyr::mutate(Station_Name = as.factor(Station_Name),
                    Year = as.numeric(Year)) |>
      dplyr::group_by(Station_ID, Station_Name) |>
      tidyr::complete(Year = tidyr::full_seq(Year, 1)) |>
      dplyr::ungroup()

    yearly_means_long <- yearly_means |>
      tidyr::pivot_longer(cols = starts_with("avg_"),
                          names_to = "Variable",
                          values_to = "Average") |>
      dplyr::mutate(Variable = gsub("avg_", "", Variable))

    message("Building plot...")

    shared_data <- crosstalk::SharedData$new(yearly_means_long)

    station_filter <- crosstalk::filter_select(
      id = "station_selector",
      label = "Choose a Station:",
      sharedData = shared_data,
      group = ~Station_Name
    )

    interactive_plot <- plotly::plot_ly(shared_data,
                                        x = ~Year,
                                        y = ~Average,
                                        color = ~Variable,
                                        type = 'scatter',
                                        mode = 'lines+markers',
                                        connectgaps = FALSE) |>
      plotly::layout(
        title = list(text = paste(gsub("_", " ", db_name_clean), "Yearly Averages")),
        xaxis = list(title = "Year", tickformat = "d", dtick = 1),
        yaxis = list(title = "Average Value"),
        hovermode = "closest"
      ) |>
      plotly::toWebGL()

    final_html <- htmltools::tagList(
      htmltools::div(style = "margin-bottom: 20px;", station_filter),
      interactive_plot
    )

    output_file <- file.path(getwd(), output_dir, paste0(db_name_clean, "_yearly_means_plot.html"))

    message("Saving HTML plot...")
    htmltools::save_html(final_html, file = output_file)

    message("Yearly means plot saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}
