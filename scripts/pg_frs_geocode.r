####################
## Getting EPA FRS Coordinates
## 8 Nov 2022
## Updated: 24 November 2022
##

## Housekeeping
packages <- c("dplyr", "ggmap")
suppressWarnings(lapply(packages, require, character.only = T))

## working dir
root <- "/Users/Alfajiri/Projects/mdi/showcase/"
data <- paste0(root, "data/")
setwd(root)


## ----- 
## read in data

## data for PG county only
frs <- read.csv(paste0(data, "pg_epa_frs.csv"))

str(frs)
summary(frs)

## -----
## clean data further

## standardize 


## -----
## get coords

## create address col

frs <- frs %>%  
    mutate(address2 = paste(address, city, state, postal_code, sep = ", "))


## test ggmap on constructed address. spoiler: it worked
test <- geocode(frs$address2[3])
test

## create coordinate matrix
coords <- geocode(frs$address2)

## check dims
str(coords)
summary(coords) ## 20 NAs
nrow(coords) == nrow(frs)


## bind
frs <- frs %>% cbind(coords)


## save so we don't have to call Google geocode api again
write.csv(frs, paste0(data, "pg_epa_frs_coords.csv"),
          na="", row.names = F)
