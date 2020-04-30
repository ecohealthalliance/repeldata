library(DBI)
library(dplyr)
conn <- repeldata::repel_local_conn()
animal_diseases <- tbl(conn, "annual_reports_animal_diseases_detail") %>% 
    filter(disease == "african swine fever") %>% 
    collect()

repeldata::repel_remote_disconnect()

repel_local_download()

dbDisconnect(conn)
