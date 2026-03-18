library(testthat)

test_that("Test directory creation", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  if (dir.exists(temp_dir)) unlink(temp_dir, recursive = TRUE)

  # Test 1: should create new directory
  results <- year_range_station_files(station_name =  "discovery island",
                                      root_folder = temp_dir)

  expect_true(dir.exists(temp_dir))
})

test_that("Test station id and year inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should return error for no inputs
  expect_error(year_range_station_files(root_folder = temp_dir),
               "Provide station_name or station_id")

  # Test 2/3: should return a message and NULL if invalid station ID is provided
  expect_message({results <- year_range_station_files(station_id = 1234,
                                                      root_folder = temp_dir)
  expect_null(results)},
  "not found")

  # Test 4/5: should return message and NULL if invalid station name is provided
  expect_message({results <- year_range_station_files(station_name =  "discovery",
                                                      root_folder = temp_dir)
  expect_null(results)},
  "Check spelling")

  # Test 6: should return message and autofill station id
  expect_message({results <- year_range_station_files(station_name =  "discovery island",
                                                      root_folder = temp_dir)},
                 "Auto-filled unique Station ID")

  # Test 7: should match station id to station name
  results <- year_range_station_files(station_id = 27226,
                                     root_folder = temp_dir)
  expect_s3_class(results, "data.frame")
})

test_that("Test year inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should return message if no start_year was provided
  expect_message({results <- year_range_station_files(station_name =  "discovery island",
                                                      root_folder = temp_dir)},
                 "No start year provided.")

  # Test 2: should return message if no end_year was provided
  expect_message({results <- year_range_station_files(station_name =  "discovery island",
                                                      root_folder = temp_dir)},
                 "No end year provided.")

  # Test 3/4: should return message and NULL if character start_year was provided
  expect_message({results <- year_range_station_files(station_name =  "discovery island",
                                                      start_year = "1990",
                                                      root_folder = temp_dir)
  expect_null(results)},
  "Invalid input")

  # Test 5/6: should return message and NULL if invalid years were provided
  expect_message({results <- year_range_station_files(station_name =  "discovery island",
                                                      start_year = 1990,
                                                      root_folder = temp_dir)
  expect_null(results)},
  "No station matching")

  # Test 7/8: Should find multiple stations with the same staion id and return a message and NULL
  expect_message({results <- year_range_station_files(station_name =  "victoria harbour a",
                                                      start_year = 2015,
                                                      root_folder = temp_dir)
  expect_null(results)},
  "Multiple stations found")
})

test_that("Test user check-in NO", {
  mockery::stub(year_range_station_files,
                "utils::askYesNo", FALSE)

  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(
    get_single_station_file = function(...) {
      message("Mock download successful")
      invisible(NULL)
    },
    plan = function(...) NULL,
    interactive = function() TRUE,
    .package = "castform"
  )

  # Test 1: Should return NULL and message when large downloads are cancelled
  testthat::with_mocked_bindings(interactive = function() TRUE,
                                 code = {expect_message({results <- year_range_station_files(station_name = "discovery island",
                                                                                            start_year = 1997,
                                                                                            end_year = 2003,
                                                                                            root_folder = temp_dir)
                                 expect_null(results)},
                                 "Download cancelled by user.")})
})

test_that("Test parallelization", {

  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  mockery::stub(year_range_station_files, "utils::askYesNo", TRUE)

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
                                 code = {expect_message(year_range_station_files(station_name = "discovery island",
                                                                                 start_year = 1997,
                                                                                 end_year = 2003,
                                                                                 root_folder = temp_dir),
                                                        "Parallel download for")
                                 })
})
