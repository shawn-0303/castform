# Station Look-Up

Search for Canadian weather stations with hourly data by filtering by
province and year range. Users can search through a single parameter or
a combination of multiple.

## Usage

``` r
station_lookup(
  province = NULL,
  start_year = NULL,
  end_year = NULL,
  HLY_station_info = NULL
)
```

## Arguments

- province:

  Character. The Canadian province or territory of interest.

- start_year:

  Numeric Integer. The start year of the data pull.

- end_year:

  Numeric Integer. The end year of the data pull

- HLY_station_info:

  Dataframe: Station metadata
