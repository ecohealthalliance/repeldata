#' Custom version of arkdb::streamable_readr_csv
#' @import readr arkdb
#' @noRd
repel_streamable_readr_csv <- function() {
    
    read <- function(file, ...) {
        readr::read_csv(file, ...)
    }
    write <- function(x, path, omit_header = FALSE) {
        readr::write_csv(x = x, file = path, append = omit_header)
    }
    
    arkdb::streamable_table(read, write, "csv")
}
