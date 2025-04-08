####################
## PG County K-12 Public Schools Proximity to Toxic Waste Facilities (Messy)
## Date: 24 November 2022
##

rm(list = ls())

## Housekeeping
packages <- c("dplyr", "geosphere", "ggplot2", "urbnmapr")
invisible(lapply(packages, require, character.only = T))

## working dir
root <- "/Users/Alfajiri/Projects/mdi/showcase/"
data <- paste0(root, "data/")
setwd(root)


## ------------------------------ ##
## Read in data
## ------------------------------ ##

ps <- read.csv(paste0(data, "md_k12_public_clean.csv"))
frs <- read.csv(paste0(data, "pg_epa_frs_coords.csv"))

## ------------------------------ ##
## Clean data
## ------------------------------ ##

## filter ps to pg
ps <- ps %>% filter(County == "Prince George's")

## clean frs
frs <- frs %>%
    mutate(site_type = ifelse(site_type == "", NA, site_type)) %>%  ## clean site type
    filter(address != "")




## ------------------------------ ##
## Calculating distances
## ------------------------------ ##

## coordinate matrices
ps_coord <- ps %>% select(lon, lat)
frs_coord <- frs %>% select(lon, lat)


## test distHaversine()
## 6378137 meters = 3963.190592 miles

## one school, one facility
test <- distHaversine(ps_coord[1,], frs_coord[1,])
test

## one school, many facilities
test2 <- distHaversine(ps_coord[1,], frs_coord[1:10,])
test2


## test getting df
test3 <- data.frame(school = ps$SCHOOL_NAME[1],
                    facility = frs$facility_name,
                    facility_type = frs$site_type,
                    facility_address = frs$address2,
                    distance = distHaversine(ps_coord[1,], frs_coord, r = 3963.190592),
                        row.names = NULL)

## create function to get list of dataframes
ps_frs_dist <- function(school_row){
    dist_df <- data.frame(school = school_row["SCHOOL_NAME"],
                          facility = frs$facility_name,
                          facility_type = frs$site_type,
                          facility_address = frs$address2,
                          distance = distHaversine(school_row[c("lon", "lat")], frs_coord, r = 3963.190592),
                          row.names = NULL)
    
}
test4 <- ps_frs_dist(ps[1,])

all(test3==test4, na.rm=T)

## test lapply
# test_df <- ps[1:2,]

# test5 <- apply(test_df, 1, ps_frs_dist)
# View(test5[[1]])

## test for loop
#  initialize list
test_df <- ps[1:3,]

test_list <- list()
for(i in 1:nrow(test_df)){
    df <- ps_frs_dist(test_df[i,])
    test_list[[i]] <- df
}

## get type counts for all sites 
frs_types <- frs %>% group_by(site_type) %>% summarise(count = n())
frs_types

## look at one school non-stationary
fhh_nonstat <- test_list[[1]] %>% filter(facility_type!="STATIONARY")


## lapply and get dfs for all 197 schools
dists <- lapply()





######### 
## NON STAT DISTS (USE THESE FOR PROJ)
#########

frs_nonstat <- frs %>% filter(site_type!="STATIONARY")
frs_nonstat_coord <- frs_nonstat %>% select(lon, lat)

ps_frs_dist <- function(school_row){
    dist_df <- data.frame(school = school_row["SCHOOL_NAME"],
                          facility = frs_nonstat$facility_name,
                          facility_type = frs_nonstat$site_type,
                          facility_address = frs_nonstat$address2,
                          distance = distHaversine(school_row[c("lon", "lat")], frs_nonstat_coord, r = 3963.190592),
                          row.names = NULL)
    
}

## test nonstat
test_df_nonstat <- ps[1:3,]

test_list_nonstat <- list()
for(i in 1:nrow(test_df_nonstat)){
    df <- ps_frs_dist(test_df_nonstat[i,])
    test_list_nonstat[[i]] <- df
}

## execute
dist_list <- list()

for(i in 1:nrow(ps)){
    df <- ps_frs_dist(ps[i,])
    dist_list[[i]] <- df
}






#####################################################
## GET FACILITY CONCENTRATION

## test for one df
test_df <- dist_list[[1]]

leq2 <- test_df %>% filter(distance <= 2) %>% nrow()
leq3 <- test_df %>% filter(distance <= 3) %>% nrow()
leq5 <- test_df %>% filter(distance <= 5) %>% nrow()
leq2
leq3
leq5

##### FUNCTION APPROACH
## define function to get conc
facility_conc <- function(df){
    name <- unique(df$SCHOOL_NAME)
    conc2 <- df %>% filter(distance <= 2) %>% nrow()
    conc3 <- df %>% filter(distance <= 3) %>% nrow()
    conc5 <- df %>% filter(distance <= 5) %>% nrow()
    name_conc <- list(name, conc2, conc3, conc5)
    return(name_conc)
}

## test func
facility_conc(test_df)

leq2 == facility_conc(test_df, 2)[[2]]
leq3 == facility_conc(test_df, 3)[[2]]
leq5 == facility_conc(test_df, 5)[[2]]


## apply func
conc_list <- lapply(dist_list, facility_conc)

# list to df
conc <- as.data.frame(do.call(rbind, conc_list)) %>% 
    rename(name  = V1,
           conc2 = V2,
           conc3 = V3,
           conc5 = V4)



#####################################################
## SUMMARY STATS


ps_conc %>% select(conc2, conc3, conc5) %>% summary()

## histograms
hist_conc2 <- ps_conc %>% 
    ggplot(aes(x = conc2))+
    geom_histogram(bins=6)+
    labs(title="2mile")
hist_conc2

hist_conc3 <- ps_conc %>% 
    ggplot(aes(x = conc3))+
    geom_histogram(bins=7)+
    scale_x_continuous(breaks = c(0:10))+
    labs(title="3mile")
hist_conc3

hist_conc5 <- ps_conc %>% 
    ggplot(aes(x = conc5))+
    geom_histogram(bins=10)+
    scale_x_continuous(breaks = c(0:10))+
    labs(title="5mile")
hist_conc5

summary()




#####################################################
## PLOTTING

## just pg
pg <- counties %>% filter(county_fips == 24033)
pg_plot <- pg %>% 
    ggplot(aes(long, lat, group = group)) +
    geom_polygon(color=NA, fill = "#e31b23") +
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)#+
    # theme_void()
pg_plot

## add schools
ps_plot <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#00863D")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = ps,
               aes(lon, lat))+
    theme_void()
ps_plot










## define breaks and colors
conc_breaks = c(2,4,6,8)
conc_colors = rev(RColorBrewer::brewer.pal(5, "Set1"))



## add conc
ps_plot <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "black")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = ps_conc,
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size(guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    # scale_color_manual(values = conc_colors)+
    labs(color = "")+
    theme_void()
ps_plot

## elementary schools
es_plot <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#E31B23")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Elementary", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    theme_void()
es_plot

## middle schools
ms_plot <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "black")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Middle", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    theme_void()
ms_plot

## high schools
hs_plot <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#00863D")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type == "High"),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    theme_void()
hs_plot



