# REPEL Data

Noam Ross, Emma Mendelsohn, Rob Young

---

## Overview

This package serves as a client interface for accessing the REPEL project database from R. It is currently EHA-only, but may become a public package for database access.

The REPEL database contains data curated from multiple sources of animal disease occurrence and covariates of disease spread (e.g., trade, animal movement). The database is regularly updated as new data becomes available. Here, we provide installation and usage instructions, followed by an overview of the tables in the database.

## Install and download

To install the package, you must have an active GitHub PAT saved in your `.Renviron` (which can be viewed via `usethis::edit_r_environ()`). If you do not have a PAT, or if it hasn't been used in over a year, follow the instructions here: https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token. Save your new token in your `.Renviron` as `GITHUB_PAT=yourtoken`. Restart your R session.

Install package from GitHub. 

```
remotes::install_github("ecohealthalliance/repeldata")
``` 
Download the data locally, and then launch the database connection from RStudio.

```
library(repeldata)
library(dplyr)

repel_local_download() # takes several minutes
repel_local_pane()
```

The __Connections__ pane (on the top-right corner of the RStudio default layout) will show all tables available in the database. Clicking on the arrows will show the field names and types, and clicking on the table icon with bring the tables into Viewer. 

To interact with the tables, you can establish a database connection and access tibbles without actually reading the data into memory. You can perform data manipulation on the tables and then collect the results using the __dplyr__ collect() function. This is especially handy for large tables for which you only need a subset of the data. 

```
conn <- repel_local_conn()
outbreak_reports_asf <- tbl(conn, "outbreak_reports_events") %>% 
    filter(disease == "african swine fever") %>% 
    collect()
```

When you are done with your session, disconnect from the database.

```
repel_local_disconnect()
```

## Remote access

Remote access to the database on our EHA server is available for development purposes. This will require a username and password provided by the REPEL team (Noam, Emma, Rob). Enter the following in your `.Renviron`

```
REPELDATA_USER=yourusername  
REPELDATA_PASSWORD=yourpassword
```

All `repel_local_x()` functions can be run as `repel_remote_x()` when using the remote database.

## Database structure 

Below is a high-level overview of all tables in the database. Descriptions of table fields can be viewed as a tibble with `repeldata::repel_fields_schema()` [WORK IN PROGRESS]

### WAHIS Tables

These tables contain disease reports and supplementary country attribute and health infrastructure information extracted from the [World Animal Health Information Database](https://wahis.oie.int/#/report-management) (WAHIS). Managed by the World Organization for Animal Health (OIE), WAHIS contains individual disease outbreak reports from 174 countries and territories; bi-annual disease summary reports; and annual country capacity reports. We download these reports from the OIE API and standardize them into structured tables.

#### Outbreak report tables

Outbreak tables are individual disease reports from data released on a weekly basis. Outbreaks are tracked as threads with new events continuously reported until the outbreak is resolved or the disease becomes endemic. 
  
* __outbreak_reports_ingest_status_log__  
List of reports in database. `report_info_id` can be appended to "https://wahis.oie.int/pi/getReport/" to see the report API, and to "https://wahis.oie.int/#/report-info?reportId=" to see the formatted outbreak report.

* __outbreak_reports_events__  
High-level event information including country, disease and disease status. Disease names are standardized to the [Animal Disease Ontology](http://agroportal.lirmm.fr/ontologies/ANDO]) from the French National research institute for agriculture, food and the environment. Each row is an outbreak report. `report_id` is the unique report ID.

* __outbreak_reports_outbreaks__  
Detailed location and impact data for outbreak events. This table can be joined with `outbreak_reports_events` by `report_id`. `outbreak_location_id` is a unique ID for each location (e.g, farm or village) within a outbreak. The field `id` is the unique combination of the `report_id`, `outbreak_location_id`, and `taxa`.

* __outbreak_reports_diseases_unmatched__  
Disease names that were not successfully matched against the ANDO database. These require manual review. Note that these diseases are not removed from the database.

#### Six month report tables

* __six_month_reports_ingest_status_log__  
List of `report_id` in database. Report API is available via `paste0("https://wahis.oie.int/smr/pi/report/", report_id, "?format=preview")`. Formatted reports can be viewed as `https://wahis.oie.int/#/report-smr/view?reportId=20038&period=SEM01&areaId=2&isAquatic=false`.

* __six_month_reports_summary__  
High-level six-month disease data. It provides disease status (present/absent/unreported) and case counts by country, disease, taxa. It also includes control measures. Disease names are standardized to the [Animal Disease Ontology](http://agroportal.lirmm.fr/ontologies/ANDO]) from the French National research institute for agriculture, food and the environment. 

* __six_month_reports_detail__  
Case data at finer temporal and/or spatial resolutions, as available.

* __six_month_reports_diseases_unmatched__  
Disease names that were not successfully matched against the ANDO database. These require manual review. Note that these diseases are not removed from the database.

#### Annual report tables

Annual report tables include information about country capacity and taxa population. 
 _Note that these tables will be updated when the API becomes available for annual reports._

* __annual_reports_status__  
Indicates whether reports are available through WAHIS for all countries, years, and semesters

* __annual_reports_ingest_status_log__  
Indicates whether reports available through WAHIS were successfully downloaded and included in the REPEL database. Error messages are provided for reports that were not successfully included.  

* __annual_reports_submission_info__  
Point of contact information for country submitter

* __annual_reports_animal_population__  
Reported populations of animals by country

* __annual_reports_veterinarians__  
Counts of veterinarians by country

* __annual_reports_national_reference_laboratories__  
Names and contact information for testing laboratories within countries

* __annual_reports_national_reference_laboratories_detail__  
Laboratory testing capability by disease

* __annual_reports_vaccine_manufacturers__  
Names and contact information for vaccine production laboratories within countries

* __annual_reports_vaccine_manufacturers_detail__  
Vaccine production capability by disease

* __annual_reports_vaccine_production__  
Vaccine doses produced and exported

### Non-WAHIS Tables

These tables contain non-disease endpoints from multiple sources representing covariates of disease spread. Connect data are values shared between two countries (e.g., trade value). 

* __connect_static__ tables  
Connect values without a temporal component. Static data are non-directional, meaning that values from Country A -> Country B are the same as values from B -> A.  

  * `connect_static_shared_borders` - shared borders (True or False)
  * `connect_static_country_distance` - Geodesic distance between country centroids in meters
  * `connect_static_bli_bird_migration` - Number of migratory birds shared by countries based on country migratory avian species lists from [BirdLife International](http://datazone.birdlife.org/country)
  * `connect_static_iucn_wildlife_migration` - Number of migratory non-avian wildlife shared by countries based on country species lists from the [IUCN Red List API](https://apiv3.iucnredlist.org/) and the global migratory species list from the [Global Register of Migratory Species](http://groms.de/groms_neu/view/order_stat_patt_spanish.php?search_pattern=)
<br/><br/>
* __connect_yearly__ tables  
Connect values that vary by year. Yearly data are directional, meaning that values from Country A -> Country B differ from values from B -> A.  

  * `connect_yearly_un_human_migration` - Number of human migrants from the [United Nations Population Division Global Migration Database](https://www.un.org/en/development/desa/population/migration/data/empirical2/index.asp)
  * `connect_yearly_wto_tourism` - Number of tourists from the [United Nations World Tourism Organization](https://www.e-unwto.org/)
  * `connect_yearly_fao_livestock` - Count of traded livestock heads from the [Food and Agriculture Organization](http://www.fao.org/faostat/en/#data/). `connect_yearly_fao_livestock_summary` summarizes total livestock heads by trade partners. 
  * `connect_yearly_ots_trade` - Agricultural trade dollars from the Open Trade Statistics API, accessed using the [tradestatistics](https://cran.r-project.org/web/packages/tradestatistics/tradestatistics.pdf) R package. Includes following reporting groups: "Foodstuffs","Animal and Vegetable Bi-Products", "Vegetable Products", "Animal Hides",  "Animal Products". `connect_yearly_ots_trade_summary` summarizes total agricultural trade dollars by trade partners. 
<br/><br/>
* __country_yearly__ tables  
Country-specific values that vary by year.

  * `country_yearly_wb_gdp` - Country GDP in dollars from WorldBank
  * `country_yearly_wb_human_population` - Country human population from WorldBank
  * `country_yearly_fao_taxa_population` - Population of key taxa from FAO
  * `country_yearly_oie_vet_population` - Veterinarians in country from OIE annual reports

### Model predictions

* __network_lme_augment_predict__  
Augmented outbreak data with network LME model predictions

* __network_lme_augment_predict_by_origin__  
Augmented outbreak data disaggregated by country origins from outbreaks


