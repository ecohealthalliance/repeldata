#' View field descriptions for REPEL data
#' @return a tibble object
#' @export
repel_fields_schema <- function(){
    read_csv(system.file("database-field-schema.csv", package = "repeldata"), col_types = cols(
        column_name = col_character(),
        data_type = col_character(),
        table = col_character(),
        description = col_character()
    ))
}

