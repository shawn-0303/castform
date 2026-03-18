library(testthat)

test_that("Test station lookup", {
  expect_error(station_lookup())

  expect_message({results1 <- station_lookup(province = "prince edward island",
                                            start_year = 1998,
                                            end_year = 1999)
  expect_null(results1)},
  "No matching stations found. Check spelling or try other parameters.")

  expect_message({results <- station_lookup(province = "prince edward island",
                                             start_year = 1980,
                                             end_year = 2002)
  expect_no_error(results)},
  "Found")

  expect_no_error(station_lookup(province = "prince edward island"))

  expect_error(station_lookup(province = "prince edward island",
                              start_year = "1980",
                              end_year = 2002),
               "`start_year` must be numeric.")

  expect_error(station_lookup(province = "prince edward island",
                              start_year = 1980,
                              end_year = "2002"),
               "`end_year` must be numeric.")
})

















