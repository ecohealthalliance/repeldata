library(DBI)
library(tidyverse)
conn <- repel_remote_conn()


dbListTables(conn)
tbl(conn, "annual_reports_status")

dbDisconnect(conn)
