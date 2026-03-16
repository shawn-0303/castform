library(testthat)

test_that("Test station id and year inputs", {
  temp_dir <- tempfile("test_data")

  # Test 1: should return error for no inputs
  expect_error(
    get_single_station_file(),
    "Provide a station_name or station_id"
  )

  # Test 2/3: should return a message and NULL if invalid station ID is provided
  expect_message({results <- get_single_station_file(station_id = 1234,
                                                     root_folder = temp_dir)
  expect_null(results)},
  "not found")

  # Test 4/5: should return message and NULL if invalid station name is provided
  expect_message({results <- get_single_station_file(station_name =  "discovery",
                                                     root_folder = temp_dir)
  expect_null(results)},
  "Check spelling.")

  # Test 6: should return message and autofill station id
  expect_message({results <- get_single_station_file(station_name =  "discovery island",
                                                     year = 1997,
                                                     month = "1",
                                                     root_folder = temp_dir)},
  "Auto-filled Station ID")

  # Test 7: should match station id to station name
  results <- get_single_station_file(station_id = 27226,
                                     year = 1997,
                                     month = "1",
                                     root_folder = temp_dir)
  expect_true(results)
})

test_that("Test year inputs", {
  temp_dir <- tempfile("test_data")

  # Test 1: should return message if no year was provided
  expect_message({results <- get_single_station_file(station_name =  "discovery island",
                                                     root_folder = temp_dir)},
                 "No year provided.")

  # Test 2/3: should return message and NULL if character year was provided
  expect_message({results <- get_single_station_file(station_name =  "discovery island",
                                                     year = "1997",
                                                     root_folder = temp_dir)
  expect_null(results)},
  "Invalid input")
})

test_that("Test month inputs", {
  temp_dir <- tempfile("test_data")

  test_month <- function(m) {
    if (is.null(m) || is.na(m))
      m <- 1

    month_clean <- tolower(trimws(as.character(m)))

    if (month_clean %in% tolower(month.name)) {
      m <- match(month_clean, tolower(month.name))
    } else if (month_clean %in% tolower(month.abb)) {
      m <- match(month_clean, tolower(month.abb))
    }

    m <- as.numeric(m)
    if (is.na(m) || m < 1 || m > 12) m <- 1
    return(m)
  }

  # Test 1: should return message if no month was provided
  expect_message({results <- get_single_station_file(station_name =  "discovery island",
                                                     month = "month",
                                                     year = 1997,
                                                     root_folder = temp_dir)},
                 "Invalid or missing month")

  # Test 2: should convert "January" to 1
  expect_equal(test_month("January"), 1)

  # Test 3:  should convert "feb" to 2
  expect_equal(test_month("  feb  "), 2)

  # Test 4: should convert "10" to 10
  expect_equal(test_month("10"), 10)

  # Test 5: should convert NULL to 1
  expect_equal(test_month(NULL), 1)

  # Test 6: should convert "month" to 1
  expect_equal(test_month("month"), 1)

  # Test 7: should convert -1 to 1
  expect_equal(test_month(-1), 1)

  # Test 8: should convert 13 to 1
  expect_equal(test_month(13), 1)

  # Test 9-11: should return true
  expect_true(get_single_station_file(station_name =  "discovery island",
                                      month = "January",
                                      year = 1997,
                                      root_folder = temp_dir))

  expect_true(get_single_station_file(station_name =  "discovery island",
                                      month = "Feb",
                                      year = 1997,
                                      root_folder = temp_dir))

  expect_true(get_single_station_file(station_name =  "discovery island",
                                      month = "Feb",
                                      year = 1997,
                                      root_folder = temp_dir))

})

test_that("Test station matching", {
  temp_dir <- tempfile("test_data")

  # Test 1: should be a successful match
  expect_true({results <- get_single_station_file(station_name =  "discovery island",
                                                  year = 1997,
                                                  month = 1,
                                                  root_folder = temp_dir)})

  # Test 2/3: should not be a successful match (NULL and message expected)
  expect_message({results <- get_single_station_file(station_name =  "discovery island",
                                                     year = 1234,
                                                     month = 1,
                                                     root_folder = temp_dir)
  expect_null(results)},
  "was active in 1234")

  # Test 4/5: Should find multiple stations with the same staion id and return a message and NULL
  expect_message({results <- get_single_station_file(station_name =  "victoria harbour a",
                                                     year = 2015,
                                                     month = 1,
                                                     root_folder = temp_dir)
  expect_null(results)},
  "Multiple stations found")
})

test_that("Test file path, URL creation, and download", {
  temp_dir <- tempfile("test_data")

  # Test 1: should be a valid result
  valid_result <- get_single_station_file(station_name = "discovery island",
                                          year = 1997,
                                          station_id = 27226,
                                          month = "1",
                                          root_folder = temp_dir)

  expect_true(valid_result)

  # Test 2: should create the expected file path
  expected_path <- file.path(temp_dir, "BRITISH_COLUMBIA", "DISCOVERY_ISLAND_27226", "1997")
  expect_true(dir.exists(expected_path))

  # Test 3: should download the expected file
  expected_file <- file.path(expected_path, "DISCOVERY_ISLAND_27226_1997_01.csv")
  expect_true(file.exists(expected_file))

  # Test 4: should return warning after checking for non-existent URL
  mockery::stub(get_single_station_file, "httr::http_error", TRUE)
  expect_warning(get_single_station_file(station_id = 27226), "URL does not exist")

  # Test 5: Should return warning after file download fails.
  mockery::stub(get_single_station_file, "httr::http_error", FALSE)
  mockery::stub(get_single_station_file, "download.file", function(...) stop("Network Down"))
  expect_warning(get_single_station_file(station_id = 27226), "Download failed")
    }
  )
