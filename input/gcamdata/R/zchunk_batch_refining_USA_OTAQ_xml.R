#' module_energy_batch_refining_USA_OTAQ_xml
#'
#' Construct XML data structure for \code{refining_USA_OTAQ.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{refining_USA_OTAQ.xml}.
module_energy_batch_refining_USA_OTAQ_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2222.SubsectorLogit_en",
             "L2222.SubsectorShrwt_en",
             "L2222.SubsectorShrwtFllt_en",
             "L2222.StubTechInterp_en",
             "L2222.StubTechCoef_en",
             "L2222.StubTechCost_en",
             "L2222.StubTechShrwt_en",
             "L2222.StubTechSecOut_en",
             "L2222.StubTechSCurve_en",
             "L2222.StubTechProfitShutdown_en",
             "L2222.GlobalTechCoef_en"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "refining_USA_OTAQ.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2222.SubsectorLogit_en <- get_data(all_data, "L2222.SubsectorLogit_en")
    L2222.SubsectorShrwt_en <- get_data(all_data, "L2222.SubsectorShrwt_en")
    L2222.SubsectorShrwtFllt_en <- get_data(all_data, "L2222.SubsectorShrwtFllt_en")
    L2222.StubTechInterp_en <- get_data(all_data, "L2222.StubTechInterp_en")
    L2222.StubTechCoef_en <- get_data(all_data, "L2222.StubTechCoef_en")
    L2222.StubTechCost_en <- get_data(all_data, "L2222.StubTechCost_en")
    L2222.StubTechShrwt_en <- get_data(all_data, "L2222.StubTechShrwt_en")
    L2222.StubTechSecOut_en <- get_data(all_data, "L2222.StubTechSecOut_en")
    L2222.StubTechSCurve_en <- get_data(all_data, "L2222.StubTechSCurve_en")
    L2222.StubTechProfitShutdown_en <- get_data(all_data, "L2222.StubTechProfitShutdown_en")
    L2222.GlobalTechCoef_en <- get_data(all_data, "L2222.GlobalTechCoef_en")

    # ===================================================

    # Produce outputs
    create_xml("refining_USA_OTAQ.xml") %>%
      add_logit_tables_xml(L2222.SubsectorLogit_en, "SubsectorLogit") %>%
      add_xml_data(L2222.SubsectorShrwt_en, "SubsectorShrwt") %>%
      add_xml_data(L2222.SubsectorShrwtFllt_en, "SubsectorShrwtFllt") %>%
      add_xml_data(L2222.StubTechInterp_en, "StubTechInterp") %>%
      add_xml_data(L2222.StubTechCoef_en, "StubTechCoef") %>%
      add_xml_data(L2222.StubTechCost_en, "StubTechCost") %>%
      add_xml_data(L2222.StubTechShrwt_en, "StubTechShrwt") %>%
      add_xml_data(L2222.StubTechSecOut_en, "StubTechSecOut") %>%
      add_xml_data(L2222.StubTechSCurve_en, "StubTechSCurve") %>%
      add_xml_data(L2222.StubTechProfitShutdown_en, "StubTechProfitShutdown") %>%
      add_xml_data(L2222.GlobalTechCoef_en, "GlobalTechCoef") %>%
      add_precursors("L2222.SubsectorLogit_en",
                     "L2222.SubsectorShrwt_en",
                     "L2222.SubsectorShrwtFllt_en",
                     "L2222.StubTechInterp_en",
                     "L2222.StubTechCoef_en",
                     "L2222.StubTechCost_en",
                     "L2222.StubTechShrwt_en",
                     "L2222.StubTechSecOut_en",
                     "L2222.StubTechSCurve_en",
                     "L2222.StubTechProfitShutdown_en",
                     "L2222.GlobalTechCoef_en") ->
      refining_USA_OTAQ.xml

    return_data(refining_USA_OTAQ.xml)
  } else {
    stop("Unknown command")
  }
}
