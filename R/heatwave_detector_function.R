#' Detect Extreme Heat Events (Heatwaves)
#'
#' Scans the downloaded data to detect extreme heat events. If no temperature thresholds are provided, will use Environment Canada's definition of an extreme heat event (https://www.canada.ca/en/environment-climate-change/services/environmental-indicators/extreme-heat-events.html)
#'
#' @param db_name Character: The name of the database
#' @param max_threshold Numeric: Maximum temperature threshold for an extreme heat event
#' @param min_threshold Numeric: Minimum temperature threshold for an extreme heat event
#' @param db_dir Character: The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir Character: The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param write_csv Logical: If TRUE prints a csv copy of the results
#'
#' @return Produces a `.html` table and plot output summarizing average daily temperatures and flags extreme heat events based on user input thresholds.
#'
#' @export
heatwave_detector <- function(db_name = NULL, max_threshold = NULL, min_threshold = NULL, db_dir = "station_data", output_dir = "station_data", write_csv = FALSE) {
  db_name_clean <- gsub(" ", "_", toupper(db_name))

  db_path <- file.path(db_dir, paste0(db_name_clean, ".sqlite"))

  if (file.exists(db_path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
    on.exit(DBI::dbDisconnect(con))

    stations_in_database <- DBI::dbGetQuery(con,
                                            "SELECT DISTINCT Station_Name, Station_ID
                                       FROM Station
                                       ORDER BY rowid")

    query_script <- "SELECT Station_ID, Year, Month, Day,
                          AVG(Temp_C) as avg_daily_temp,
                          MIN(Temp_C) as min_daily_temp,
                          MAX(Temp_C) as max_daily_temp
                          FROM Observation
                          WHERE Temp_C IS NOT NULL
                          GROUP BY  Station_ID, Year, Month, Day"

    message("Querying yearly averages...")
    query_results <- DBI::dbGetQuery(con, query_script)

    if (is.null(max_threshold) || is.null(min_threshold)) {

      # Run the helper function
      message("No provided temperature thresholds. Finding matching climate region...")
      climate_region_data <- .climate_regions_stations(stationID = unique(query_results$Station_ID))

      if (!is.null(climate_region_data)) {
        if (is.null(max_threshold)) max_threshold <- climate_region_data$max
        if (is.null(min_threshold)) min_threshold <- climate_region_data$min
      }
    } else {
      message("Using user-provided thresholds: Max ", max_threshold, " / Min ", min_threshold)
    }

    heatwave <- query_results |>
      dplyr::left_join(stations_in_database, by = c("Station_ID")) |>
      dplyr::mutate(Station_Name = as.factor(Station_Name)) |>
      dplyr::group_by(Station_ID) |>
      dplyr::mutate(Date = lubridate::make_date(Year, Month, Day),
             crosses_heat_threshold = ifelse(max_daily_temp >= max_threshold &
                                             min_daily_temp >= min_threshold, 1, 0),
             heat_wave = ifelse(crosses_heat_threshold == 1 &
                                (dplyr::lag(crosses_heat_threshold) == 1 |
                                   dplyr::lead(crosses_heat_threshold) == 1), 1, 0)) |>
      dplyr::select(`Station Name` = Station_Name,
                    `Station ID` = Station_ID,
                    Date,
                    `Average Daily Temperature` = avg_daily_temp,
                    `Minimum Daily Temperature` = min_daily_temp,
                    `Maximum Daily Temperature` = max_daily_temp,
                    `Cross Heat Threshold?` = crosses_heat_threshold,
                    `Heatwave Indicator` = heat_wave)

    message("Formatting table...")
    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    heatwave_table <- DT::datatable(heatwave,
                                    caption = htmltools::tags$caption(style = 'caption-side: top; text-align: center; color:black; font-size:250%;',
                                                                        paste0(table_title_name, " Extreme Heat Detector")),
                                    filter = list(position = 'top', clear = FALSE, plain = TRUE),
                                    rownames = FALSE,
                                    extensions = 'Buttons',
                                    options = list(pageLength = 10,
                                                     dom = 'Bfrtip',
                                                     buttons = list(list(extend = 'copy', title = paste0(db_name_clean, "_heatwave_detector")),
                                                                    list(extend = 'csv', title = paste0(db_name_clean, "_heatwave_detector")),
                                                                    list(extend = 'pdf', title = paste0(db_name_clean, "_heatwave_detector")))))

    output_path <- file.path(getwd(), output_dir, paste0(db_name_clean, "_outputs"))
    if (!dir.exists(output_path )) dir.create(output_path , recursive = TRUE)

    table_output_file <- file.path(output_path, paste0(db_name_clean, "_heatwave_table.html"))

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(heatwave_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, table_output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", table_output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Heatwave table saved to: ", table_output_file)

    if (write_csv == TRUE) {
      message("Writing data to csv....")

      csv_output_file <- file.path(output_path, paste0(db_name_clean, "_heatwave_table.csv"))
      write.csv(heatwave, file = csv_output_file)

      message("Heatwave csv saved to: ", csv_output_file)
    }

    message("Building plot...")

    heatwave_sorted <- heatwave |> dplyr::arrange(Date)

    shared_data <- crosstalk::SharedData$new(heatwave_sorted)

    station_filter <- crosstalk::filter_select(
      id = "station_selector",
      label = "Choose a Station:",
      sharedData = shared_data,
      group = ~`Station Name`
    )

    interactive_plot <- plotly::plot_ly(shared_data,
                                        x = ~Date) |>
      plotly::add_bars(y = ~ifelse(`Heatwave Indicator` == 1, 65, 0),
                       base = -30,
                       width = 86400000,
                       marker = list(color = 'red',
                                     alpha = 0.8,
                                     line = list(width = 0)),
                       name = "Heatwave Event",
                       hoverinfo = "none") |>
      plotly::add_lines(y = ~`Average Daily Temperature`,
                        type = 'scattergl',
                        mode = 'lines',
                        line = list(color = 'blue', width = 1),
                        name = "Daily Temperature Average") |>
      plotly::layout(
        title = list(text = paste(gsub("_", " ", db_name_clean), "Daily Temperature Averages (with Extreme Heat Events)")),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Average Daily Temperature"),
        hovermode = "closest"
      ) |>
      plotly::toWebGL()

    final_html <- htmltools::tagList(
      htmltools::div(style = "margin-bottom: 20px;", station_filter),
      interactive_plot
    )

    output_file <- file.path(output_path, paste0(db_name_clean, "_heatwave_plot.html"))

    message("Saving HTML plot...")
    htmltools::save_html(final_html, file = output_file)

    message("Heatwaves plot saved to: ", output_file)

    return(interactive_plot)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}





