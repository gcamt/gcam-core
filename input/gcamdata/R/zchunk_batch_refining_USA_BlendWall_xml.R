#' module_energy_batch_refining_USA_BlendWall_xml
#'
#' Construct XML data structure for \code{refining_USA_BlendWall.xml}.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{refining_USA_BlendWall.xml}.
module_energy_batch_refining_USA_BlendWall_xml <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c("L2222.StubTechCoef_BlendWall"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c(XML = "refining_USA_BlendWall.xml"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    L2222.StubTechCoef_BlendWall <- get_data(all_data, "L2222.StubTechCoef_BlendWall")

    # ===================================================

    # Produce outputs
    create_xml("refining_USA_BlendWall.xml") %>%
      add_xml_data(L2222.StubTechCoef_BlendWall, "StubTechCoef") %>%
      add_precursors("L2222.StubTechCoef_BlendWall") ->
      refining_USA_BlendWall.xml

    return_data(refining_USA_BlendWall.xml)
  } else {
    stop("Unknown command")
  }
}
