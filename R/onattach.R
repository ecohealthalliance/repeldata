# .onAttach <- function(libname, pkgname) {
#     MonetDBLite::monetdblite_shutdown()
#     if (interactive() && Sys.getenv("RSTUDIO") == "1") {
#         wahis_pane()
#     }
# }

#' Remove the local WAHIS database
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
    for (t in dbListTables(repel_local_conn())) {
        dbRemoveTable(repel_local_conn(), t)
    }
    update_local_repel_pane()
}

#' Get the status of the current local WAHIS database
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
                "WAHIS database status:\n",
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
