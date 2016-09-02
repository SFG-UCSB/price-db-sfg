# Reconstructing global ex-vessel prices of fished species

**Paper Authors**  
Dr. Mike Melnychuk<sup>1*</sup>    
Tyler Clavelle<sup>2+</sup>  
Brandon Owashi<sup>2</sup>  
C. Kent Strauss

<sup>1</sup>[School of Aquatic and Fishery Sciences](https://fish.uw.edu/), University of Washington, Seattle, WA 98195  
<sup>2</sup>[Sustainable Fisheries Group](http://sfg.msi.ucsb.edu/), University of California, Santa Barbara, CA 93106  
<sup>\*</sup>To whom correspondence regarding the paper should be addressed. Email: m.mel@u.washington.edu  
<sup>\+</sup>To whom correspondence regarding the code should be addressed. Email: tclavelle@bren.ucsb.edu

**Code Author**  
Tyler Clavelle ([GitHub](https://github.com/tclavelle?tab=repositories))   

## Overview
This GitHub repository contains the code and materials required to produce the global database of ex-vessel prices described in Melnychuk *et al.* (2016). The analysis relies entirely on data publicly available from the Food and Agriculture Organization of the United Nations (FAO). We have made the code publicly available so that other researchers and interested parties can produce the dataset for themselves. Additionally, the code can be rerun to update the database when future releases of the required FAO data files become available.   

The entire repository (code and data) can be downloaded as a zip file by clicking on the green button above. The code is written using the R language. If you do not currently use R or RStudio (IDE for R) you can download them at the following links:
+ [R](https://www.r-project.org)
+ [RStudio](https://www.rstudio.com)

GitHub users, please feel free to fork the repository and submit pull requests.
### Inputs
+ **R Script** - The `Price_DB_Construction.R` R script constructs and saves the ex-vessel price database

+ **FAO Data** - The `price-db-data` folder contains current versions of the required FAO data files, which include the [Fishery and Commodities and Trade database](http://www.fao.org/fishery/statistics/global-commodities-production/en) and [Appendix II – World fishery production: estimated value by groups of species](ftp://ftp.fao.org/FI/STAT/summary/appIIybc.pdf). The commodity data files are unprocessed files directly exported from FAO's [FishStatJ](http://www.fao.org/fishery/statistics/software/fishstatj/en) program. When updating these files, users must include the *Country*, *Commodity*, *ISSCAAP group*, and *Trade flow* variables in addition to the year columns   

  + `Commodity_quantity_76to13.csv`- Commodity production (tons) by country and trade flow (exports only)
  + `Commodity_value_76to13.csv`- Commodity value ($US 1,000) by country and trade flow (exports only)
  + `FAO exvessel estimates from archives.xlsx` - Production (1000 tons), value ($US millions), and ex-vessel price ($US/ton)  

Users can update the database in the future with new data by replacing the filenames in `Price_DB_Construction.R` with the filenames of updated data from the FAO. The ex-vessel estimates available in [Appendix II](ftp://ftp.fao.org/FI/STAT/summary/appIIybc.pdf) are currently stored in PDF format online and must be saved in an .xlsx file by the user for future updates

+ **Linkage Tables** - The `price-db-linkage-tables` folder contains the linkage tables required to construct the database per the methods described in Melnychuk *et al.* (2016) as well as assign and filter out commodities based on their level of processing

  + `Exvessel_tableS1.csv` - Linkage table 1
  + `Exvessel_tableS2.csv` - Linkage table 2
  + `Exvessel_tableS3.csv` - Linkage table 3
  + `processing assignments.csv` - Processing level assignments for each pooled commodity

### Outputs
Running `Price_DB_Construction.R` will create a results folder containing the following output files:
+ **Exvessel Price Database.csv** - Complete database of reconstructed ex-vessel prices for all FAO species items
+ **Expansion Factor Table.csv** - Expansion factors used to convert export prices to ex-vessel prices for each ISSCAAP group
