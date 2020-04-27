#' @importFrom rappdirs user_data_dir
repel_local_path <- function() {
    Sys.getenv("REPEL_DB_DIR", unset = rappdirs::user_data_dir("repeldata"))
}

repel_local_check_status <- function() {
    if (!repel_local_status(FALSE)) {
        stop("Local REPEL database empty or corrupt. Download with repel_local_download()") # nolint
    }
}

#' The local WAHIS database
#'
#' Returns a connection to the local WAHIS database. This is a DBI-compliant
#' [MonetDBLite::MonetDBLite()] database connection. When using **dplyr**-based
#' workflows, one typically accesses tables with functions such as
#' [wahis_shipments()], but this function lets one interact with the database
#' directly via SQL.
#'
#' @param dbdir The location of the database on disk. Defaults to
#' `wahisclient` under [rappdirs::user_data_dir()], or the environment variable `WAHIS_DB_DIR`.
#'
#' @return A MonetDBLite DBI connection
#' @importFrom DBI dbIsValid dbConnect
#' @importFrom MonetDBLite MonetDBLite
#' @export
repel_local_conn <- function(dbdir = repel_local_path()) {
    db <- mget("repel_local_conn", envir = repel_cache, ifnotfound = NA)[[1]]
    if (inherits(db, "DBIConnection")) {
        if (DBI::dbIsValid(db)) {
            return(db)
        }
    }
    dbname <- dbdir
    dir.create(dbname, FALSE)
    
    tryCatch(
        {
            gc(verbose = FALSE)
            db <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbname = dbdir)
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

#' repel_remote_disconnect()
#' @export
repel_remote_disconnect <- function(){
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionClosed("Postgres", "repelremote")
    }
}
