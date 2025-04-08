####################
## PG County K-12 Public Schools Proximity to Toxic Waste Facilities
## Date: 30 November 2022
##



rm(list = ls())

## ---------------------------------------- ##
## HOUSEKEEPING
## ---------------------------------------- ##

## load packages
packages <- c("dplyr", "geosphere", "ggplot2")
invisible(lapply(packages, require, character.only = T))

## dirs
root <- "/Users/Alfajiri/Projects/mdi/showcase/"
data <- paste0(root, "data/")
output <- paste0(root, "output/")
setwd(root)

## ---------------------------------------- ##
## DATA WRANGLING
## ---------------------------------------- ##

## read data
ps <- read.csv(paste0(data, "md_k12_public_clean.csv"))
frs <- read.csv(paste0(data, "pg_epa_frs_coords.csv"))


## clean data
# filter ps to pg
ps <- ps %>% filter(County == "Prince George's") %>% 
    # and fix the error in geocoding
    mutate(lon = ifelse(SCHOOL_NAME == "Wirt (William) Middle", -76.91038644511002, lon),
           lat = ifelse(SCHOOL_NAME == "Wirt (William) Middle", 38.966093500746034, lat))

# clean frs
frs <- frs %>%
    mutate(site_type = ifelse(site_type == "", NA, site_type)) %>%  ## clean site type
    filter(address != "",
           site_type != "STATIONARY")   # stationary included stuff like Family Dollar and other businesses. noise perhaps


## coordinate matrices
ps_coord <- ps %>% select(lon, lat)
frs_coord <- frs %>% select(lon, lat)



## -----
## Calculating distances

## create function to get list of dataframes
ps_frs_dist <- function(school_row){
    dist_df <- data.frame(school = school_row["SCHOOL_NAME"],
                          facility = frs$facility_name,
                          facility_type = frs$site_type,
                          facility_address = frs$address2,
                          distance = distHaversine(school_row[c("lon", "lat")], frs_coord, r = 3963.190592),
                          row.names = NULL)
    
}


## apply function
# initialise
dist_list <- list()

# execute
for(i in 1:nrow(ps)){
    df <- ps_frs_dist(ps[i,]) %>% 
        arrange(distance)
    dist_list[[i]] <- df
}


## -----
## Calculating concentrations

## define function
facility_conc <- function(df){
    name <- unique(df$SCHOOL_NAME)
    conc2 <- df %>% filter(distance <= 2) %>% nrow()
    conc3 <- df %>% filter(distance <= 3) %>% nrow()
    conc5 <- df %>% filter(distance <= 5) %>% nrow()
    name_conc <- list(name, conc2, conc3, conc5)
    return(name_conc)
}

## apply function
conc_list <- lapply(dist_list, facility_conc)

# list to df
conc <- as.data.frame(do.call(rbind, conc_list)) %>% 
    transmute(name  = as.character(V1),
              conc2 = as.numeric(V2),
              conc3 = as.numeric(V3),
              conc5 = as.numeric(V4))


## -----
## Merge back onto ps data

ps_conc <- ps %>%
    left_join(conc, by = c("SCHOOL_NAME" = "name")) %>% 
    select(SCHOOL_NAME, contains("conc"), lat, lon, everything())

## create conc_bin column
ps_conc <- ps_conc %>% 
    mutate(conc_bin = factor(case_when(
        conc5 == 0  ~ "0",
        conc5 %in% 1:2  ~ "1-2",
        conc5 %in% 3:4  ~ "3-4",
        conc5 %in% 5:6  ~ "5-6",
        conc5 >= 7  ~ "7+",
    )))


## ---------------------------------------- ##
## PLOTTING
## ---------------------------------------- ##

## pg shape from urban
pg <- urbnmapr::counties %>% filter(county_fips == 24033)

## breaks
conc_breaks = c(2,4,6,8)

## -----
## 2mi radius

## all schools
ps_plot2 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "black")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = ps_conc,
               aes(lon, lat, size = conc2, color = factor(conc2)))+
    scale_size(guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    # scale_color_manual(values = conc_colors)+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
ps_plot2
ggsave(paste0(output, "all_2mi.png"), height = 6, width = 4, dpi=600)

## elementary schools
es_plot2 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#E31B23")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Elementary", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc2, color = factor(conc2)))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1", guide=NULL)+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
es_plot2
ggsave(paste0(output, "es_2mi.png"), height = 6, width = 4, dpi=600)

## middle schools
ms_plot2 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "black")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Middle", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc2, color = factor(conc2)))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1", guide = NULL)+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
ms_plot2
ggsave(paste0(output, "ms_2mi.png"), height = 6, width = 4, dpi=600)

## high schools
hs_plot2 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#00863D")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type == "High"),
               aes(lon, lat, size = conc2, color = factor(conc2)))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1", guide = NULL)+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
hs_plot2
ggsave(paste0(output, "hs_2mi.png"), height = 6, width = 4, dpi=600)








## -----
## 5mi radius

## all schools
ps_plot5 <- ggplot(data = NULL)+
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
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
         color = "")+
    ggpubr::theme_transparent()
ps_plot5
ggsave(paste0(output, "all_5mi.png"), height = 6, width = 4)

## elementary schools
es_plot5 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#E31B23")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Elementary", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
es_plot5
ggsave(paste0(output, "es_5mi.png"), height = 6, width = 4, dpi=600)

## middle schools
ms_plot5 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "black")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type %in% c("Middle", "Elementary/Middle", "PreK-8")),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
ms_plot5
ggsave(paste0(output, "ms_5mi.png"), height = 6, width = 4, dpi=600)

## high schools
hs_plot5 <- ggplot(data = NULL)+
    geom_polygon(data = pg, 
                 aes(long, lat, group = group),
                 color = NA, fill = "#00863D")+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45)+
    ## schools
    geom_point(data = filter(ps_conc, School_Type == "High"),
               aes(lon, lat, size = conc5, color = conc_bin))+
    scale_size_continuous(breaks = conc_breaks, guide = NULL)+
    scale_color_brewer(palette = "Set1")+
    labs(#title = "Number of toxic waste facilities within a 5-mile radius",
        color = "")+
    theme_void()
hs_plot5
ggsave(paste0(output, "hs_5mi.png"), height = 6, width = 4, dpi=600)



















