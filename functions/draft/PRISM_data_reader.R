#Header----
#Project: 
#Purpose: To download and import PRISM data and extract data based on point
# locations of a site.
#File: PRISM_data_reader.R
#By: Jason Mercer
#Creation date (YYYY/MM/DD): 2018/05/06
#R Version(s): 3.5.3



#Libraries----
library(tidyverse)
library(sf)
library(raster)
library(prism)
library(lubridate)
library(paletteer)



#Options----
#Where to download the prism data
download_folder <- "C:/Users/Trader/Downloads/PRISM"

#Makes sure your download folder exists
if(!file.exists(download_folder)) {
  dir.create(download_folder)
  cat("Made folder: '", download_folder, "'.", sep = "")
} else {
  cat("Folder, '", download_folder, "' already exists.", sep = "")
}

#Specify a download location for data
  #Can't specify location in functions, for some reason
options(prism.path = download_folder)



#Download data----
#Use the prism package to download the data
prism::get_prism_monthlys(type = "tmean", years = 1987:2016, mon = 1:12)

#Record which folders were downloaded
prism_folders <- list.dirs(download_folder, full.names = TRUE,
  recursive = FALSE)
#REcord the full name of each file in each folder that contains the raster info
prism_files <- paste0(prism_folders, "/", basename(prism_folders), ".bil")



#Load data----
#Read in the site information
sites_sf <- sf::st_read("C:/Users/Trader/Downloads/Wyoming_Places_JieminOnly.kml")
#Convert to a SpatialPointsDataFrame object
sites_Spatial <- sf::as_Spatial(sites_sf)

#Convert the sites_Spatial to the same projection as the .bil files
sites_Spatial <- sp::spTransform(sites_Spatial,
  "+proj=longlat +datum=NAD83 +no_defs +ellps=GRS80 +towgs84=0,0,0")

#Define the main function for parsing the data
prism_extractor <- function(prism_grid_filename, SPDF, verbose = TRUE) {
  #Check if prism_grid_filename is a character string
  if(!is.character(prism_grid_filename)) {
    stop("The prism_grid_filename object should be a character vector.")
  }
  
  #Check if SPDF is a spatial points data frame
  if(!(class(sites_Spatial)[1] == "SpatialPointsDataFrame")) {
    stop(paste("SPDF is not a SpatialPointsDataFrame, which is required ",
      "for the function to work properly.", sep = ""))
  }

  #Read in the file name
  file_name <- basename(prism_grid_filename)
  
  #Convert the file name information into metadata about the raster being read
  file_meta <- file_name %>%
    #Gets rid of the ".bil" extenstion, as it is redundant
    stringr::str_split(pattern = "\\.", simplify = TRUE) %>%
    #Keeps only the important part
    .[, 1] %>%
    #Splits up the name based on the "_" part of the file name
    stringr::str_split(pattern = "_", simplify = TRUE) %>%
    #Use non-standard evaluation (NSE) to make a tibble/dataframe of metadata
    purrr::map2_dfc(c("data_source", "variable", "status", "grid_info", "time",
      "file_type"),
      #This is the NSE part
      ~ tibble::tibble(!!.y := .x))
  
  #Check if the file actually exists and if doesn't then return NAs for temp
  if(!file.exists(prism_grid_filename)) {
    #Extract the names of the sites
    out_file <- tibble::tibble(site = SPDF@data$Name) %>%
      #Make all the values NA
      dplyr::mutate(value = NA_real_)
    #Column bind all the data, recplicating the metadata however many rows of
    # sites there are, then convert to a tibble
    out_file <- tibble::as_tibble(cbind(file_meta, out_file,
      stringsAsFactors = FALSE))
    #Return the result and terminate the function
    return(out_file)
  }
  
  #Read in the PRISM grid, if it exists
  prism_grid <- raster::raster(prism_grid_filename)
  
  #HERE IS WHERE I CAN CHECK IF THE PROJECTIONS ARE THE SAME
  if(!(prism_grid@crs@projargs == SPDF@proj4string@projargs)) {
    if(verbose) {
      warning(paste("The prism_grid and SPDF objects do not have the same",
        " coordinate reference system (CRS). You may not be extracting the",
        " right point if CRS information are not the same.", sep = ""))
    }
  }
  
  #Extract the x-y data for each site
    #The first and second columns contain the x and y data, respectively
  spatial_xy <- SPDF@coords[, c(1, 2)]
  
  #Extract the value (e.g., temperature) information
  values <- raster::extract(prism_grid, spatial_xy)
  
  #Record the sites and values in a single tibble
  out_file <- tibble::tibble(site = SPDF@data$Name,
    value = values)
  
  #Combine the value and metadata
  out_file <- tibble::as_tibble(cbind(file_meta, out_file,
    stringsAsFactors = FALSE))
  
  #Return the all the data
  return(out_file)
}

#Read in the data!
prism_data_raw <- purrr::map_dfr(prism_files, prism_extractor,
  sites_Spatial)

#Convert time into year and month information
prism_data <- prism_data_raw %>%
  #Assumes the first 4 digits are the year and the last 2 are month
  tidyr::separate(col = time, into = c("year", "month"), 4) %>%
  #Use lubridate to convert to a Date column
  dplyr::mutate(year_month = lubridate::ymd(paste(year, month, 01, sep = "-")))



#Data analysis----
#Calculate site averages
prism_data_means <- prism_data %>%
  dplyr::group_by(site) %>%
  dplyr::mutate(value = mean(value, na.rm = TRUE))

#Generate a color palette
cp <- paletteer::paletteer_d(package = ggsci, palette = default_igv,
  n = length(unique(prism_data$site)))
names(cp) <- unique(prism_data$site)

#Plot the data!
prism_data %>%
  dplyr::group_by(year_month) %>%
  dplyr::summarise(value = mean(value, na.rm = TRUE)) %>%
  tidyr::drop_na() %>%
  ggplot(aes(year_month, value)) +
  geom_line(color = "grey") +
  geom_hline(data = prism_data_means, aes(yintercept = value, color = site),
    size = 1) +
  labs(x = "Date",
    y = "Temperature (C)") +
  theme_classic() +
  scale_color_manual(values = cp, name = "Site")

#Plot the outliers
prism_monthly_prob <- prism_data %>%
  group_by(site, month) %>%
  mutate(mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    probability = pnorm(value, mean, sd),
    outlier = ifelse(probability > 0.975, "Warmer than usual", NA),
    outlier = ifelse(probability < 0.025, "Cooler than usual", outlier)) %>%
  drop_na() %>%
  ungroup()
  
fp <- c(paletteer_d(ggsci, nrc_npg, 5))
names(fp) <- c("Warmer than usual", "Cooler than usual")

prism_data %>%
  filter(month %in% c("06", "07", "08", "09")) %>%
  mutate(month = month(year_month, label = TRUE, abbr = FALSE)) %>%
  ggplot(aes(year_month, value)) +
  geom_line(aes(color = site)) +
  geom_point(data = prism_monthly_prob %>%
      filter(month %in% c("06", "07", "08", "09")) %>%
      mutate(month = month(year_month, label = TRUE, abbr = FALSE)),
    aes(fill = outlier), shape = 21, size = 4) +
  facet_wrap(~ month) +
  labs(x = NULL, y = "Temperature (C)") +
  theme_classic() +
  theme(strip.background = element_blank()) +
  scale_color_manual(values = cp, name = "Site") +
  scale_fill_manual(values = fp, name = "Temperature\nanomaly")


#Look for outliers across all sites
prism_prob <- prism_data %>%
  mutate(month = month(year_month, label = TRUE)) %>%
  distinct(year_month, month, value) %>%
  mutate(year = year(year_month)) %>%
  group_by(month) %>%
  mutate(mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    probability = pnorm(value, mean, sd),
    outlier = ifelse(probability > 0.975, "Warmer than usual", NA),
    outlier = ifelse(probability < 0.025, "Cooler than usual", outlier)) %>%
  ungroup()

prism_prob %>%
  group_by(month, year) %>%
  mutate(value = mean(value, na.rm = TRUE)) %>%
  ggplot(aes(month, value)) +
  geom_line(aes(group = year), color = "gray") +
  geom_point(data = prism_prob %>% drop_na(),
    aes(color = year, shape = outlier), size = 4) +
  labs(x = NULL, y = "Temperature (C)") +
  theme_classic() +
  scale_color_distiller(palette = "Spectral",
    name = "Year of temperature\nanomaly",
    limits = c(1987, 2016)) +
  scale_shape_discrete(name = "Temperature\nanomaly")



#Export----




