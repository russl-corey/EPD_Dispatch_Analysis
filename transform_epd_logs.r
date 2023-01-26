# Filename: transform_epd_logs.r
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
library(stringr)
library(dplyr)
require(chron)

# set working directory to data folder
setwd('/home/russell/Dropbox/DataAnalysis/EPD_Response_Times/')

# PART ONE: load raw dispatch data data
epd_logs <- read_csv('data/epd_logs.csv')

# PART TWO: proccess dates

# Format datetimes to proper date time objects
epd_logs$calltime <- as.POSIXct(epd_logs$`Call Time   `, format = "%m/%d/%Y %I:%M:%S %p")
epd_logs$disptime <- as.POSIXct(epd_logs$`Dispatch Time   `, format = "%m/%d/%Y %I:%M:%S %p")

# Calculate response time
epd_logs$resptime_min <- as.numeric(difftime(epd_logs$disptime, epd_logs$calltime, units = "mins"))
epd_logs$resptime <- as.integer(difftime(epd_logs$disptime, epd_logs$calltime, units = "mins"))

# Filter out negative response times
epd_logs <- epd_logs[epd_logs$resptime > 0,]
epd_logs <- epd_logs[!is.na(epd_logs$resptime),]

# embed date and day of week
epd_logs$call_date <- as.Date(epd_logs$`Call Time   `, format = "%m/%d/%Y")
epd_logs$call_year <- format(epd_logs$call_date,"%Y")
epd_logs$call_month <- format(epd_logs$call_date,"%m")
epd_logs$weekday <- weekdays(epd_logs$calltime)


# PART THREE: encode part 1 crimes

# define part  1 crimes
part1_list <- part1 <- c('Forcible Rape', 'Robbery', 'Assault 4', 'Burglary', 'Theft',  'Arson')

# make subset of dispatch calls that are part1
epd_part1 <- epd_logs[epd_logs$`Incident Desc   ` %in% part1_list,]

# encode true/false onto original data frame
epd_logs$part1 <- FALSE
epd_logs$part1[epd_logs$`Incident Desc   ` %in% part1_list] <- TRUE

# PART FOUR: encode bussiness locations

# Prepare EPD dispatch logs to merge to business logs

# set to lower case
epd_logs$location <- tolower(epd_logs$`Location   `)

# Seperate the numbered addresses from street intersections
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

# load all active business data set
Active_Businesses_ALL <- read_csv("/home/russell/Data/data.oregon.gov/Active_Businesses_-_ALL.csv")

# make subset of only mailing addresses
business_addresses <- Active_Businesses_ALL[Active_Businesses_ALL$`Associated Name Type` == 'MAILING ADDRESS',]

#rename column by name
business_addresses$city <- tolower(business_addresses$City)
business_addresses$address <- tolower(business_addresses$Address)
business_addresses[c('number', 'street')] <- str_split_fixed(business_addresses$address, ' ', 2)

# select only Eugene business addresses
business_addresses <- business_addresses[business_addresses$city == 'eugene', ]

# Split business address into number and street
business_addresses[c('number', 'street')] <- str_split_fixed(business_addresses$address, ' ', 2)

# merge the business records to geocoded addresses into temp data frame
biz_calls <- merge(x=business_addresses, y=epd_addr,
                       by.x=c('number', 'street'), 
                       by.y=c('number', 'street'),
                       all = FALSE)

# embeded true/false for business location to original data
epd_logs$business <- FALSE
epd_logs$business[epd_logs$`Event Number   ` %in% biz_calls$`Event Number   `] <- TRUE

# FINAL PART: write out logs and cleanup

# Write out logs
write_csv(epd_logs, 'data/epd_logs_resptime.csv')

# clean up
rm(part1, part1_list, epd_part1, epd_logs, Active_Businesses_ALL, biz_calls, 
   business_addresses, epd_addr, epd_inter, epd_openaddress_map)
