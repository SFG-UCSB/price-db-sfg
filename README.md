# Reconstructing global ex-vessel prices of fished species

### Authors
Dr. Mike Melnychuk (University of Washington)  
Tyler Clavelle (University of California, Santa Barbara)  
Brandon Owashi (University of California, Santa Barbara)  
Kent Strauss

## Overview
This GitHub repository contains the code and materials required to produce the global database of ex-vessel prices described in Melnychuk *et al.* (2016). The entire repository can be downloaded as a zip file or cloned to your machine by clicking on the green button above. For GitHub users, please feel free to fork the repository and submit a pull request with any improvements. The code is written using the R language. If you do not currently use R or RStudio (GUI for R) you can download them at the following links:
+ [R](https://www.r-project.org)
+ [RStudio](https://www.rstudio.com)

### Inputs
+ **Price_DB_Construction.R** - This R script constructs and saves the ex-vessel price database
+ **price-db-linkage-tables** - This folder contains the linkage tables required to construct the database

  + *Exvessel_tableS1.csv* - Linkage table 1
  + *Exvessel_tableS2.csv* - Linkage table 2
  + *Exvessel_tableS3.csv* - Linkage table 3
  + *processing assignments.csv* - Processing level assignments for each pooled commodity


+ **price-db-data** - This folder contains current versions of the required FAO data files and will be used by `Price_DB_Construction.R` to construct the database. Users can update the database in the future with new data by replacing the filenames in `Price_DB_Construction.R` with the filenames of updated data from the FAO
 
  + *Commodity_quantity_76to13.csv*
  + *Commodity_value_76to13.csv*
  + *FAO exvessel estimates from archives.xlsx*

Once the repository has been downloaded, the database can be constructed either by opening the `Price_DB_Construction.R` script and pressing *source* in RStudio, or by typing `source('path to repository'/Price_DB_Construction.R)`, where `'path to repository'` is the file path where you saved the repository folder.

### Outputs
Running `Price_DB_Construction.R` will create a results folder containing the following three output files:
+ **Exvessel Price Database.csv** - Complete database of reconstructed ex-vessel prices for all FAO species items
+ **Expansion Factor Table.csv** - Expansion factors used to convert export prices to ex-vessel prices for each ISSCAAP group
+ **Export Price Database.csv** - Complete compiled time series of quantities and values for every FAO Country-commodity pair
