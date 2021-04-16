#' module_energy_batch_IntensityCap_trn_xml
#'
#' Construct XML data structure for \code{IntensityCap_trn.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{IntensityCap_trn.xml}.
module_energy_batch_IntensityCap_trn_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2542.StubTranTechCoef_caps",
             "L2542.StubTranTechRES_caps",
             "L2542.PortfolioStdConstraint_RES"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "IntensityCap_trn.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2542.StubTranTechCoef_caps <- get_data(all_data, "L2542.StubTranTechCoef_caps")
    L2542.StubTranTechRES_caps <- get_data(all_data, "L2542.StubTranTechRES_caps")
    L2542.PortfolioStdConstraint_RES <- get_data(all_data, "L2542.PortfolioStdConstraint_RES")

    # ===================================================

    # Produce outputs
    create_xml("IntensityCap_trn.xml") %>%
      add_xml_data(L2542.StubTranTechCoef_caps, "StubTranTechCoef") %>%
      add_xml_data(L2542.StubTranTechRES_caps, "StubTranTechRES") %>%
      add_xml_data(L2542.PortfolioStdConstraint_RES, "PortfolioStdConstraint") %>%
      add_precursors("L2542.StubTranTechCoef_caps",
                     "L2542.StubTranTechRES_caps",
                     "L2542.PortfolioStdConstraint_RES") ->
      IntensityCap_trn.xml

    return_data(IntensityCap_trn.xml)
  } else {
    stop("Unknown command")
  }
}
