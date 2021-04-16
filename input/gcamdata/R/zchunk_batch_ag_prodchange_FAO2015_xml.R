#' module_aglu_batch_ag_prodchange_FAO2015_xml
#'
#' Construct XML data structure for \code{Ccoef.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{Ccoef.xml}. The corresponding file in the
#' original data system was \code{batch_Ccoef_xml.R} (energy XML).
module_aglu_batch_ag_prodchange_FAO2015_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2013.AgProdChange_2015"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "ag_prodchange_FAO2015.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2013.AgProdChange_2015 <- get_data(all_data, "L2013.AgProdChange_2015")

    # ===================================================

    # Produce outputs
    create_xml("ag_prodchange_FAO2015.xml") %>%
      add_xml_data(L2013.AgProdChange_2015, "AgProdChange") %>%
      add_precursors("L2013.AgProdChange_2015") ->
      ag_prodchange_FAO2015.xml

    return_data(ag_prodchange_FAO2015.xml)
  } else {
    stop("Unknown command")
  }
}
