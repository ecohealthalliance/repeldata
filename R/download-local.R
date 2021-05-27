#' Download the REPEL database to your local computer
#'
#' This command downloads the REPEL shipments database and populates a local
#' database. Note that you need EHA AWS access to do so for now.
#'
#' The database is stored by default under [rappdirs::user_data_dir()], or its
#' location can be set with the environment variable `REPEL_DB_DIR`.
#'
#' @param destdir Where to download the compressed files.
#' @param cleanup Whether to delete the compressed files after loading into the database.
#' @param verbose Whether to display messages and download progress
#' @param load_aws_credentials Whether to use credentials from [aws.signature::use_credentials()].  If FALSE, AWS credentials must be provided as environment variables.
#' @param raw_data_only Whether to download only raw data. TRUE includes REPEL model predictions.

#'
#' @return NULL
#' @export
#' @import dplyr stringr
#' @importFrom arkdb unark streamable_readr_csv
#' @importFrom readr read_csv
#' @importFrom aws.s3 save_object get_bucket_df
#' @importFrom fs dir_create path
#' @importFrom rlang parse_expr
#' @examples
#' \donttest{
#' \dontrun{
#' repel_local_download()
#' }
#' }
#TODO get AWS LastModified
repel_local_download <- function(destdir = tempfile(),
                                 cleanup = TRUE, verbose = interactive(),
                                 load_aws_credentials = FALSE,
                                 raw_data_only = FALSE) {
    
    if(load_aws_credentials && requireNamespace("aws.signature", quietly = TRUE)) {
        aws.signature::use_credentials()  
    }
    
    #Hide readr progress bars
    oldopt <- options("readr.show_progress")
    options(readr.show_progress = FALSE)
    on.exit(options(readr.show_progress = oldopt))
    
    # Get files to download
    data_files_df <- aws.s3::get_bucket_df("repeldb", prefix = "csv") %>% 
        filter(!grepl("(raster_|spatial_ref_sys)", Key)) #Exclude raster data only supported by postGIS
    
    if(raw_data_only){
        data_files_df <- data_files_df %>% 
            filter(stringr::str_detect(Key, "annual_|outbreak_|connect_|country_|worldbank_"))
    }
    
    # Clear local database prior to download
    repel_local_delete()
    fs::dir_create(destdir)
    
    # Load schema for field types
    schema <- repel_fields_schema()
    
    # Download data
    if (verbose) message("Downloading data...\n")
    purrr::walk(data_files_df$Key, function(key) {
        
        f = fs::path(destdir, basename(key))
        save_object(object = key, bucket = "repeldb", file = f)
        field_type_lookup <- schema %>% 
            filter(table == stringr::str_remove_all(key, ".csv.xz|csv/")) %>% 
            mutate(row_name = paste0(column_name, " = ", data_type))
        field_types <- paste0("cols(", paste(field_type_lookup$row_name, collapse = ", "), ")")
        
        tryCatch({
            print(key)
            arkdb::unark(f, repel_local_conn(readonly = FALSE), lines = 100000, 
                         overwrite = TRUE, streamable_table = repel_streamable_readr_csv(), 
                         col_types = eval(rlang::parse_expr(field_types)), 
                         guess_max = 100000,
                         try_native = FALSE)
        }, error=function(e){cat("ERROR :", conditionMessage(e), "\n")})
        if (cleanup) file.remove(f)
    })
    if (verbose) message("Calculating Stats...\n")
    DBI::dbWriteTable(repel_local_conn(readonly = FALSE), "repel_local_status", make_local_status_table(),
                      overwrite = TRUE)
    update_local_repel_pane()
    if (verbose) message("Done!")
    repel_local_disconnect()
}

#' Get the status of the current local REPEL database
#'
#' @param verbose Whether to print a status message
#'
#' @return TRUE if the database exists, FALSE if it is not detected. (invisible)
#' @export
#' @importFrom DBI dbExistsTable
#' @importFrom tools toTitleCase
#' @examples
#' repel_local_status()
repel_local_status <- function(verbose = TRUE) {
    if (DBI::dbExistsTable(repel_local_conn(), "repel_local_status")) {
        status <- DBI::dbReadTable(repel_local_conn(), "repel_local_status")
        status_msg <-
            paste0(
                "REPEL database status:\n",
                paste0(toTitleCase(gsub("_", " ", names(status))),
                       ": ", as.matrix(status),
                       collapse = "\n"
                )
            )
        out <- TRUE
    } else {
        status_msg <- "Local REPEL database empty or corrupt. Download with repel_local_download()" #nolint
        out <- FALSE
    }
    if (verbose) message(status_msg)
    invisible(out)
}

#' @importFrom DBI dbGetQuery
#' @importFrom purrr map_dbl
#' @importFrom tibble tibble
make_local_status_table <- function() {
    sz <- sum(file.info(list.files(repel_local_path(),
                                   all.files = TRUE,
                                   recursive = TRUE,
                                   full.names = TRUE))$size)
    class(sz) <- "object_size"
    tables <- DBI::dbListTables(repel_local_conn())
    records = sum(map_dbl(tables, ~DBI::dbGetQuery(repel_local_conn(), paste0("SELECT COUNT(*) FROM ", ., ";"))[[1]]))
    tibble(
        time_imported = Sys.time(),
        number_of_tables = length(tables),
        number_of_records = formatC(records, format = "d", big.mark = ","),
        size_on_disk = format(sz, "auto"),
        location_on_disk = repel_local_path()
    )
}


#' Remove the local REPEL database
#'
#' Deletes all tables from the local database
#'
#' @return NULL
#' @export
#' @importFrom DBI dbListTables dbRemoveTable
#'
#' @examples
#' \donttest{
#' \dontrun{
#' repel_local_delete()
#' }
#' }
repel_local_delete <- function() {
    x <- try(repel_local_disconnect(), silent = TRUE)
    if (inherits(x, "try-error")) {
        fs::dir_delete(repel_local_path())
    } else {
        for (t in dbListTables(repel_local_conn(readonly = FALSE))) {
            dbRemoveTable(repel_local_conn(readonly = FALSE), t)
        }
    }
    #update_local_repel_pane()
}



