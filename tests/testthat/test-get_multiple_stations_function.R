library(testthat)

test_that("Test station id and year inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should return error for no inputs
  expect_error(get_multiple_station_files(root_folder = temp_dir),
               "Provide station_name or station_id")

  # Test 2/3: should return a message and NULL if invalid station ID is provided
  expect_message({results <- get_multiple_station_files(station_id = 1234,
                                                        root_folder = temp_dir)
  expect_null(results)},
  "not found")

  # Test 4/5: should return message and NULL if invalid station name is provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery",
                                                        root_folder = temp_dir)
  expect_null(results)},
  "Check spelling")

  # Test 6: should return message and autofill station id
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1997,
                                                        month = 1,
                                                        root_folder = temp_dir)},
                 "Auto-filled unique Station ID")
})

test_that("Test year inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should return message if no year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        root_folder = temp_dir)},
                 "No year provided.")

  # Test 2/3: should return message and NULL if character year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = "1990",
                                                        root_folder = temp_dir)
  expect_null(results)},
  "Invalid input")

  # Test 4/5: should return message and NULL if invalid year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1990,
                                                        root_folder = temp_dir)
  expect_null(results)},
  "No station matching")
})

test_that("Test month inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

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
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
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
  expect_s3_class(get_multiple_station_files(station_name =  "discovery island",
                                             month = "January",
                                             year = 1997,
                                             root_folder = temp_dir), "data.frame")

  expect_s3_class(get_multiple_station_files(station_name =  "discovery island",
                                             month = "Feb",
                                             year = 1997,
                                             root_folder = temp_dir), "data.frame")

  expect_s3_class(get_multiple_station_files(station_name =  "discovery island",
                                             month = "Feb",
                                             year = 1997,
                                             root_folder = temp_dir), "data.frame")

})

test_that("Test station matching", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should be a successful match
  expect_s3_class(results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1997,
                                                        month = 1,
                                                        root_folder = temp_dir), "data.frame")

  # Test 2/3: should not be a successful match (NULL and message expected)
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1234,
                                                        month = 1,
                                                        root_folder = temp_dir)
  expect_null(results)},
  "was active in 1234")

  # Test 4/5: Should find multiple stations with the same staion id and return a message and NULL
  expect_message({results <- get_multiple_station_files(station_name =  "victoria harbour a",
                                                        year = 2015,
                                                        month = 1,
                                                        root_folder = temp_dir)
  expect_null(results)},
  "Multiple stations found")

  # Test 6: Should return a valid data frame
  expect_s3_class(results <- get_multiple_station_files(station_id = 27226,
                                                        year = 1997,
                                                        month = 1,
                                                        root_folder = temp_dir), "data.frame")
})

test_that("Test parallelization", {

  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  mockery::stub(get_multiple_station_files, "utils::askYesNo", TRUE)

  testthat::local_mocked_bindings(
    get_single_station_file = function(...) {
      message("Mock download successful")
      invisible(NULL)
    },
    plan = function(...) NULL,
    interactive = function() TRUE,
    .package = "castform"
  )

  # Test 1: should produce a message when parallelization threshold is met
  testthat::with_mocked_bindings(interactive = function() TRUE,
                                 code = {expect_message(get_multiple_station_files(station_name = "discovery island",
                                                                                   year = 1997,
                                                                                   month = 1,
                                                                                   number_of_files = 51,
                                                                                   root_folder = temp_dir),
                                                        "Parallelization threshold met")
                                 })
})

