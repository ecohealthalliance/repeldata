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
#' @importFrom DBI dbIsValid dbConnect dbIsReadOnly
#' @importFrom duckdb duckdb
#' @export
repel_local_conn <- function(dbdir = repel_local_path()) {
    db <- mget("repel_local_conn", envir = repel_cache, ifnotfound = NA)[[1]]
    if (inherits(db, "DBIConnection")) {
        if (DBI::dbIsValid(db)) {
            return(db)
        }
    }
    dbname <- path(dbdir, "repeldata", ext = "db")
    
    tryCatch(
        {
            gc(verbose = FALSE)
            db <- DBI::dbConnect(duckdb::duckdb(), dbdir = dbname)
        },
        error = function(e) {
            if (grepl("(Database lock|bad rolemask)", e)) {
                stop(paste(
                    "Local WAHIS database is locked by another R session.\n",
                    "Try closing or running repel_local_disconnect() in that session."
                ),
                call. = FALSE
                )
            } else {
                stop(e)
            }
        },
        finally = NULL
    )
    
    assign("repel_local_conn", db, envir = repel_cache)
    db
}

#' Disconnect from the WAHIS database
#'
#' A utility function for disconnecting from the database.
#'
#' @examples
#' repel_local_disconnect()
#' @export
#'
repel_local_disconnect <- function() {
    repel_local_disconnect_()
}
repel_local_disconnect_ <- function(environment = repel_cache) { # nolint
    db <- mget("repel_local_conn", envir = repel_cache, ifnotfound = NA)[[1]]
    if (inherits(db, "DBIConnection")) {
        gc(verbose = FALSE)
        DBI::dbDisconnect(db, shutdown = TRUE)
    }
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionClosed("MonetDB", "repellocal")
    }
}

repel_cache <- new.env()
reg.finalizer(repel_cache, repel_local_disconnect_, onexit = TRUE)


