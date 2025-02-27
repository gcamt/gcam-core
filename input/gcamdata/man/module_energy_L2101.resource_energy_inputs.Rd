% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/zchunk_L2101.resource_energy_inputs.R
\name{module_energy_L2101.resource_energy_inputs}
\alias{module_energy_L2101.resource_energy_inputs}
\title{module_energy_L2101.resource_energy_inputs}
\usage{
module_energy_L2101.resource_energy_inputs(command, ...)
}
\arguments{
\item{command}{API command to execute}

\item{...}{other optional parameters, depending on command}
}
\value{
Depends on \code{command}: either a vector of required inputs,
a vector of output names, or (if \code{command} is "MAKE") all
the generated outputs: \code{L2101.SubDepRsrcCoef_fos}, \code{L2101.SubDepRsrcDummyInfo_fos}.
}
\description{
Resource market information, prices, TechChange parameters, supply curves, and environmental costs.
}
\details{
Resource production input/output coefficients and dummy input flag.
}
\author{
GPK March 2019
}
