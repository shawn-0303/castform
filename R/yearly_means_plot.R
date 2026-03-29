#' Yearly Mean Plots
#'
#' Creates `.html` output plots that summarize the average of each variable over time.
#'
#' @param db_name Character: The name of the database
#' @param db_dir The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
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

    plot_base <- plotly::plot_ly(yearly_means_long,
                                 x = ~Year,
                                 y = ~Average,
                                 color = ~Variable,
                                 split = ~Station_ID,
                                 name = ~Variable,
                                 customdata = ~Station_ID,
                                 type = 'scatter',
                                 mode = 'lines+markers',
                                 connectgaps = FALSE)

    built_plot <- plotly::plotly_build(plot_base)
    all_traces <- built_plot$x$data
    trace_ids <- sapply(all_traces, function(x) x$customdata[1])

    stn_lookup <- yearly_means %>%
      dplyr::distinct(Station_ID, Station_Name) %>%
      dplyr::mutate(Station_ID = as.character(Station_ID))

    buttons <- lapply(1:nrow(stn_lookup), function(i) {
      id <- stn_lookup$Station_ID[i]
      nm <- stn_lookup$Station_Name[i]
      vis_vector <- trace_ids == id

      list(method = "update",
           args = list(list(visible = vis_vector),
                       list(title = list(text = paste("Yearly Weather Averages:", nm, " (Station ID: ", id, ")")))),
           label = nm)
    })

    year_limits <- range(yearly_means_long$Year, na.rm = TRUE)

    # Update the plot
    plot <- plot_base |>
      plotly::layout(xaxis = list(
        title = "Year",
        range = year_limits,
        tickformat =  "d",
        dtick = 1),
        updatemenus = list(
          list(buttons = buttons,
               direction = "down",
               showactive = TRUE))) |>
      plotly::style(visible = (trace_ids == stn_lookup$Station_ID[1])) |>
      plotly::toWebGL()

    output_file <- file.path(getwd(), output_dir, paste0(db_name_clean, "_yearly_means_plot.html"))

    tmp_dir <- tempdir()
    tmp_file <- file.path(tmp_dir, "temp_table.html")

    message("Saving self-contained HTML table...")
    htmlwidgets::saveWidget(plot, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Yearly means plot saved to: ", output_file)
  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }
}
