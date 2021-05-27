#' Custom version of arkdb::streamable_readr_csv
#' @import readr arkdb
#' @noRd
repel_streamable_readr_csv <- function(field_types) {
    
    read <- function(file, ...) {
        readr::read_csv(file, col_types = eval(rlang::parse_expr(field_types)), ...)
    }
    write <- function(x, path, omit_header = FALSE) {
        readr::write_csv(x = x, file = path, append = omit_header)
    }
    
    arkdb::streamable_table(read, write, "csv")
}
