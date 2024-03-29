% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download-local.R
\name{repel_local_status}
\alias{repel_local_status}
\title{Get the status of the current local REPEL database}
\usage{
repel_local_status(verbose = TRUE)
}
\arguments{
\item{verbose}{Whether to print a status message}
}
\value{
TRUE if the database exists, FALSE if it is not detected. (invisible)
}
\description{
Get the status of the current local REPEL database
}
\examples{
repel_local_status()
}
