
# REPEL Data

Noam Ross, Emma Mendelsohn, Rob Young

---

### Overview

This package serves as a client interface for accessing the REPEL project database from R. It is currently EHA-only, but may become a public package for database access.

The database schema and description of sources can be viewed [here](https://github.com/ecohealthalliance/repel-docs/blob/master/database-schema.md). Field descriptions can be viewed as a tibble with `repeldata::repel_schema()`.


### Install

```
remotes::install_github("ecohealthalliance/repeldata")
``` 

### Database access

Download the data locally, and then launch the database connection from RStudio

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
animal_diseases <- tbl(conn, "annual_reports_animal_diseases") %>% 
    filter(disease == "african swine fever") %>% 
    collect()
```

When you are done with your session, disconnect from the database.

```
repel_local_disconnect()
```

### Remote access
Remote access to the database on our EHA server is available for development purposes. This will require a username and password provided by the REPEL team (Noam, Emma, Rob).

```
REPELDATA_USER=yourusername  
REPELDATA_PASSWORD=yourpassword
```

All `repel_local_x()` functions can be run as `repel_remote_x()` when using the remote database.






