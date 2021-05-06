#' Get location for local REPEL database
#'
#' @importFrom rappdirs user_data_dir
repel_local_path <- function() {
    path <- fs::dir_create(
        Sys.getenv("REPEL_DB_DIR", 
                   unset = rappdirs::user_data_dir("repeldata"))
    )
    path
}

repel_local_check_status <- function() {
    if (!repel_local_status(FALSE)) {
        stop("Local REPEL database empty or corrupt. Download with repel_local_download()") # nolint
    }
}

#' The local REPEL database
#'
#' Returns a connection to the local REPEL database. This is a DBI-compliant
#' [duckdb::duckdb()] database connection. 
#' 
#' @param dbdir The location of the database on disk. Defaults to
#' `repeldata` under [rappdirs::user_data_dir()], or the environment variable `WAHIS_DB_DIR`.
#'
#' @return A database connection
#' @importFrom arkdb local_db
#' @export
repel_local_conn <- function(dbdir = repel_local_path(), readonly = TRUE,
                             cache_connection = TRUE,
                             memory_limit = getOption("duckdb_memory_limit", NA)) {
    arkdb::local_db(dbdir = dbdir,
                    driver = "duckdb",
                    readonly = readonly,
                    cache_connection = cache_connection,
                    memory_limit = memory_limit)

}

#' Disconnect from the WAHIS database
#'
#' A utility function for disconnecting from the database.
#' @importFrom arkdb local_db_disconnect
#' @examples
#' repel_local_disconnect()
#' @export
#'
repel_local_disconnect <- function() {
    arkdb::local_db_disconnect(repel_local_conn())
}

