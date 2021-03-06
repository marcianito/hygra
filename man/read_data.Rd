% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/read_files.R
\name{read_data}
\alias{read_data}
\title{Read input data files}
\usage{
read_data(data_in, data_dir, spat_col = c(NA, NA, 2), dat_col = 3,
  dat_tsf = 7, ...)
}
\arguments{
\item{data_in}{Vector, containing the filename of the data to read.}

\item{spat_col}{Vector, defines the columns of the statial coordinates in the stucture: vector(x, y, z).
If not all dimensions are supplied, the corresponding entry has to be NA.}

\item{dat_col}{Numeric, containing the number of the column which holds the measurment data.}

\item{...}{additional parameters for reading .rData lines. (sep, dec, etc.).}

\item{input_dir}{Vector, containing the directory of the file.}
}
\value{
Returns a data.frame, consisting of a time series (time info and data).
}
\description{
Reads data files for usage of input data.
Various file formats are supported.
}
\details{
If no columns are specified for spatial coordinates or data,
the simplest 1d case is assumed, providing time, z and data.
So far, input data is supported in the following file formats:
.rData, .csv, .tsf.
}
\examples{
missing
}
\references{
Marvin Reich (2017), mreich@posteo.de
}
