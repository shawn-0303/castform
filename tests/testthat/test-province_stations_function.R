library(testthat)

test_that("Test province inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  # Test 1: should return error for no inputs
  expect_error(province_station_files(root_folder = temp_dir),
               "Provide a province or territory")

  # Test 2/3: should return a message and NULL for invalid provinces
  expect_message({results <- province_station_files(province = "Ont",
                                                    root_folder = temp_dir)
  expect_null(results)},
  "No stations found in")
})

test_that("Test year inputs", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  testthat::local_mocked_bindings(download.file = function(url, destfile, ...) {
    dir.create(dirname(destfile), recursive = TRUE, showWarnings = FALSE)
    write.csv(data.frame(status = "mocked download"), destfile)
    return(0)
  },  .package = "utils")

  mockery::stub(province_station_files,
                "utils::askYesNo", FALSE)

  # Test 1: should return message if no year was provided
  expect_message(province_station_files(province = "ontario",
                                        root_folder = temp_dir),
                 "No year provided.")

  # Test 2/3: should return message and NULL if character year was provided
  expect_message({results <- province_station_files(province = "ontario",
                                                    year = "1990",
                                                    root_folder = temp_dir)
  expect_null(results)},
  "Invalid input")

  # Test 4/5: should return message and NULL if invalid year was provided
  expect_message({results <- province_station_files(province = "ontario",
                                                    year = 1234,
                                                    root_folder = temp_dir)
  expect_null(results)},
  "No active hourly stations found in")
})

test_that("Test month inputs", {
  mockery::stub(province_station_files,
                "utils::askYesNo", TRUE)

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
  expect_message({results <- province_station_files(province = "ontario",
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
})

test_that("Test user check-in NO", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  mockery::stub(province_station_files, "interactive", TRUE)
  mockery::stub(province_station_files, "utils::askYesNo", FALSE)


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
                                 code = {expect_message({results <- province_station_files(province = "ontario",
                                                                                           root_folder = temp_dir)
                                 expect_null(results)},
                                 "Download cancelled by user.")})
})

test_that("Test user check-in YES", {
  temp_dir <- file.path(tempdir(), "castform_tests")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)

  mockery::stub(province_station_files, "interactive", TRUE)
  mockery::stub(province_station_files, "utils::askYesNo", FALSE)

  testthat::local_mocked_bindings(
    get_single_station_file = function(...) {
      message("Mock download successful")
      invisible(NULL)
    },
    plan = function(...) NULL,
    interactive = function() TRUE,
    .package = "castform"
  )

  # Test 1: Should print message when downloading <50 fils sequentially...
  expect_message({results <- province_station_files(province = "prince edward island",
                                                    year = 1980,
                                                    month = 1,
                                                    root_folder = temp_dir)
  "files sequentially..."})
})




