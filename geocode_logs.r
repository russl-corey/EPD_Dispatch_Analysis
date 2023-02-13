# Filename: geocode_logs.r
# Author: @russl_corey <russl_corey@proton.me>
# Date: Jan 8, 2023
# 
# This program is free software: you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY 
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program. If not, see <https://www.gnu.org/licenses/>. 


library(readr)
library(dplyr)
library(geojsonio)
library(stringr)

out_folder <- '/home/russell/Data/GIS/epd/'

# Set the working directory this script is located
setwd("/home/russell/Dropbox/DataAnalysis/EPD_Response_Times/")

# PART ONE: load transformed epd dispatch data
epd_logs <- read_csv('data/epd_logs_resptime.csv')

# set location to lower case
epd_logs$location <- tolower(epd_logs$`Location   `)

# Separate the numbered addresses from street intersections
epd_inter <- epd_logs[grepl('/', epd_logs$`Location   `),]
epd_addr <- epd_logs[!grepl('/', epd_logs$`Location   `),]


# Parse addresses into street name and number
# Split business address into number and street
epd_addr[c('number', 'street')] <- str_split_fixed(epd_addr$location, ' ', 2)

# Split Street into street and city
epd_addr[c('street', 'city')] <- str_split_fixed(epd_addr$street, ',', 2)

# rewite anything with 'eugene' in it to epd's abbreviation
epd_addr$city[grepl('eugene', epd_addr$city)] <- 'eug'

# Remove white space from city column
epd_addr$city <- gsub(" ","",epd_addr$city)

# Join formatted city names from mapping
epd_openaddress_map <- read_csv('data/epd_city_abbr_map.csv')
epd_addr <- merge(x=epd_addr, y=epd_openaddress_map, by.x='city', by.y='epd_abbrv', all=FALSE)

# Part Two: load geo reference data

# Load open addresses
lane_addresses <- geojson_read("/home/russell/Data/GIS/OpenAddresses/lane-addresses-county.geojson",  what = "sp")

# create lower case street name column on lane_addresses
lane_addresses$lstreet <- tolower(lane_addresses$street)

# remove duplicate entries with same street, and city as a way to get 
# rid of apartments since epd logs dont record apts
lane_addresses <- lane_addresses[!duplicated(lane_addresses@data[c('street', 'number', 'city')]), ]

# merge the business records to geocoded addresses into temp data frame
logs_geocoded <- merge(x=lane_addresses, y=epd_addr,
                       by.x=c('number', 'lstreet', 'city'), 
                       by.y=c('number', 'street', 'city_name'),
                       all = FALSE)

# Part Two B: geo reference calls from the street intersection data set

# Load geo refernced Lane County street intersections
lane_intersections <- geojson_read("/home/russell/Data/GIS/lane_intersections/intersection3.geojson",  what = "sp")

# filter out unneeded columns
lane_intersections@data <- lane_intersections@data %>%
  select('PREFIX', 'PREFIX_2', 'NAME', 'NAME_2', 'TYPE', 'TYPE_2', 'LCITY')

# Drop rows that are empty for either street1 or street2
lane_intersections <- lane_intersections[!is.na(lane_intersections$PREFIX) | !is.na(lane_intersections$NAME) | !is.na(lane_intersections$TYPE),]
lane_intersections <- lane_intersections[!is.na(lane_intersections$PREFIX_2) | !is.na(lane_intersections$NAME_2) | !is.na(lane_intersections$TYPE_2),]

# format address parts and construct street1
lane_intersections$PREFIX[is.na(lane_intersections$PREFIX)] <- ' '
lane_intersections$NAME[is.na(lane_intersections$NAME)] <- ' '
lane_intersections$TYPE[is.na(lane_intersections$TYPE)] <- ' '
lane_intersections$street1 <- str_trim(tolower(paste(lane_intersections$PREFIX, lane_intersections$NAME, lane_intersections$TYPE)), 'both')

# format address parts and construct street2
lane_intersections$PREFIX_2[is.na(lane_intersections$PREFIX_2)] <- ' '
lane_intersections$NAME_2[is.na(lane_intersections$NAME_2)] <- ' '
lane_intersections$TYPE_2[is.na(lane_intersections$TYPE_2)] <- ' '
lane_intersections$street2 <- str_trim(tolower(paste(lane_intersections$PREFIX_2, lane_intersections$NAME_2, lane_intersections$TYPE_2)), 'both')

# parse location column in epd_inter dataset to street1 and street2
epd_inter[c('street1', 'street2')] <- str_split_fixed(epd_inter$location, '/', 2)

# format string2 into street and city
# Split Street into street and city
epd_inter[c('street2', 'city')] <- str_split_fixed(epd_inter$street2, ',', 2)

# rewite anything with 'eugene' in it to epd's abbreviation
epd_inter$city[grepl('eugene', epd_inter$city)] <- 'eug'

# Remove white space from city column
epd_inter$city <- gsub(" ","",epd_inter$city)

# Join formatted city names from mapping
epd_inter <- merge(x=epd_inter, y=epd_openaddress_map, by.x='city', by.y='epd_abbrv', all=FALSE)

# join address to georef 
logs_geocoded_street1 <- merge(x=lane_intersections, y=epd_inter,
                       by.x=c('street1', 'street2', 'LCITY'), 
                       by.y=c('street1', 'street2', 'city_name'),
                       all.x = TRUE) %>%
  filter(!is.na(resptime))

logs_geocoded_street2 <- merge(x=lane_intersections, y=epd_inter,
                               by.x=c('street1', 'street2', 'LCITY'), 
                               by.y=c('street2', 'street1', 'city_name'),
                               all.x = TRUE) %>%
  filter(!is.na(resptime))

# combine both sets of georefed data
logs_geocoded_inter <- rbind(logs_geocoded_street1, logs_geocoded_street2)

# combine epd_str and epd_inter georeffed logs
InBoth = intersect(colnames(logs_geocoded), colnames(logs_geocoded_inter))
all_geocoded = rbind(logs_geocoded[,InBoth], logs_geocoded_inter[,InBoth])

# Part Three: file output

# Write all out
write_csv(all_geocoded, paste0(out_folder, 'epd_dispatch_geocoded.csv'))

# Clean up
rm(epd_logs, epd_addr, lane_addresses, out_folder, epd_inter, 
   epd_openaddress_map, logs_geocoded, logs_geocoded_street1,
   logs_geocoded_street2, logs_geocoded_inter, logs_geocoded, 
   lane_intersections, InBoth)


