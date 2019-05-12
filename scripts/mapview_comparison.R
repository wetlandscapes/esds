## ---- mapview_comp ----
#Header----
#Project: Earth Systems Data Science
#Purpose: Download and combine different temperature records for comparison
#File: ./scripts/mapview_comparison.R
#By: Jason Mercer
#Creation date (YYYY/MM/DD): 2019/05/12
#R Version(s): 3.5.3

#Libraries----
library(leaflet)
library(mapview)
library(pals)
library(sp)
library(tidyverse)

#Load data----
load("data/processed/temperature_comparison.R") #temp_comp


#Data manipulation----
temper_ttest <- temp_comp %>%
  split(.$station_id) %>%
  purrr::map(dplyr::select, ushcn, prism) %>%
  purrr::map(drop_na) %>%
  purrr::map(~t.test(.x$ushcn, .x$prism, alternative = "two.sided", paired = TRUE)) %>%
  purrr::map_dfr(glance, .id = "station_id")

temper_tested <- temp_comp %>%
  dplyr::select(station_id, latitude, longitude, elevation) %>%
  distinct() %>%
  full_join(temper_ttest, by = "station_id") %>%
  mutate(signif = ifelse(estimate < 0, "Overestimate", "Underestimate"),
         signif = ifelse(p.value > 0.05, "Unbiased", signif),
         signif = factor(signif, levels = c("Overestimate", "Unbiased",
                                            "Underestimate"))) %>%
  mutate(estimate_NA = ifelse(p.value > 0.05, NA, estimate))


#Data analysis----
#Calculate an empirical density function for each site
temp_density <- temp_comp %>%
  split(.$station_id) %>%
  purrr::map(mutate, diff = ushcn - prism) %>%
  purrr::map(drop_na) %>%
  purrr::map(pull, diff) %>%
  purrr::map(density) %>%
  purrr::map(~.x[c("x", "y")]) %>%
  purrr::map_dfr(as_tibble, .id = "station_id") %>%
  split(.$station_id) %>%
  purrr::map(left_join, temper_tested, by = "station_id") %>%
  purrr::map(left_join, temp_comp %>% distinct(station_id, name, state),
             by = "station_id")

#Make a function that will generate a similar plot across all sites
density_plotter <- function(data) {
  p <- data %>%
    ggplot(aes(x, ymax = y, ymin = 0)) +
    geom_ribbon(aes(fill = estimate_NA), alpha = 0.75) +
    geom_line(aes(y = y)) +
    geom_vline(xintercept = 0, color = "gray", linetype = "dashed", size = 1) +
    geom_vline(aes(xintercept = estimate_NA)) +
    labs(x = "Temperature bias (C)",
         y = "Probability density",
         title = paste0(unique(data$station_id), ": ", unique(data$name), ", ",
                       unique(data$state))) +
    theme_classic() +
    theme(legend.position = "none") +
    scale_fill_paletteer_c(pals, ocean.balance, -1, limits = c(-4, 4),
                           na.value = "grey50")
  
  p
}

#Save all the plots as a list
density_p <- temp_density %>%
  purrr::map(density_plotter)

#Save all the plots locally (this can take a while as there are >1200 sites)
density_p %>%
  purrr::walk2(.y = names(density_p),
              ~ ggsave(filename = paste0("figures/R/comparison/", .y, ".png"),
                      plot = .x,
                      device = "png"))
