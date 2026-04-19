# Yearly Mean Plots

Summarizes the average of each variable over time.

## Usage

``` r
plot_yearly_means(
  db_name = NULL,
  db_dir = "station_data",
  output_dir = "station_data",
  output_name = NULL,
  write_csv = FALSE
)
```

## Arguments

- db_name:

  Character: The name of the database

- db_dir:

  Character: The directory of the database, If left unchanged, will
  default to package's default created directory "station_data".

- output_dir:

  Character: The created download folder and file path. If left
  unchanged, will create a new "station_data" folder in the working
  directory.

- output_name:

  Character: The name of the output file. If left unfilled, the function
  will name the file "db_name_missingness_table.html"

- write_csv:

  Logical: If TRUE prints a csv copy of the results

## Value

An \`.html\` output line plot visualizing the data.
