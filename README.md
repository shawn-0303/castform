
# castform

<img src="man/figures/castform_logo.png" align="right" width="140" alt="castform hex sticker" />

castform is a package used to download historic hourly weather station data from Environment Canada. This data is downloaded from:

https://climate.weather.gc.ca/historical_data/search_historic_data_e.html

<br clear="right"/>

## Available Functions

This package has various functions that allow for the download, processing, and analysis of historical weather station data. This includes functions to:

* Download latest station inventory list
* Search for available stations by province and year range
* Download a single hourly data file 
* Download multiple hourly data files 
* Download data files by province/territory
* Download data files by year range
* Download all available hourly station files
* Create a database from downloaded files
* Create exploratory plots
* Detect heatwaves from historical data

## Installation

You can install the development version of castform from [GitHub](https://github.com/shawn-0303/castform) with:

``` r
# install.packages("pak")
pak::pak("shawn-0303/castform_package")
```

## Loading Metadata

This needs to be the FIRST STEP of your analysis.

Download the latest station inventory list using `get_metadata()`. 
This function will download the latest station inventory list and store each new version as a .csv and .rda file. 
Whenever this function is run, it will also load the station list into the global environment as `Hourly_station_info`.

``` r
library(castform)

get_metadata()
```

## Searching for Station Information

All the download wrappers require specific information about the station(s) the user wants to download. 
This information can be pulled from the metadata using station_lookup().

``` r
station_lookup(province = "prince edward island",
               start_year = 1953,
               end_year = 2001)
```

You can search for stations by `Province` as well as the `start_year` and `end_year` of hourly data collection.

## Downloading files

The following are various download wrappers that will download historic weather station data as .csv files. 

By default, all downloads are written to a new "station_data" folder in the working directory.

### Download a Single Station File

Download a single .csv file from a specified station that stores a month of hourly weather data.

If your goal is a larger download, it is a good idea to verify your station information and output directories using this function.

``` r
get_single_station_file(station_name =  "discovery island",
                        station_id = 27226,
                        year = 1997,
                        month = 1,
                        root_folder = "station_data")
```        

### Downloading Multiple Station Files

``` r                        
get_multiple_station_files(station_name = "discovery island",
                           station_id = 27226,
                           number_of_files = 10,
                           year = 1997,
                           month = 1,
                           parallel_threshold = 50,
                           root_folder = "station_data")
```

### Downloading Files by Station

Can specify by `year` and `month`, but if left empty, will download all data available for that station.

``` r                        
get_station_files(station_name = "discovery island"
                  station_id = 27226,
                  parallel_threshold = 50,
                  root_folder = "station_data")
```

### Downloading Files by Province

Can specify by `year` and `month`, but if left empty, will download all data available for that province.

```r
province_station_files(province = "prince edward island",
                       parallel_threshold = 50,
                       root_folder = "station_data")
```

### Downloading Files by Year Range 

```r
year_range_station_files(station_name = "discovery island",
                         station_id = 27226,
                         start_year = 1997,
                         end_year = 1999,
                         parallel_threshold = 50,
                         root_folder = "station_data")
```

### Download All Available Hourly Station Data

This function downloads all available historical hourly weather station data from Canada and **will result in a very large download.**

```r
get_all_files()
```
## Making Databases

Creates a searchable database with a specified folder of hourly weather station data.
By default, data will be pulled from the package’s default data storage folder (“station_data”) 
in the user’s working directory and the database will be stored in the same folder.

```r
build_station_database <- function(db_name = "BC_station_data", 
                                   output_dir = "castform_outputs", 
                                   root_folder = "downloaded_data") 
```

This builds a database with the expected scheme:

* `Weather`: Stores weather conditions and their associated numeric codes
* `Station`: Stores weather station information using HLY_station_info
* `Observation`: Stores information from downloaded station data (.csv) files

### Validate the Database

After creation, it is a good idea to validate the created database using `validate_database()`
This will check for the created tables, list the number of observations within each table, 
and lists the first five observations within the Observation table.

```r
validate_database(db_name = "BC_station_data",
                  db_dir = "castform_outputs")
```

From the expected schema, produced tables should have: 

* `Weather` 54 records
* `Station` As many records as HLY_Station_Info
* `Observation` As many records as stored in the downloaded data files

## Exploratory Data Analysis

Queries and produces .html outputs to visualize the structure and summary of the data.
Each table provides buttons for users to copy the output or download a `.csv` or `.pdf`. 

### Data Missingness

Creates a table outlining the expected and actual data counts, along with the percentage of 
missing data for each variable in each station. 

```r
data_missingness_table(db_name =  "BC_station_data",
                       db_dir = "castform_outputs",
                       output_dir = ""castform_outputs"")
```

### Data Ranges

Creates a table summarizing the average, minimum and maximum value of each variable 
in each station.

```r
data_ranges(db_name =  "BC_station_data",
            db_dir = "castform_outputs",
            output_dir = ""castform_outputs"")
```
