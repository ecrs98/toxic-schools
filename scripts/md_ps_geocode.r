####################
## Getting MD School Coordinates
## Date: 24 November 2022
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

schools_raw <- read.csv(paste0(data, "md_k12_public.csv"))

str(schools)
summary(schools)

## -----
## test ggmap
# spoiler: it worked
test <- geocode("11135 Newport Mill Rd, Kensington, MD 20895")
test

## -----
## get coords

## create address col
schools <- schools_raw %>%
    mutate(address = paste(STREET, CITY, STATE, ZIP, sep = ", "))

## test ggmap on constructed address. spoiler: it worked
test2 <- geocode(schools$address[1])
test2

## test ggmap on multiple addresses. spoiler: it worked
test3 <- geocode(schools$address[1:2])
test3

## create coordinate matrix
coords <- geocode(schools$address)

## check dims
str(coords)
summary(coords)
nrow(coords) == nrow(schools)

## bind
schools <- schools %>% cbind(coords)

## save so we don't have to call Google geocode api again
# write.csv(schools, paste0(data, "md_k12_public_coords.csv"),
#           na="", row.names = F)
