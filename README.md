# EPD_Dispatch_Analysis
Analyze spatial, temporal, and catagorical patterns in Eugene Police Department response times to Dispatch Calls.

# Inputs and Outputs

## Inputs

# Scripts

The steps are broken into seperate scripts

  * transform_epd_logs.r
  * collect_epd_csvs.r
  * Geocode_Logs.r

### transform_epd_logs.r

Reads in:

   * data/epd_logs.r
   * data/epd_city_abbr_map.csv
   * "data.oregon.gov/Active_Businesses_-_ALL.csv" (from external directory)
   
  and performs data cleaning, formatting and embedding. Writes out 
  
    * data/epd_logs_resptime.csv
    
### collect_epd_csvs.r

reads in all the sepearte logs

Writes out: 

  * data/epd_logs.csv


### geocode_logs.r

Reads in:

  * data/epd_logs_resptime.csv
  * GIS/OpenAddresses/lane-addresses-county.geojson (external)
  
