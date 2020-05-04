library(repeldata)
library(DBI)
library(tidyverse)

### See readme to set up environment variables to be able to access the data

# View data ---------------------------------------------------------------
repel_remote_pane()
repel_remote_disconnect()

# Explore data ------------------------------------------------------------

# connect to the remote database
conn <- repel_remote_conn()

# get table names and schema
tables <- DBI::dbListTables(conn)
schema <- repel_schema()

# get annual report status
annual_status <- dplyr::tbl(conn, "annual_reports_status") %>% 
    collect()

annual_status %>% 
    filter(report_semester == "0", 
           reported) %>% 
    group_by(report_year) %>% 
    summarize(n_countries = n_distinct(country_iso3c)) %>% 
    ungroup() %>% 
    ggplot(., aes(x = report_year, y = n_countries)) +
    geom_bar(stat = "identity") 

# get animal diseases

ad <- tbl(conn, "annual_reports_animal_diseases")

ad_asf <- ad %>% 
    filter(disease == "african swine fever",
           report_semester == "0",
           report_year == "2017") %>% 
    collect()

ad_asf %>% 
    distinct(country, new_outbreaks, total_outbreaks, taxa) %>% 
    arrange(-new_outbreaks) %>% 
    View()

ah <- tbl(conn, "annual_reports_animal_hosts")

ah_asf <- ah %>% 
    filter(disease == "african swine fever",
           report_semester == "0",
           report_year == "2017") %>% 
    collect()

ah_asf %>% 
    distinct(country, taxa, 
             susceptible, cases, deaths, killed_and_disposed_of, slaughtered,vaccination_in_response_to_the_outbreak) %>% 
    arrange(-cases) %>% 
    View()

# disconnect
DBI::dbDisconnect(conn)
