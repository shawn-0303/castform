library(testthat)

test_that("get single file test", {
  get_single_station_file(station_id = 27226)
  result <- get_multiple_station_files(station_id = 27226)
  expect_s3_class(result, "data.frame")
})

test_that("get multiple files test", {
  result_justid <- get_multiple_station_files(station_id = 27226)
  expect_s3_class(result_justid, "data.frame")

  result_multipleid <- get_multiple_station_files(station_id = c(27226, 65))
  expect_s3_class(result_justid, "data.frame")
})

test_that("get province files test", {
  province_station_files(province = "prince edward island",
                         year = 1998)
  expect_true(dir.exists("station_data/ONTARIO"))})



year_range_station_files(station_name = "discovery island",
                         start_year = 1990)

province_station_files(province = "prince edward island",
                       year = 1980)

get_single_station_file(station_name = "discovery island",
                        month = "jan")


station_lookup(province = "onTaRio",
               start_year = 1233,
               end_year = 2020)

