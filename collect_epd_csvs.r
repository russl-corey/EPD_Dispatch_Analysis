# Filename: collect_epd_csvs.r
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

# set working directory to data folder
setwd('/home/russell/Dropbox/DataAnalysis/EPD_Response_Times/')
csv_folder <- "/home/russell/Documents/scrape_epd/"

# PART ONE: load data and filter oregon records

# Make a list of all the available open address files

files <- paste0(csv_folder, list.files(csv_folder, pattern='.csv$'))

# init empty var for data
csv_data <- c()

for(file in files){
  # update user
  print(paste('processing: ', file))
  
  # read csv file
  data <- read_csv(file)
  
  # append loaded data to or_data
  csv_data <- rbind(csv_data, data)
}

# cleanup
rm(data)

# drop empty rows
#csv_data <- csv_data[!is.na(o_data$LoanNumber), ]  

# save records
write_csv(csv_data, 'data/epd_logs.csv')

