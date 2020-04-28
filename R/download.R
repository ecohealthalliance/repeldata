#' Download the WAHIS database to your local computer
#'
#' This command downloads the WAHIS shipments database and populates a local
#' database. Note that you need EHA AWS access to do so for now.
#'
#' The database is stored by default under [rappdirs::user_data_dir()], or its
#' location can be set with the environment variable `WAHIS_DB_DIR`.
#'
#' @param destdir Where to download the compressed files.
#' @param cleanup Whether to delete the compressed files after loading into the database.
#' @param verbose Whether to display messages and download progress
#' @param load_aws_credentials Whether to use credentials from [aws.signature::use_credentials()].  If FALSE, AWS credentials must be provided as environment variables.

#'
#' @return NULL
#' @export
#' @importFrom arkdb unark
#' @importFrom aws.s3 save_object get_bucket_df
#' @importFrom fs dir_create path
#'
#' @examples
#' \donttest{
#' \dontrun{
#' repel_local_download()
#' }
#' }
#TODO get AWS LastModified
repel_local_download <- function(destdir = tempfile(),
                              cleanup = TRUE, verbose = interactive(),
                              load_aws_credentials = TRUE) {
    if(load_aws_credentials && requireNamespace("aws.signature", quietly = TRUE)) {
        aws.signature::use_credentials()  
    }
    if (verbose) message("Downloading data...\n")
    purrr::walk(DBI::dbListTables(repel_local_conn()), ~DBI::dbRemoveTable(repel_local_conn(), .))
    fs::dir_create(destdir)
    data_files_df <- get_bucket_df("repeldb", prefix = "csv")
    purrr::walk(data_files_df$Key, function(key) {
        f = fs::path(destdir, basename(key))
        save_object(object = key, bucket = "repeldb", file = f)
        tryCatch({
            print(key)
            arkdb::unark(f, repel_local_conn(), lines = 100000, overwrite = TRUE)
            }, error=function(e){cat("ERROR :", conditionMessage(e), "\n")})
        if (cleanup) file.remove(f)
    })
    if (verbose) message("Calculating Stats...\n")
    DBI::dbWriteTable(repel_local_conn(), "repel_local_status", make_status_table(),
                 overwrite = TRUE)
    update_local_repel_pane()
    if (verbose) message("Done!")
}


#' @importFrom DBI dbGetQuery
#' @importFrom purrr map_dbl
#' @importFrom tibble tibble
make_status_table <- function() {
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
