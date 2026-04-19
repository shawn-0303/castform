#' Pull Strings of Repeated Data
#'
#' Identifies when data values are repeated at least three times in a row.
#'
#' @param db_name Character: The name of the database
#' @param db_dir The directory of the database, If left unchanged, will default to package's default created directory "station_data".
#' @param output_dir The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#' @param output_name Character: The name of the output file. If left unfilled, the function will name the file "db_name_missingness_table.html"
#' @param write_csv Logical: If TRUE prints a csv copy of the results
#'
#' @return a `.html` output table and plot that stores the length of the repeat (in hours) as well as the start and end date/time. Large amounts of data mayt take longer to load and require users to zoom into the plot to see points.
#'
#' @export
pull_repeated_strings <- function(db_name = NULL, db_dir = "station_data", output_dir = "station_data", output_name = NULL, write_csv = FALSE) {
  db_name_clean <- gsub(" ", "_", toupper(db_name))
  output_name_clean <- gsub(" ", "_", toupper(output_name))

  db_path <- file.path(db_dir, paste0(db_name_clean, ".sqlite"))

  if (file.exists(db_path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
    on.exit(DBI::dbDisconnect(con))

    vars <- c("Temp_C", "Dew_Point_C", "Rel_Hum", "Precip_Amount", "Wind_Dir_deg",
              "Wind_Spd_kmh", "Visibility_km", "Stn_Press_kPa", "Hmdx", "Wind_Chill")

    all_streaks <- list()

    for (v in vars) {
      message("Finding repeated strings in ", v, "...")

      # This SQL script:
      # 1. Identifies if the current value is different from the previous row
      # 2. Creates a 'streak_id' that increments every time a value changes
      # 3. Groups by that ID to count the length
      sql_query <- paste0("
      WITH RankedData AS (
        SELECT
          Station_ID,
          Year || '-' || printf('%02d', Month) || '-' || printf('%02d', Day) || ' ' || Time_LST AS Timestamp,
          ", v, " AS Value,
          LAG(", v, ") OVER (PARTITION BY Station_ID ORDER BY Year, Month, Day, Time_LST) AS PrevValue
        FROM Observation
        WHERE ", v, " IS NOT NULL
      ),
      StreakGroups AS (
        SELECT *,
          SUM(CASE WHEN Value = PrevValue THEN 0 ELSE 1 END)
            OVER (PARTITION BY Station_ID ORDER BY Timestamp) AS StreakID
        FROM RankedData
      )
      SELECT
        Station_ID,
        '", v, "' AS Variable,
        Value AS Repeated_Value,
        COUNT(*) AS Streak_Length_Hours,
        MIN(Timestamp) AS Start_Time,
        MAX(Timestamp) AS End_Time
      FROM StreakGroups
      GROUP BY Station_ID, StreakID
      HAVING Streak_Length_Hours >= 3
    ")

      all_streaks[[v]] <- DBI::dbGetQuery(con, sql_query)
    }

    final_df <- all_streaks %>%
      purrr::keep(~nrow(.x) > 0) %>%
      dplyr::bind_rows()

    if(nrow(final_df) == 0) return(message("No streaks found."))

    stations <- DBI::dbGetQuery(con, "SELECT Station_ID, Station_Name FROM Station")
    final_df <- final_df %>%
      dplyr::left_join(stations, by = "Station_ID") %>%
      dplyr::select("Station Name" = Station_Name,
                    "Station ID" = Station_ID,
                    Variable,
                    "Repeated Value" = Repeated_Value,
                    "Length of Strek (Hours)" = Streak_Length_Hours,
                    "Streak Start Time" = Start_Time,
                    "Streak End Time" = End_Time)


    message("Formatting table...")
    table_title_name <- gsub("_", " ", toupper(db_name_clean))

    repeated_strings_table <- DT::datatable(final_df,
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
    htmlwidgets::saveWidget(repeated_strings_table, file = tmp_file, selfcontained = TRUE)

    file.copy(tmp_file, table_output_file, overwrite = TRUE)

    dep_dir <- gsub("\\.html$", "_files", table_output_file)
    if (dir.exists(dep_dir)) unlink(dep_dir, recursive = TRUE)

    message("Repeated strings table saved to: ", table_output_file)

    if (write_csv == TRUE) {
      message("Writing data to csv....")

      if (is.null(output_name)) {
        csv_output_file <- file.path(output_path, paste0(db_name_clean, "_repeated_strings_table.csv"))
      } else {
        csv_output_file <- file.path(output_path, paste0(output_name_clean, "_table.csv"))
      }

      write.csv(final_df, file = csv_output_file)
      message("Repeated strings csv saved to: ", csv_output_file)
    }

    message("Formatting plot...")

    shared_data <- crosstalk::SharedData$new(final_df)

    station_filter <- crosstalk::filter_select(
      id = "station_selector",
      label = "Select Station:",
      sharedData = shared_data,
      group = ~`Station Name`
    )

    # Gantt-style plot
    interactive_plot <- plotly::plot_ly(shared_data) %>%
      plotly::add_segments(
        x = ~as.POSIXct(`Streak Start Time`),      # 👈 Force to Date/Time object
        xend = ~as.POSIXct(`Streak End Time`),
        y = ~paste(`Station Name`, Variable),
        yend = ~paste(`Station Name`, Variable),
        color = ~Variable,
        line = list(width = 15)
      ) %>%
      plotly::layout(
        title = "Repeated String Timeline",
        xaxis = list(title = "Date",
                     tickformat = "%Y",
                     dtick = "M12"),
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

    return(interactive_plot)

  } else {
    message("Database not found. Please double check the entered database name, the database directory, and ensure the build_station_database function finished successfully.")
  }

}
