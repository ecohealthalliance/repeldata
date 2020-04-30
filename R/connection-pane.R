#' Open REPEL database connection pane in RStudio
#'
#' This function launches the RStudio "Connection" pane to interactively
#' explore the database.
#'
#' @return NULL
#' @export
#'
#' @examples
#' if (!is.null(getOption("connectionObserver"))) wahis_pane()
#' 

repel_pane <- function(conn = repel_remote_conn(),
                       connectCode = "repeldata::repel_remote_pane()",
                       actions = list()) {
    
    if(inherits(conn, "MonetDBEmbeddedConnection")){
        dbname <- "REPEL local database"
        host <- "repellocal"
        type <- "MonetDB"
        disconnect <- repeldata::repel_local_disconnect
        actions <- list(
            Status = list(
                icon = system.file("img", "oie-logo.png", package = "repeldata"),
                callback = repel_local_status
            )
        )
    }
    
    if(inherits(conn, "PqConnection")){ 
        dbname <- "REPEL remote database"
        host <- "repelremote"
        type <- "Postgres"
        disconnect <- repeldata::repel_remote_disconnect
    }
    
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionOpened(
            type = type, # message (postgresql or monetdb)
            host = host, # unique id
            displayName = dbname,
            icon = system.file("img", "eha_logo.png", package = "repeldata"),
            connectCode = connectCode,
            disconnect = disconnect,
            listObjectTypes = function() {
                list(
                    table = list(contains = "data")
                )
            },
            listObjects = function(type = "datasets") {
                tbls <- DBI::dbListTables(conn)
                data.frame(
                    name = tbls,
                    type = rep("table", length(tbls)),
                    stringsAsFactors = FALSE
                )
            },
            listColumns = function(table) {
                res <- DBI::dbSendQuery(conn,
                                        paste("SELECT * FROM", table, "LIMIT 1"))
                on.exit(DBI::dbClearResult(res))
                DBI::dbColumnInfo(res)
            },
            previewObject = function(rowLimit, table) {  #nolint
                DBI::dbGetQuery(conn,
                                paste("SELECT * FROM", table, "LIMIT", rowLimit))
            },
            actions = actions,
            connectionObject = conn
        )
    }
}


#' Show REPEL (remote) database in the RStudio Connections Pane 
#'
#' @return
#' @export
#'
#' @examples
repel_remote_pane <- function() {
    repel_pane(conn = repel_remote_conn(),
               connectCode = "repeldata::repel_remote_pane()")
}

update_remote_repel_pane <- function() {
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionUpdated("Postgres", "repelremote", "")
    }
}


#' Show REPEL (local) database in the RStudio Connections Pane 
#'
#' @return
#' @export
#'
#' @examples
#' 
repel_local_pane <- function() {
    repel_pane(conn = repel_local_conn(),
               connectCode = "repeldata::repel_local_pane()")
}

update_local_repel_pane <- function() {
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionUpdated("MonetDB", "repellocal", "")
    }
}

