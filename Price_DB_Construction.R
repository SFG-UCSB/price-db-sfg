##################################################################---------------------------------------------------------------------
#
# Melnychuck et al. (2016) Reconstruction of global ex-vessel prices of fished species
# 
# Code by Tyler Clavelle (tclavelle@bren.ucsb.edu)
#
# Code description: This code constructs the global ex-vessel price database as per Melnychuch et al. (2016). It relies entirely on publicly
# avaliable FAO data and can produce an updated ex-vessel price database with each new release of FAO data.
#
##################################################################---------------------------------------------------------------------


##############################################################################################################
### Data Preparation -------------------------------------------------------------------------------------------------------------------

# Create directory to save results
dir.create('price-db-results/',recursive = T)

# List of neccessary packages
pkgs <- c('tidyr', 'dplyr', 'ggplot2', 'readxl')

# Check to see if packages are already installed and install if not
if(any(pkgs %in% installed.packages() == F) == F) {

  # load packages
  library(tidyr)
  library(dplyr)
  library(ggplot2)
  library(readxl)  

} else { # install missing packages and then load all
  install.packages(pkgs[pkgs %in% installed.packages() == F])
  sapply(pkgs, FUN = library())
}

## Read in data
# Linkage tables
link1<-read.csv('price-db-data/price-db-linkage-tables/exvessel_tableS1.csv',stringsAsFactors = F)
link2<-read.csv('price-db-data/price-db-linkage-tables/exvessel_tableS2.csv',stringsAsFactors = F)
link3<-read.csv('price-db-data/price-db-linkage-tables/exvessel_tableS3.csv',stringsAsFactors = F)

# Updated commodity data
cvalue<-read.csv('price-db-data/Commodity_value_76to13.csv', stringsAsFactors = F, na.strings = c('...','0 0','-')) # value in 1000s
cquantity<-read.csv('price-db-data/Commodity_quantity_76to13.csv', stringsAsFactors = F,na.strings = c('...','0 0','-')) # quantity in tons

# FAO estimated ex-vessel data by ISSCAAP group
faoprices <- read_excel('price-db-data/FAO exvessel estimates from archives.xlsx', sheet = 4)

## Set options for database 
lowprocess <- FALSE # for using all commodities or just low processed commodities
commod_min <- 100 # minimum quantity required for inclusion in export price calculation
 

###############################################################################
## Process FAO ----------------------------------------------------------------

# Function to reshape value and quantity tables to long format
golong<-function(data) data %>% tbl_df() %>% gather('Year',Value,contains('X'),convert=T)

# apply function to datasets
cvalue<-golong(cvalue)

cquantity<-golong(cquantity) %>%
  rename(Quantity = Value) # rename value variable to quantity

# Strip X from Year
cvalue$Year<-as.numeric(gsub('X','',cvalue$Year))
cquantity$Year<-as.numeric(gsub('X','',cquantity$Year))


##############################################################################################################
### Commodity Processing -------------------------------------------------------------------------------------------------------------------

# join value and quantity tables so they only include matched pairs
cboth<- inner_join(cvalue,cquantity)

# remove contested commodity "Miscellaneous crustaceans, not frozen, nei" due to apparent errors in data
cboth <- subset(cboth, Commodity..Commodity. != 'Miscellaneous crustaceans, not frozen, nei')

# strip ' F' from values and convert to numeric
cboth$Value<-as.numeric(gsub(pattern = ' F', replacement = '',cboth$Value))
cboth$Quantity<-as.numeric(gsub(pattern = ' F', replacement = '',cboth$Quantity))

# clean up column names
cboth1<- cboth %>%
  rename(Country        = Country..Country.,
         FAO_commodity  = Commodity..Commodity.,
         TradeFlow      = Trade.flow..Trade.flow.)

# standardize missing values to NAs
fix<-cboth1$Quantity==0 | cboth1$Value==0 | is.na(cboth1$Quantity) | is.na(cboth1$Value)

cboth1$Quantity[fix]<-NA
cboth1$Value[fix]<-NA

# Subset data to exclude highly processed categories if desired
if(lowprocess == T) {
  
  process <- read.csv(file = 'price-db-data/processing assingments.csv')
  
  lows <- filter(process, assingment == 'low')
  
  cboth1 <- filter(cboth1, FAO_commodity %in% lows$FAO_commodity)
}

# Calculate country export prices
cboth1<-cboth1 %>%
  mutate(Export_Price = 1000 * (Value) / Quantity)

# aggregate country values to get aggregate quantities and values by commodity and match to linkage table one
# to include pooled commodity category
agg<-cboth1 %>%
  group_by(FAO_commodity,Year) %>%
  summarize(TotalQuantity=sum(Quantity,na.rm=T),TotalValue=sum(Value,na.rm=T)) %>%
  left_join(link1) %>%
  filter(is.na(pooled_commodity)==F) %>%
  ungroup()

# aggregate across pooled commodities
agg<-agg %>%
  group_by(pooled_commodity,group_for_pairing,Year) %>%
  summarize(PooledQuantity = sum(TotalQuantity,na.rm=T),
            PooledValue    = sum(TotalValue,na.rm=T)) %>%
  mutate(PooledPrice       = PooledValue/PooledQuantity) %>% 
  ungroup()

# aggregate over ISSCAAP
aggisscaap<- agg %>%
  group_by(group_for_pairing,Year) %>%
  summarize(ISSCAAPQuantity  =  sum(PooledQuantity,na.rm=T),
            ISSCAAPValue     =  sum(PooledValue,na.rm=T)) %>%
  mutate(ISSCAAPPrice        =  ISSCAAPValue/ISSCAAPQuantity) %>%
  ungroup()


##############################################################################################################  
### FAO Exvessel Processing ----------------------------------------------------------------------------------------------------------------

# Filter FAO price data to appropriate level and rename variables to more convenient names
faoexvessel<-faoprices %>%
  filter(is.na(`Species group`)==F & `Species group`!='World total' & `Prod type`=='Capture fisheries' & Archive < 2014) %>%
  spread(Units,Value) %>%
  mutate(Year           = as.integer(Year)) %>%
  rename(Quantity_1000s = `1 000 t`,
         Value_Millions = `US$ mill`,
         Price_PerTon   = `US$/t`,
         group_for_pairing = `Species group`)

# Pull out earlies year from archives prior to 2012
archive_pull <- function(df, year) {
  temp <- df %>%
    filter(Year == year) %>%
    filter(Archive == max(Archive, na.rm = T))
  return(temp)
}

# Loop over unique years and apply archive_pull function
yrs <- unique(faoexvessel$Year)
exv <- list()
for(a in 1:length(yrs)) {
  exv[[a]] <- archive_pull(faoexvessel, year = yrs[a])
}

# flatten list into data frame
faoexvessel <- bind_rows(exv)

# rename miscellaneous animal products to miscellaneous aquatic invertebrates
faoexvessel$group_for_pairing[faoexvessel$group_for_pairing=='Miscellaneous aquatic animals']<-'Miscellaneous aquatic invertebrates'


##############################################################################################################
### Expansion Factor Calculation -----------------------------------------------------------------------------

# join export and exvessel data and calculate expansion factor as export/exvessel
expansion <- left_join(aggisscaap,faoexvessel) %>%
  filter(Year<2013) %>%
  mutate(ISSCAAPPrice = 1000*ISSCAAPPrice,
         expfactor    = ISSCAAPPrice/Price_PerTon)


##############################################################################################################
## Extrapolate missing values for 1976-1994

# calculate the weighted expansion factor
wt_expansion <- expansion %>% 
  tbl_df() %>%
  filter(Year>=1994) %>%
  group_by(group_for_pairing) %>%
  summarize(exvessel_wt_mean = (1000000*sum(Value_Millions,na.rm=T)) / (1000*(sum(Quantity_1000s,na.rm=T))),
            export_wt_mean   = (1000*sum(ISSCAAPValue,na.rm=T))/(sum(ISSCAAPQuantity,na.rm=T)),
            wt_exp_factor    = export_wt_mean / exvessel_wt_mean) 

# extract data for years with exvessel and export prices and calculate the median and mean exp factors
hist_factor <- expansion %>%
  filter(Year>=1994) %>%
  group_by(group_for_pairing) %>%
  summarize(med_exp_factor   = median(expfactor,na.rm=T),
            mean_exp_factor  = mean(expfactor,na.rm=T))

# use calculated median (or mean) expansion factors to estimate exvessel prices for 1976-1994  
needs_price<-expansion %>%
  tbl_df() %>%
  filter(Year<1994) %>%
  left_join(hist_factor) %>%
  mutate(Price_PerTon = ISSCAAPPrice / med_exp_factor)

# rejoin the timeseries
expansion<-expansion %>%
  filter(Year>=1994) %>%
  bind_rows(needs_price) %>%
  arrange(group_for_pairing,Year) 

# fill in expfactor variable for '76-'94 with the calculated expfactor of choice (median or mean) 
expansion$expfactor[is.na(expansion$expfactor)] <- expansion$med_exp_factor[is.na(expansion$expfactor)]


##############################################################################################################
### Exvessel Calculation -------------------------------------------------------------------------------------

# join pooled commodities with expansion factors
aggexvessel<-left_join(agg,expansion) 

# convert PooledValue from 1000s to dollars
aggexvessel$PooledValue<- aggexvessel$PooledValue*1000
  
# recalculate pooled price
aggexvessel$PooledPrice<- aggexvessel$PooledValue/aggexvessel$PooledQuantity
  
# calculate ex-vessel price using inverse expansion factor
aggexvessel$exvessel<- aggexvessel$PooledPrice/aggexvessel$expfactor

# join exvessel estimates with linkage table 3 to match exvessel prices to species
database<-left_join(link3,aggexvessel)


### Format and Save Database and Intermediate Tables ---------------------------------------------------------------------------------------

# Save export data
write.csv(cboth1, file = 'price-db-results/Export Price Database.csv')

# Save expansion factor table
write.csv(expansion, file = 'price-db-results/Exvessel Expansion Factor Table.csv')

# Save final database
write.csv(database, file = 'price-db-results/Exvessel Price Database.csv')

