#' Connect to the remote REPEL database
#' 
#' Returns a connection to the remote REPEL database, hosted on a Postgres server.
#' `REPELDATA_USER` and `REPELDATA_PASSWORD` should be set in your environment
#' (e.g. `.Renviron` file) to provide access to the data.
#' 
#' @param host The host URL.  Defaults to the EHA server
#' @param port the host connection port.  Generally does not need to be set
#' @param user User login name.  In general to be set in `.Renviron`
#' @param password User login passwword. In general to be set in `.Renviron`
#'
#' @return a DBI connection object
#' @export
#'
repel_remote_conn <- function(host = NULL, port = NULL, user = NULL, password = NULL) {
    conn <- DBI::dbConnect(
        RPostgres::Postgres(),
        host = host %||%  Sys.getenv("REPEL_REMOTE_HOST", "kirby.ecohealthalliance.org"),
        port = port %||% Sys.getenv("REPEL_REMOTE_PORT", 22053),
        user = user %||% Sys.getenv("REPELDATA_USER"),
        password = password %||% Sys.getenv("REPELDATA_PASSWORD"),
        dbname = "repel"
    )
    return(conn)
}


#' Disconnect from the remote REPEL database
#' 
#' @return 
#' @export
#' 
#' @examples 
repel_remote_disconnect <- function(){
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionClosed("Postgres", "repelremote")
    }
}