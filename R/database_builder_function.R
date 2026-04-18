#' Create Station Databases
#'
#' Creates a database using a folder of specified weather station data. This will automatically create three tables. A Station information table using HLY_station_info, a Weather table to look up weather conditions and their associated numeric code, and an Observation table made using downloaded station data (.csv) files.
#'
#' @param db_name Character: The name of the database
#' @param HLY_station_info Station metadata
#' @param output_dir The created output directory of the database. If left unchanged, will store the database within the default root_folder
#' @param root_folder The created download folder and file path. If left unchanged, will create a new "station_data" folder in the working directory.
#'
#' @export
build_station_database <- function(db_name = NULL, HLY_station_info = NULL, output_dir = "station_data", root_folder = "station_data") {
  progressr::handlers(global = TRUE)
  progressr::handlers("progress")

  # No metadata provided
  if (is.null(HLY_station_info)) {
    if (exists("HLY_station_info", envir = .GlobalEnv)) {
      HLY_station_info <- get("HLY_station_info", envir = .GlobalEnv)
    } else {
      stop("HLY_station_info not found. Please run get_metadata() first.")
    }
  }

  if (is.null(db_name) || is.na(db_name))
    stop("Please provided a database name")

  db_name_clean <- gsub(" ", "_", toupper(db_name))

  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  db_path <- file.path(output_dir, paste0(db_name_clean, ".sqlite"))
  if (file.exists(db_path)) file.remove(db_path)

  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = db_path)
  DBI::dbExecute(con, "PRAGMA foreign_keys = ON;")
  on.exit(DBI::dbDisconnect(con))

  DBI::dbExecute(con, "
  CREATE TABLE Station (
    Climate_ID TEXT PRIMARY KEY,
    Station_ID INTEGER UNIQUE,
    Station_Name TEXT,
    Province_Name TEXT,
    Latitude REAL,
    Longitude REAL,
    Elevation REAL,
    HLY_First_Year INTEGER,
    HLY_Last_Year INTEGER
  );
")

  DBI::dbExecute(con, "
  CREATE TABLE Weather (
    Weather_ID INTEGER PRIMARY KEY,
    Weather_Condition TEXT UNIQUE
  );
")

  DBI::dbExecute(con, "
  CREATE TABLE Observation(
    Longitude REAL,
    Latitude REAL,
    Station_ID INTEGER,
    Year INTEGER,
    Month INTEGER,
    Day INTEGER,
    Time_LST TEXT,
    Temp_C REAL,
    Dew_Point_C REAL,
    Rel_Hum REAL,
    Precip_Amount REAL,
    Wind_Dir_deg REAL,
    Wind_Spd_kmh REAL,
    Visibility_km REAL,
    Stn_Press_kPa REAL,
    Hmdx REAL,
    Wind_Chill REAL,
    Weather INTEGER,
    PRIMARY KEY (Station_ID, Year, Month, Day, Time_LST),
    FOREIGN KEY (Station_ID) REFERENCES Station(Station_ID)
  );
")

  conditions <-  c(
    "Blowing Dust","Blowing Sand","Blowing Snow",
    "Clear","Cloudy" ,
    "Drizzle","Dust",
    "Fog","Freezing Drizzle", "Freezing Fog","Freezing Rain","Funnel Cloud",
    "Hail","Haze","Heavy Drizzle","Heavy Freezing Drizzle","Heavy Freezing Rain",
    "Heavy Hail","Heavy Ice Pellet Showers", "Heavy Ice Pellets","Heavy Rain",
    "Heavy Rain Showers","Heavy Snow","Heavy Snow Grains","Heavy Snow Pellets",
    "Heavy Snow Showers","Heavy Thunderstorms",
    "Ice Crystals","Ice Fog","Ice Pellet Showers","Ice Pellets",
    "Mainly Clear","Moderate Drizzle","Moderate Freezing Drizzle",
    "Moderate Freezing Rain","Moderate Hail","Moderate Ice Pellet Showers",
    "Moderate Ice Pellets","Moderate Rain","Moderate Rain Showers",
    "Moderate Snow","Moderate Snow Grains","Moderate Snow Pellets",
    "Moderate Snow Showers","Mostly Cloudy",
    "Rain","Rain Showers" ,
    "Smoke","Snow","Snow Grains","Snow Pellets","Snow Showers",
    "Thunderstorms","Tornado")

  weather_lookup_df <- tibble::tibble(Weather_ID = seq_along(sort(unique(conditions))),
                                      Weather_Condition = sort(unique(conditions)))

  weather <- setNames(weather_lookup_df$Weather_ID,
                      weather_lookup_df$Weather_Condition)

  station_info <- HLY_station_info
  station_table <- station_info|>
    dplyr::mutate(Province_Name = dplyr::case_when(
                                          toupper(Province) == "AB" ~ "Alberta",
                                          toupper(Province) == "BC" ~ "British Columbia",
                                          toupper(Province) == "MB" ~ "Manitoba",
                                          toupper(Province) == "NB" ~ "New Brunswick",
                                          toupper(Province) == "NL" ~ "Newfoundland",
                                          toupper(Province) == "NS" ~ "Nova Scotia",
                                          toupper(Province) == "NT" ~ "Northwest Territories",
                                          toupper(Province) == "NU" ~ "Nunavut",
                                          toupper(Province) == "ON" ~ "Ontario",
                                          toupper(Province) == "PE" ~ "Prince Edward Island",
                                          toupper(Province) == "QC" ~ "Quebec",
                                          toupper(Province) == "SK" ~ "Saskatchewan",
                                          toupper(Province) == "YT" ~ "Yukon Territory",
                                          TRUE ~ Province
                                        )) |>
    dplyr::select(Climate_ID = Climate.ID,
                   Station_ID = Station.ID,
                   Station_Name = stationName,
                   Province_Name,
                   Latitude,
                   Longitude,
                   Elevation = Elevation..m.,
                   HLY_First_Year = HLY.First.Year,
                   HLY_Last_Year = HLY.Last.Year)

  DBI::dbWriteTable(con, "Station", station_table, append = TRUE)
  DBI::dbWriteTable(con, "Weather", weather_lookup_df, append = TRUE)


  files <- list.files(root_folder, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
  valid_ids <- station_table$Station_ID

  progressr::with_progress({
    p <- progressr::progressor(steps = length(files))

    purrr::walk(files, function(f) {
      # Extract ID from filename to skip non-indexed stations
      s_id <- as.integer(stringr::str_extract(basename(f), "(?<=_)[0-9]+(?=_)"))
      if (!(s_id %in% valid_ids)) { p(); return(NULL) }

      df <- read.csv(f)
      if (nrow(df) == 0) { p(); return(NULL) }

      df_clean <- df |>
        dplyr::select(Longitude      = Longitude..x.,
                      Latitude        = Latitude..y.,
                      Climate_ID      = Climate.ID,
                      Year            = Year,
                      Month           = Month,
                      Day             = Day,
                      Time_LST        = Time..LST.,
                      Temp_C          = Temp...C.,
                      Dew_Point_C     = Dew.Point.Temp...C.,
                      Rel_Hum         = Rel.Hum....,
                      Precip_Amount   = any_of("Precip..Amount..mm."),
                      Wind_Dir_deg    = Wind.Dir..10s.deg.,
                      Wind_Spd_kmh    = Wind.Spd..km.h.,
                      Visibility_km   = Visibility..km.,
                      Stn_Press_kPa   = Stn.Press..kPa.,
                      Hmdx            = Hmdx,
                      Wind_Chill      = Wind.Chill,
                      Weather         = Weather)

      if (!"Precip_Amount" %in% names(df_clean)) {df_clean$Precip_Amount <- NA_real_  }

      df_clean <- df_clean |>
        dplyr::mutate(
          Station_ID = s_id,
          Weather = as.numeric(weather[as.character(Weather)]),
          dplyr::across(where(is.character) & !dplyr::any_of(c("Climate_ID", "Time_LST")), as.numeric)
        ) |>
        dplyr::select(-Climate_ID)

      DBI::dbWriteTable(con, "Observation", df_clean, append = TRUE)
      p()
    })
  })
  message(paste0("Database build complete. Data stored in ", paste0(db_name_clean, ".sqlite")))
}


