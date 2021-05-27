# this script gets field types from the remote db
# field descriptions manually entered on googlesheets
# save as inst file for easy access

devtools::load_all()
library(stringr)
library(googlesheets4)
conn <- repel_remote_conn()
tabs <- DBI::dbListTables(conn)
tabs2 <- tabs[str_starts(tabs, "annual_|outbreak_|connect_|country_|worldbank_")]

schema <- purrr::map_dfr(tabs2, function(tb){
    tb_q <- dbGetQuery(conn,
                       glue::glue("SELECT column_name, data_type 
                          FROM information_schema.columns
                          WHERE table_name = '{tb}'
                          ORDER  BY ordinal_position"))
    tb_q$table <- tb
    return(tb_q)
}) %>% as_tibble()

connect_ots_lookup <- dbReadTable(conn, "connect_ots_lookup") %>% 
    mutate(column_name = paste0("trade_dollars_", product_code)) %>% 
    mutate(description = paste("OTS - heads of", product_fullname_english)) %>% 
    select(-product_code, -product_fullname_english)

connect_fao_lookup <- dbReadTable(conn, "connect_fao_lookup") %>% 
    mutate(column_name = paste0("livestock_heads_", item_code)) %>% 
    mutate(description = paste("FAO - heads of", item)) %>% 
    select(-item_code, -item)

lookup <- bind_rows(connect_ots_lookup, connect_fao_lookup)

schema <- schema %>% 
    left_join(lookup)

# google drive to edit
gs4_create("repeldata-schema", sheets = list(fields = schema))
#TODO gsread

write_csv(schema, here::here("inst/database-field-schema.csv"))


