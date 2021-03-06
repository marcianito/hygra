% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/help_funcs.R
\name{plot_dem}
\alias{plot_dem}
\title{Plot a DEM}
\usage{
plot_dem(dem, dem.info, locs = NA)
}
\arguments{
\item{dem}{x * y-grid containing z-coordinates}

\item{dem.info}{data.frame containing information about the DEM (row wise): columns, rows, starting x, starting y, lengths of one cellsize}

\item{locs}{data.frame with column strucure $x (coordinate), $y (coordinate), $name (name to be printed in plot)
...}
}
\description{
Plots a Digital Elevation Model / Matrix using ggplot2-style.
}
\details{
missing
}
\examples{
missing 

}
\references{
Marvin Reich (2014), mreich@gfz-potsdam.de
}
