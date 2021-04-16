#' module_energy_batch_resource_energy_inputs_xml
#'
#' Construct XML data structure for \code{resource_energy_inputs.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{resource_energy_inputs.xml}.
module_energy_batch_resource_energy_inputs_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2101.SubDepRsrcCoef_fos",
             "L2101.SubDepRsrcDummyInfo_fos"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "resource_energy_inputs.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2101.SubDepRsrcCoef_fos <- get_data(all_data, "L2101.SubDepRsrcCoef_fos")
    L2101.SubDepRsrcDummyInfo_fos <- get_data(all_data, "L2101.SubDepRsrcDummyInfo_fos")

    # ===================================================

    # Produce outputs
    create_xml("resource_energy_inputs.xml") %>%
      add_xml_data(L2101.SubDepRsrcCoef_fos, "SubDepRsrcCoef") %>%
      add_xml_data(L2101.SubDepRsrcDummyInfo_fos, "SubDepRsrcDummyInfo") %>%
      add_precursors("L2101.SubDepRsrcCoef_fos",
                     "L2101.SubDepRsrcDummyInfo_fos") ->
      resource_energy_inputs.xml

    return_data(resource_energy_inputs.xml)
  } else {
    stop("Unknown command")
  }
}
