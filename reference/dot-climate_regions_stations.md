# Identify Station Climate Region

Match the station to it's climate region and extreme temperature
threshold. Last updated April 17, 2026.

## Usage

``` r
.climate_regions_stations(stationID = NULL)
```

## Arguments

- stationID:

  Station ID from queried results from \`heatwave_detector()\`

## Value

If a matching Station ID is found, will return the daytime maximum and
night time minimum temperature threshold for that station as a list.
