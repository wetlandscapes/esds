library(tidyverse)
library(sf)
library(dataRetrieval)


gagesii <- read_sf("data/gagesII_9322_sept30_2011.shp")

gagesii %>%
  select(HCDN_2009:FLYRS1990) %>%
  plot()

length(unique(gagesii$STAID))
staid <- gagesii$STAID[1]

#https://cran.r-project.org/web/packages/dataRetrieval/vignettes/dataRetrieval.html

ChoptankInfo <- readNWISdv(staid, "00060")
ChoptankInfo <- renameNWISColumns(ChoptankInfo)
unique(ChoptankInfo$Flow_cd)

attributes(ChoptankInfo)$siteInfo

ChoptankInfo %>%
  drop_na() %>%
  ggplot(aes(Date, Flow)) +
  geom_line() +
  theme_classic()
