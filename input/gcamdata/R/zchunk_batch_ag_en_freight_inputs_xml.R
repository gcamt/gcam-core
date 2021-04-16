#' module_energy_batch_ag_en_freight_inputs_xml
#'
#' Construct XML data structure for \code{ag_en_freight_inputs.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs, a vector of output names, or (if
#'   \code{command} is "MAKE") all the generated outputs: \code{ag_en_freight_inputs.xml}.
module_energy_batch_ag_en_freight_inputs_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L271.TechCoef_freight",
             "L271.TechPMult_freight",
             "L271.TechCost_freight",
             "L271.BaseService_freightNetEnAg"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "ag_en_freight_inputs.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L271.TechCoef_freight <- get_data(all_data, "L271.TechCoef_freight")
    L271.TechPMult_freight <- get_data(all_data, "L271.TechPMult_freight")
    L271.TechCost_freight <- get_data(all_data, "L271.TechCost_freight")
    L271.BaseService_freightNetEnAg <- get_data(all_data, "L271.BaseService_freightNetEnAg")

    # ===================================================

    # Produce outputs
    create_xml("ag_en_freight_inputs.xml") %>%
      add_xml_data(L271.TechCoef_freight, "TechCoef") %>%
      add_xml_data(L271.TechPMult_freight, "TechPMult") %>%
      add_xml_data(L271.TechCost_freight, "TechCost") %>%
      add_xml_data(L271.BaseService_freightNetEnAg, "BaseService") %>%
      add_precursors("L271.TechCoef_freight",
                     "L271.TechPMult_freight",
                     "L271.TechCost_freight",
                     "L271.BaseService_freightNetEnAg") ->
      ag_en_freight_inputs.xml

    return_data(ag_en_freight_inputs.xml)
  } else {
    stop("Unknown command")
  }
}
