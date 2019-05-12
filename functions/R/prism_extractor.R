#' Extract PRISM climate data using spatial point data
#'
#' @param prism_grid_filename 
#' @param SPDF 
#' @param verbose 
#'
#' @return
#' @export
#'
#' @examples
prism_extractor <- function(prism_grid_filename, SPDF, verbose = TRUE) {
  #Check if prism_grid_filename is a character string
  if(!is.character(prism_grid_filename)) {
    stop("The prism_grid_filename object should be a character vector.")
  }
  
  #Check if SPDF is a spatial points data frame
  if(!(class(SPDF)[1] == "SpatialPointsDataFrame")) {
    stop(paste("SPDF is not a SpatialPointsDataFrame, which is required ",
               "for the function to work properly.", sep = ""))
  }
  
  #Read in the file name
  file_name <- basename(prism_grid_filename)
  
  if(str_detect(file_name, "all", negate = TRUE)) {
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
  } else {
    file_meta <- file_name %>%
      stringr::str_split(pattern = "\\.", simplify = TRUE) %>%
      .[, 1] %>%
      stringr::str_split(pattern = "_", simplify = TRUE) %>%
      purrr::map2_dfc(c("data_source", "variable", "status", "grid_info", "time",
                        "all", "file_type"),
                      ~ tibble::tibble(!!.y := .x))
  }
  
  
  
  #Check if the file actually exists and if doesn't then return NAs for temp
  if(!file.exists(prism_grid_filename)) {
    #Extract the names of the sites
    out_file <- tibble::tibble(site = SPDF@data[[1]]) %>%
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
  out_file <- tibble::tibble(site = SPDF@data[[1]],
                             value = values)
  
  #Combine the value and metadata
  out_file <- tibble::as_tibble(cbind(file_meta, out_file,
                                      stringsAsFactors = FALSE))
  
  #Return the all the data
  return(out_file)
}