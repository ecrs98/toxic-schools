####################
## Exploring MD School Data
## 8 Nov 2022
##

## Housekeeping
packages <- c("dplyr", "ggmap", "stringr")
suppressWarnings(lapply(packages, require, character.only = T))

## working dir
root <- "/Users/Alfajiri/Projects/mdi/showcase/"
data <- paste0(root, "data/")
setwd(root)


## ----- 
## read in data

## read in new data
schools <- read.csv(paste0(data, "md_k12_public_coords.csv"))

# str(schools)
# summary(schools)


## -----
# clean further

## read in new data
schools <- read.csv(paste0(data, "md_k12_public_coords.csv"))


## OBJECTID
# check if meaningful
summary(schools$OBJECTID)               ## identical distributions, so likely just an index
summary(1:1379)

## remove cols
rm_vars <- c("ï..X", "Y", "OBJECTID")

schools_clean <- schools %>% 
    select(-all_of(rm_vars))

## save
write.csv(schools_clean, paste0(data, "md_k12_public_clean.csv"),
          na="", row.names = F)


## -----
# examine pg county data

## filter to pg only
pg_schools <- schools_clean %>% filter(County=="Prince George's")

## summary stats
nrow(pg_schools)
summary(pg_schools)

## outlying coordinates?
outliers <- pg_schools %>% filter(lon==min(pg_schools$lon,na.rm=T)) %>% select(SCHOOL_NAME, address, lon, lat)
outliers
## check outliers for all data
