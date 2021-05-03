#' Extract value of rasters at specified lat/long points
#'
#' @param conn Connection to the REPEL database
#' @param raster_name Name of a raster table, typically starting with `raster_`
#' @param lon Longitude, between -180 and 180
#' @param lat Latitude, between -90 and 90
#' @param check Whether to fail early with incorrect bounds or table names
#' @importFrom sf st_as_text st_multipoint
#' @importFrom purrr reduce map
#' @importFrom dplyr select full_join everything
#' @importFrom DBI dbGetQuery dbReadTable
#' @importFrom glue glue
#' @return A data frame with lat/lon and raster values
#' @export
get_raster_vals <- function(conn = repel_remote_conn(), raster_name, lon, lat, check = TRUE) {
    if (check) {
        stopifnot(length(lon) == length(lat), between(lon, -180, 180), between(lat, -90, 90))
        raster_tab <- dbReadTable(conn, "raster_columns")
        stopifnot(raster_name %in% raster_tab[["r_table_name"]])
    }
    
    mp <- sf::st_as_text(sf::st_multipoint(cbind(lon, lat)))
    
    out <- dplyr::select(
        reduce(
            .x = map(raster_name, function(tab) {
                query <- glue::glue("
            SELECT ST_X(dp.geom) AS lon, ST_Y(dp.geom) AS lat, ST_Value({tab}.rast, geom) AS {tab}
            FROM ST_Dump('SRID=4326;{mp}') AS dp
            JOIN {tab} ON ST_Intersects({tab}.rast,dp.geom) ;
          ")
                dbGetQuery(conn, query)
            }),
            .f = ~full_join(.x, .y, by = c("lon", "lat")),
        ), lon, lat, everything())
    
    out
}
