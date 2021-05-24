#' Custom version of arkdb::streamable_readr_csv
#' fixes column type in date_of_last_occurrence_if_absent
#' @import readr arkdb
#' @noRd
repel_streamable_readr_csv <- function() {
    
    read <- function(file, ...) {
        readr::read_csv(file, col_types = readr::cols(
            date_of_last_occurrence_if_absent = readr::col_character()), ...)
    }
    write <- function(x, path, omit_header = FALSE) {
        readr::write_csv(x = x, file = path, append = omit_header)
    }
    
    arkdb::streamable_table(read, write, "csv")
}
