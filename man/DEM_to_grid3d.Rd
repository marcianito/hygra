% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/DEM_to_grid3d.R
\name{DEM_to_grid3d}
\alias{DEM_to_grid3d}
\title{Surface grid}
\usage{
DEM_to_grid3d(DEM, grid_domain_x, grid_domain_y, grid_discr, depth_split,
  loc_z = 0, input_dir, output_dir, ...)
}
\arguments{
\item{DEM}{Character string, containing the name of the DEM-file to use.
If left empty, a flat topography with value 0 (zero) will be assumed.}

\item{grid_domain_x}{test}

\item{input_dir}{Character string, specifying the path of the directory where the DEM-file is located.}

\item{output_dir}{Character string, specifying the path of the directory where output should be stored.}
}
\value{
Returns a data.frame, which holds topographical information, including x,y coordinates,
from the area of the SG building.
}
\description{
Generates a 2d grid of the surface of topography at the observatory building.
This is done on basis of a DEM or assuming a flat surface.
}
\details{
missing
}
\examples{
missing
}
\references{
Marvin Reich (2017), mreich@posteo.de
}
