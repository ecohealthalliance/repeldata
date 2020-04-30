
# REPEL Data

Noam Ross, Emma Mendelsohn, Rob Young

---

### Overview

This package serves as a client interface for accessing the REPEL project database from R. It is currently EHA-only, but may become a public package for database access.

The database schema and description of sources can be viewed [here](https://github.com/ecohealthalliance/repel-docs/blob/master/database-schema.md).

You have the option to access the database remotely on our EHA server or to download it locally to your computer. The former option is best for exploratory data viewing and simple data manipulation. For analyses involving table joins and extensive data manipulation, we suggest the second option. 

### Install

```
remotes::install_github("ecohealthalliance/repeldata")
``` 

### Remote access
To access the remote database, you will need a REPEL username and password in your `.Renviron`. Please contact anyone on the REPEL team (Noam, Emma, Rob) to be provided a username and password.

The easiest way to edit your `.Renviron` is with the __usethis__ package:  

```
usethis::edit_r_environ()  
```

This will open your `.Renviron` file. Add the following lines, save, and then restart your R session: 

```
REPELDATA_USER=yourusername  
REPELDATA_PASSWORD=yourpassword
```

Once you have your permissions, you can launch the database connection from RStudio:

```
library(repeldata)  
repel_remote_pane()
```

The __Connections__ pane (on the top-right corner of the RStudio default layout) will show all tables available in the database. Clicking on the arrows will show the field names and types, and clicking on the table icon with bring the tables into Viewer. 

When you are done with your session, disconnect from the remote database.

```
repel_remote_disconnect()
```

### Local access

To access the local database, you will need a AWS access keys in your `.Renviron`. Please contact Noam to set up your AWS account.

The easiest way to edit your `.Renviron` is with the __usethis__ package:  

```
usethis::edit_r_environ()  
```

This will open your `.Renviron` file. Add the following lines, save, and then restart your R session: 

```
AWS_ACCESS_KEY_ID=yourkey
AWS_SECRET_ACCESS_KEY=yoursecretkey
AWS_DEFAULT_REGION=us-east-1
```

Once you have your permissions, you can download the data locally, and then launch the database connection from RStudio:

```
library(repeldata)
repel_local_download()
repel_local_pane()
```

As with the remote connection, the __Connections__ pane (on the top-right corner of the RStudio default layout) will show all tables available in the database. Clicking on the arrows will show the field names and types, and clicking on the table icon with bring the tables into Viewer. 

When you are done with your session, disconnect from the local database.

```
repel_local_disconnect()
```

### Interacting with data

To interact with the tables, you can establish a database connection (remote or local) and access tibbles without actually reading the data into memory. You can perform data manipulation on the tables and then collect the results using the __dplyr__ collect() function. This is especially handy for large tables for which you only need a subset of the data. 

```
library(dplyr)

conn <- repel_remote_conn() # this could also be repel_local_conn()
animal_diseases <- tbl(conn, "annual_reports_animal_diseases") %>% 
    filter(disease == "african swine fever") %>% 
    collect()

DBI::dbDisconnect(conn) # disconnect using the DBI package
```



