#' module_aglu_batch_ag_energy_IRR_MGMT_xml
#'
#' Construct XML data structure for \code{ag_energy_IRR_MGMT.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{ag_energy_IRR_MGMT.xml}.
module_aglu_batch_ag_energy_IRR_MGMT_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2082.AgCoef_en_ag_irr_mgmt",
             "L2082.AgCoef_en_bio_irr_mgmt",
             "L2082.AgCost_ag_irr_mgmt_adj",
             "L2082.AgCost_bio_irr_mgmt_adj"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "ag_energy_IRR_MGMT.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2082.AgCoef_en_ag_irr_mgmt <- get_data(all_data, "L2082.AgCoef_en_ag_irr_mgmt")
    L2082.AgCoef_en_bio_irr_mgmt <- get_data(all_data, "L2082.AgCoef_en_bio_irr_mgmt")
    L2082.AgCost_ag_irr_mgmt_adj <- get_data(all_data, "L2082.AgCost_ag_irr_mgmt_adj")
    L2082.AgCost_bio_irr_mgmt_adj <- get_data(all_data, "L2082.AgCost_bio_irr_mgmt_adj")
    # ===================================================

    # Produce outputs
    create_xml("ag_energy_IRR_MGMT.xml") %>%
      add_xml_data(L2082.AgCoef_en_ag_irr_mgmt, "AgCoef") %>%
      add_xml_data(L2082.AgCoef_en_bio_irr_mgmt, "AgCoef") %>%
      add_xml_data(L2082.AgCost_ag_irr_mgmt_adj, "AgCost") %>%
      add_xml_data(L2082.AgCost_bio_irr_mgmt_adj, "AgCost") %>%
      add_precursors("L2082.AgCoef_en_ag_irr_mgmt", "L2082.AgCoef_en_bio_irr_mgmt",
                     "L2082.AgCost_ag_irr_mgmt_adj", "L2082.AgCost_bio_irr_mgmt_adj") ->
      ag_energy_IRR_MGMT.xml

    return_data(ag_energy_IRR_MGMT.xml)
  } else {
    stop("Unknown command")
  }
}
