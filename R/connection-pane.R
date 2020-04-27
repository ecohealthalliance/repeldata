sql_action <- function() {
    if (requireNamespace("rstudioapi", quietly = TRUE) &&
        exists("documentNew", asNamespace("rstudioapi"))) {
        contents <- paste(
            "-- !preview conn=wahisclient::wahis_db()",
            "",
            "SELECT * FROM annual_reports_metadata LIMIT 100",
            "",
            sep = "\n"
        )
        
        rstudioapi::documentNew(
            text = contents, type = "sql",
            position = rstudioapi::document_position(2, 40),
            execute = FALSE
        )
    }
}

#' Open WAHIS database connection pane in RStudio
#'
#' This function launches the RStudio "Connection" pane to interactively
#' explore the database.
#'
#' @return NULL
#' @export
#'
#' @examples
#' if (!is.null(getOption("connectionObserver"))) wahis_pane()
wahis_pane <- function(conn = wahis_db(), dbname = "REPEL local database",
                       connectCode = "wahisclient::wahis_pane()",
                       disconnect = wahisclient::wahis_disconnect) {
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionOpened(
            type = "wahisclient",
            host = "wahisclient",
            displayName = dbname,
            icon = system.file("img", "eha_logo.png", package = "wahisclient"),
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
                data.frame(
                    name = res@env$info$names, type = res@env$info$types,
                    stringsAsFactors = FALSE
                )
            },
            previewObject = function(rowLimit, table) {  #nolint
                DBI::dbGetQuery(conn,
                                paste("SELECT * FROM", table, "LIMIT", rowLimit))
            },
            actions = list(
                Status = list(
                    icon = system.file("img", "oie-logo.png", package = "wahisclient"),
                    callback = wahis_status
                ),
                SQL = list(
                    icon = system.file("img", "edit-sql.png", package = "wahisclient"),
                    callback = sql_action
                )
            ),
            connectionObject = conn
        )
    }
}

update_wahis_pane <- function() {
    observer <- getOption("connectionObserver")
    if (!is.null(observer)) {
        observer$connectionUpdated("wahisclient", "wahisclient", "")
    }
}
