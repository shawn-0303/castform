library(testthat)

stub_download <- function(fn) {
  mockery::stub(fn, "get_single_station_file", function(...) {
    message("Mock download successful")
    return(invisible(NULL))
  })
}

test_that("Test station id and year inputs", {
  stub_download(get_multiple_station_files)

  # Test 1: should return error for no inputs
  expect_error(get_multiple_station_files(),
    "Provide station_name or station_id")

  # Test 2/3: should return a message and NULL if invalid station ID is provided
  expect_message({results <- get_multiple_station_files(station_id = 1234)
  expect_null(results)},
  "not found")

  # Test 4/5: should return message and NULL if invalid station name is provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery")
  expect_null(results)},
  "Check spelling")

  # Test 6: should return message and autofill station id
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1997,
                                                        month = 1)},
                 "Auto-filled unique Station ID")
})

test_that("Test year inputs", {
  stub_download(get_multiple_station_files)

  # Test 1: should return message if no year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island")},
                 "No year provided.")

  # Test 2/3: should return message and NULL if character year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = "1990")
  expect_null(results)},
  "Invalid input")

  # Test 4/5: should return message and NULL if invalid year was provided
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                        year = 1990)
  expect_null(results)},
  "No station matching")
})

test_that("Test month inputs", {
  stub_download(get_multiple_station_files)

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
                                                     year = 1997)},
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
                                      year = 1997), "data.frame")

  expect_s3_class(get_multiple_station_files(station_name =  "discovery island",
                                      month = "Feb",
                                      year = 1997), "data.frame")

  expect_s3_class(get_multiple_station_files(station_name =  "discovery island",
                                      month = "Feb",
                                      year = 1997), "data.frame")

})

test_that("Test station matching", {
  stub_download(get_multiple_station_files)

  # Test 1: should be a successful match
  expect_s3_class(results <- get_multiple_station_files(station_name =  "discovery island",
                                                  year = 1997,
                                                  month = 1), "data.frame")

  # Test 2/3: should not be a successful match (NULL and message expected)
  expect_message({results <- get_multiple_station_files(station_name =  "discovery island",
                                                     year = 1234,
                                                     month = 1)
  expect_null(results)},
  "was active in 1234")

  # Test 4/5: Should find multiple stations with the same staion id and return a message and NULL
  expect_message({results <- get_multiple_station_files(station_name =  "victoria harbour a",
                                                     year = 2015,
                                                     month = 1)
  expect_null(results)},
  "Multiple stations found")

  # Test 6: Should return a valid data frame
  expect_s3_class(results <- get_multiple_station_files(station_id = 27226,
                                                        year = 1997,
                                                        month = 1), "data.frame")
})

test_that("Test parallelization", {
  old_plan <- future::plan(future::sequential)
  on.exit(future::plan(old_plan), add = TRUE)

  mockery::stub(get_multiple_station_files, "plan", function(...) NULL)
  mockery::stub(get_multiple_station_files, "get_single_station_file", function(...) NULL)
  mockery::stub(get_multiple_station_files,
                "utils::askYesNo", TRUE)

  # Test 1: should produce a message when parallelization threshold is met
  testthat::with_mocked_bindings(interactive = function() TRUE,
                                 code = {expect_message(get_multiple_station_files(station_name = "discovery island",
                                                                                   year = 1997,
                                                                                   month = 1,
                                                                                   number_of_files = 51),
                                                        "Parallelization threshold met")
                                   })
})


test_that("Test user check-in NO", {
  mockery::stub(get_multiple_station_files,
                "utils::askYesNo", FALSE)

  testthat::with_mocked_bindings(interactive = function() TRUE,
    code = {expect_message(get_multiple_station_files(station_id = 27226,
                                                      number_of_files = 60),
        "Download cancelled by user.")})
})

test_that("Test user check-in YES", {
  old_plan <- future::plan(future::sequential)
  on.exit(future::plan(old_plan), add = TRUE)

  mockery::stub(get_multiple_station_files,
                "utils::askYesNo", TRUE)

  testthat::with_mocked_bindings(interactive = function() TRUE,
                                 code = {result <- get_multiple_station_files(station_id = 27226,
                                                                              number_of_files = 60)
                                 expect_false(is.null(result))})
})

