## ---- temp_comp ----
#Header----
#Project: Earth Systems Data Science
#Purpose: Download and combine different temperature records for comparison
#File: ./scripts/temperature_comparison.R
#By: Jason Mercer
#Creation date (YYYY/MM/DD): 2019/05/10
#R Version(s): 3.5.3

#Libraries----
library(tidyverse)
library(sf)
library(sp)
library(raster)
library(prism)


#Options----
#Where to download the prism data
download_folder <- "data/temp"

#Create the download folder, if it doesn't already exist
if(!file.exists(download_folder)) {
  dir.create(download_folder)
  cat("Made folder: '", download_folder, "'.", sep = "")
} else {
  cat("Folder '", download_folder, "' already exists.", sep = "")
}

#Specify a download location for data
#Can't specify download location in functions, for some reason
options(prism.path = download_folder)


#Custom functions----
#Load in any custom functions I've made
purrr::walk(list.files("functions/R", pattern = "*.R$", full.names = TRUE,
                       recursive = FALSE), source, verbose = FALSE)


#Download data----
#*USHCN data----
#Monthly average temperature for sites in the US Historical Climatology Network
ta_mon_file <- paste0("https://cdiac.ess-dive.lbl.gov/ftp/ushcn_v2.5_monthly/",
                      "ushcn2014_FLs_52i_tavg.txt.gz")
#Station metadata (e.g., spatial locations)
station_file <- paste0("https://cdiac.ess-dive.lbl.gov/ftp/ushcn_v2.5_monthly/",
                       "ushcn-stations.txt")
#Download the data
download.file(url = ta_mon_file,
              destfile = "data/raw/ushcn/ushcn2014_FLs_52i_tavg.txt.gz")
download.file(url = station_file,
              destfile = "data/raw/ushcn/ushcn-stations.txt")

#*PRISM data----
#Download the prism data; this takes a few moments
#prism::get_prism_annual(type = "tmean", years = 1895:2014)


#Load data----
#*USHCN data----
#Station temperature data
ta_mon_raw <- read.table(file = "data/raw/ushcn/ushcn2014_FLs_52i_tavg.txt.gz",
                     as.is = TRUE,
                     colClasses = "character",
                     sep = "$")

#Station metadata
#Information from the metadata file for reading in a fixed width file
pos_start <- c(1, 8, 17, 27, 34, 37, 68, 75, 82, 89)
pos_end <- c(6, 15, 25, 32, 35, 66, 73, 80, 87, 90)
  #Note: elevation is in meters
pos_col <- c("station_id", "latitude", "longitude", "elevation", "state",
             "name", "component_1", "component_2", "component_3", "UTC")

station_raw <- read_fwf("data/raw/ushcn/ushcn-stations.txt",
                        col_positions = fwf_positions(start = pos_start,
                                                      end = pos_end,
                                                      col_names = pos_col),
                        na = c("------", "-999.9"))

#*PRISM data----
#Only one PRISM data set will be in memory at a time, to reduce overhead.
# Read-in occurs when executing the `prism_extractor` function.


#Data manipulation----
#Massage the USHCN file into something useable
  #Drop the first 17 characters -- they'll get added in later
ta_mon <- sub(pattern = "^.{17}", replacement = "",
                      x = ta_mon_raw$V1) %>%
  #Remove some superfluous stuff
  gsub(pattern = "(.{5}).{4}", replacement = "\\1,", x = .)  %>%
  sub(",(.{5}).{3}$", ",\\1", .) %>%
  #Read in the "file"; first 12 obs are month average temps
  read_csv(col_names = c(month.abb, "annual"),
           na = "-9999",
           trim_ws = TRUE) %>%
  #Keep only the annual data for each site/year combo
  dplyr::select(annual) %>%
  #Pull in the station info
  mutate(station_id = sub(pattern = "USH00([[:digit:]]+).*",
                                             replacement = "\\1",
                                             x = ta_mon_raw$V1)) %>%
  #Pull in the year
  mutate(year = as.numeric(sub("USH00[[:digit:]]+ +([[:digit:]]+).*", "\\1",
                               ta_mon_raw$V1)))

#Convert temperature from F to C
ta_mon <- ta_mon %>%
  mutate(annual = ((annual/10) - 32) * 5/9) %>%
  rename("ushcn" = "annual")

#Keep only the station metadata of interest
station <- station_raw %>%
  dplyr::select(station_id, latitude, longitude, elevation, state, name)

#Combine temperature and
ushcn_data <- full_join(station, ta_mon, by = "station_id")

#I'm guessing the CRS is 4326 base on:
# https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/
# OverviewCoordinateReferenceSystems.pdf
temper_sp <- ushcn_data %>%
  dplyr::select(longitude, latitude) %>%
  distinct() %>%
  sp::SpatialPointsDataFrame(data = ushcn_data %>%
                               distinct(longitude, latitude, station_id),
                             proj4string = CRS(sf::st_crs(4326)[[2]]))

#Convert the temper_sp to the same projection as the PRISM .bil files
temper_sp <- sp::spTransform(temper_sp,
  "+proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0")

#Record which folders were downloaded for the PRISM data
prism_folders <- list.dirs(download_folder, full.names = TRUE,
                           recursive = FALSE)

#Record the full name of each file in each folder that contains the raster info
prism_files <- paste0(prism_folders, "/", basename(prism_folders), ".bil")


#Data analysis----
#Read in the PRISM data! (This'll take a hot second)
prism_data_raw <- map_dfr(prism_files, prism_extractor,
                                 temper_sp["station_id"])
  
#Convert time into numeric, highlight that it is a year, and keep only the
# important stuff
prism_data <- prism_data_raw %>%
  dplyr::mutate(year = as.numeric(time)) %>%
  dplyr::select(site, year, value) %>%
  rename("prism" = "value")

#Join all the data together so it can be compared
temp_comp <- full_join(ushcn_data, prism_data,
                         by = c("station_id" = "site", "year" = "year"))


#Export----
#Save the data to be examined and plotted later
#save(temp_comp, file = "data/processed/temperature_comparison.R")


#Remove----
#Get rid of the large temporary data
#unlink(download_folder, recursive = TRUE)
