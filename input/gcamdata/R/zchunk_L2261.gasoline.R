#' module_energy_L2261.gasoline
#'
#' Prepare the assumptions and calibrated outputs for motor gasoline ("refined liquids gasoline pool")
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L2222.SubsectorLogit_en}, \code{L2222.SubsectorShrwt_en},
#' \code{L2222.SubsectorShrwtFllt_en}, \code{L2222.StubTechInterp_en}, \code{L2222.StubTechCoef_en},
#'  \code{L2222.StubTechCost_en}, \code{L2222.StubTechShrwt_en}, \code{L2222.StubTechSecOut_en},
#'  \code{L2222.StubTechSCurve_en}, \code{L2222.StubTechProfitShutdown_en}, \code{L2222.StubTechCoef_BlendWall}.
#' @details This chunk modifies the parameterization of subsectors and technologies in the USA refining sector as per
#'   data provided by OTAQ
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author GPK March 2019
module_energy_L2261.gasoline <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/GCAM_region_names",
             FILE = "energy/A261.sector",
             FILE = "energy/A261.subsector_logit",
             FILE = "energy/A261.subsector_shrwt",
             FILE = "energy/A261.subsector_interp",
             FILE = "energy/A261.globaltech_eff",
             FILE = "energy/A261.globaltech_cost",
             FILE = "energy/A261.globaltech_shrwt",
             "L254.StubTranTechCalInput",
             "L222.StubTechProd_refining"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L2261.Supplysector_en",
             "L2261.SubsectorLogit_en",
             "L2261.SubsectorShrwtFllt_en",
             "L2261.SubsectorInterp_en",
             "L2261.StubTech_en",
             "L2261.GlobalTechEff_en",
             "L2261.GlobalTechCost_en",
             "L2261.GlobalTechShrwt_en",
             "L2261.StubTechProd_gsln"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Silencing global variable package checks
    year <- year.fillout <- technology <- supplysector <- subsector <- minicam.energy.input <-
      efficiency <- minicam.non.energy.input <- input.cost <- share.weight <- region <-
      calOutputValue <- calibrated.value <- total_gsln <- ethanol <- subs.share.weight <- NULL

    # Load required inputs
    GCAM_region_names <- get_data(all_data, "common/GCAM_region_names")
    A261.sector <- get_data(all_data, "energy/A261.sector")
    A261.subsector_logit <- get_data(all_data, "energy/A261.subsector_logit")
    A261.subsector_shrwt <- get_data(all_data, "energy/A261.subsector_shrwt")
    A261.subsector_interp <- get_data(all_data, "energy/A261.subsector_interp")
    A261.globaltech_eff <- get_data(all_data, "energy/A261.globaltech_eff")
    A261.globaltech_cost <- get_data(all_data, "energy/A261.globaltech_cost")
    A261.globaltech_shrwt <- get_data(all_data, "energy/A261.globaltech_shrwt")
    L254.StubTranTechCalInput <- get_data(all_data, "L254.StubTranTechCalInput")
    L222.StubTechProd_refining <- get_data(all_data, "L222.StubTechProd_refining")

    # ===================================================

    # 2. Build tables for CSVs

    L2261.Supplysector_en <- write_to_all_regions(A261.sector,
                                                  c(LEVEL2_DATA_NAMES[["Supplysector"]], LOGIT_TYPE_COLNAME),
                                                  GCAM_region_names)

    L2261.SubsectorLogit_en <- write_to_all_regions(A261.subsector_logit,
                                                    c(LEVEL2_DATA_NAMES[["SubsectorLogit"]], LOGIT_TYPE_COLNAME),
                                                    GCAM_region_names)

    if(any(!is.na(A261.subsector_shrwt$year))){
      L2261.SubsectorShrwt_en <- write_to_all_regions(filter(A261.subsector_shrwt, !is.na(year)),
                                                      LEVEL2_DATA_NAMES[["SubsectorShrwt"]],
                                                      GCAM_region_names)
    }

    if(any(!is.na(A261.subsector_shrwt$year.fillout))) {
      L2261.SubsectorShrwtFllt_en <- write_to_all_regions(filter(A261.subsector_shrwt, !is.na(year.fillout)),
                                                      LEVEL2_DATA_NAMES[["SubsectorShrwtFllt"]],
                                                      GCAM_region_names)
    }

    if(any(is.na(A261.subsector_interp$to.value))){
      L2261.SubsectorInterp_en <- write_to_all_regions(filter(A261.subsector_interp, is.na(A261.subsector_interp$to.value)),
                                                       LEVEL2_DATA_NAMES[["SubsectorInterp"]],
                                                       GCAM_region_names)
    }
    if(any(!is.na(A261.subsector_interp$to.value))){
      L2261.SubsectorInterpTo_en <- write_to_all_regions(filter(A261.subsector_interp, !is.na(A261.subsector_interp$to.value)),
                                                         LEVEL2_DATA_NAMES[["names_SubsectorInterpTo"]],
                                                         GCAM_region_names)
    }

    # 2c. Technology information

    L2261.StubTech_en <- write_to_all_regions(A261.globaltech_shrwt,
                                              LEVEL2_DATA_NAMES[["Tech"]],
                                              GCAM_region_names) %>%
      rename(stub.technology = technology)


    # L2261.GlobalTechEff_en: Energy inputs and efficiencies of ref liq gasoline pool technologies
    A261.globaltech_eff %>%
      gather_years(value_col = "efficiency") %>%
      complete(nesting(supplysector, subsector, technology, minicam.energy.input),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology, minicam.energy.input) %>%
      mutate(efficiency = round(approx_fun(year, efficiency, rule = 1), energy.DIGITS_EFFICIENCY)) %>%
      ungroup() %>%
      drop_na() %>% # any model years outside the envelope of years with provided values are dropped
      filter(year %in% MODEL_YEARS) %>%
      # Assign the columns "sector.name" and "subsector.name", consistent with the location info of a global technology
      rename(sector.name = supplysector, subsector.name = subsector) %>%
      select(LEVEL2_DATA_NAMES[["GlobalTechEff"]])->
      L2261.GlobalTechEff_en

    # L2261.GlobalTechCost_en: Costs of global technologies for ref liq gasoline pool
    A261.globaltech_cost %>%
      gather_years(value_col = "input.cost") %>%
      complete(nesting(supplysector, subsector, technology, minicam.non.energy.input),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology, minicam.non.energy.input) %>%
      mutate(input.cost = round(approx_fun(year, input.cost, rule = 1), energy.DIGITS_COST)) %>%
      ungroup() %>%
      drop_na() %>% # any model years outside the envelope of years with provided values are dropped
      filter(year %in% MODEL_YEARS) %>%
      rename(sector.name = supplysector, subsector.name = subsector) %>%
      select(LEVEL2_DATA_NAMES[["GlobalTechCost"]])->
      L2261.GlobalTechCost_en

    # L2261.GlobalTechShrwt_en: Shareweights of refining technologies
    A261.globaltech_shrwt %>%
      gather_years(value_col = "share.weight") %>%
      complete(nesting(supplysector, subsector, technology),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology) %>%
      mutate(share.weight = round(approx_fun(year, share.weight, rule = 1), energy.DIGITS_SHRWT)) %>%
      ungroup() %>%
      drop_na() %>% # any model years outside the envelope of years with provided values are dropped
      filter(year %in% MODEL_YEARS) %>%
      rename(sector.name = supplysector, subsector.name = subsector) %>%
      select(LEVEL2_DATA_NAMES[["GlobalTechShrwt"]]) ->
      L2261.GlobalTechShrwt_en

    # Calibration information
    # First, compute the total "refined liquids gasoline pool" (ethanol + refining) from the inputs to the
    # transportation technologies. The ethanol volume is equal to the ethanol output, calibrated elsewhere. The refining
    # "output" is equal to the total minus ethanol.

    L222.StubTechProd_ethanol <- filter(L222.StubTechProd_refining, supplysector == "ethanol") %>%
      group_by(region, year) %>%
      summarise(ethanol = sum(calOutputValue)) %>%
      ungroup()

    L2261.StubTechProd_gsln <- filter(L254.StubTranTechCalInput, minicam.energy.input %in% unique(A261.sector$supplysector)) %>%
      group_by(region, minicam.energy.input, year) %>%
      summarise(total_gsln = sum(calibrated.value)) %>%
      ungroup() %>%
      left_join_error_no_match(L222.StubTechProd_ethanol, by = c("region", "year"), ignore_columns = "ethanol") %>%
      replace_na(list(ethanol = 0)) %>%
      mutate(refining = total_gsln - ethanol) %>%
      select(-total_gsln) %>%
      rename(supplysector = minicam.energy.input) %>%
      gather(key = minicam.energy.input, value = "calOutputValue", -region, -supplysector, -year) %>%
      left_join_error_no_match(select(A261.globaltech_eff, supplysector, subsector, technology, minicam.energy.input),
                               by = c("supplysector", "minicam.energy.input")) %>%
      rename(stub.technology = technology) %>%
      mutate(share.weight.year = year,
             subs.share.weight = if_else(calOutputValue > 0, 1, 0),
             tech.share.weight = subs.share.weight) %>%
      select(LEVEL2_DATA_NAMES[["StubTechProd"]])

    # Zeroing out the ethanol production in 2015 in regions with zero production in 2010
    # The problem here is that with ethanol broken out as a specific commodity, the regions that produce none and aren't assigned
    # any first-generation crop for the historical production will only be able to produce with second-gen technologies,
    # but the second-gen technologies by default aren't available until 2020. So, in the 2015 time period, ethanol needs to be
    # share-weight 0 in these regions w zero production

    zero_ethanol_2015_regions <- L2261.StubTechProd_gsln$region[
      L2261.StubTechProd_gsln$year == 2010 & L2261.StubTechProd_gsln$subs.share.weight == 0 ]

    tmp<-filter(L2261.SubsectorShrwtFllt_en, region %in% zero_ethanol_2015_regions & subsector == "ethanol") %>%
      mutate(year.fillout = 2015,
             share.weight = 0)

    L2261.SubsectorShrwtFllt_en <- mutate(L2261.SubsectorShrwtFllt_en,
                                          year.fillout = if_else(region %in% zero_ethanol_2015_regions & subsector == "ethanol",
                                                                 2020,
                                                                 year.fillout),
                                          share.weight = if_else(region %in% zero_ethanol_2015_regions & subsector == "ethanol",
                                                                 0.05,
                                                                 share.weight))
    L2261.SubsectorShrwtFllt_en <- bind_rows(tmp, L2261.SubsectorShrwtFllt_en)


    # ===================================================

    # Produce outputs

    L2261.Supplysector_en %>%
      add_title("Motor gasoline (ref liq gas pool) supplysector info") %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("common/GCAM_region_names", "energy/A261.sector") ->
      L2261.Supplysector_en

    L2261.SubsectorLogit_en %>%
      add_title("Motor gasoline subsector logit exponents") %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("common/GCAM_region_names", "energy/A261.subsector_logit") ->
      L2261.SubsectorLogit_en

    L2261.SubsectorShrwtFllt_en %>%
      add_title("Motor gasoline subsector share-weight default fillout values") %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("common/GCAM_region_names", "energy/A261.subsector_shrwt") ->
      L2261.SubsectorShrwtFllt_en

    L2261.SubsectorInterp_en %>%
      add_title("Motor gasoline subsector share-weight interpolation") %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("common/GCAM_region_names", "energy/A261.subsector_interp") ->
      L2261.SubsectorInterp_en

    L2261.StubTech_en %>%
      add_title("Motor gasoline stub technologies") %>%
      add_units("unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("common/GCAM_region_names", "energy/A261.globaltech_shrwt") ->
      L2261.StubTech_en

    L2261.GlobalTechEff_en %>%
      add_title("Motor gasoline technology efficiencies") %>%
      add_units("Unitless output/input") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A261.globaltech_eff") ->
      L2261.GlobalTechEff_en

    L2261.GlobalTechCost_en %>%
      add_title("Motor gasoline technology costs") %>%
      add_units("1975$/GJ") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A261.globaltech_cost") ->
      L2261.GlobalTechCost_en

    L2261.GlobalTechShrwt_en %>%
      add_title("Motor gasoline technology share-weights") %>%
      add_units("unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A261.globaltech_shrwt") ->
      L2261.GlobalTechShrwt_en

    L2261.StubTechProd_gsln %>%
      add_title("Motor gasoline technology calibration") %>%
      add_units("EJ/yr") %>%
      add_comments("Ethanol tech: equal to ethanol output") %>%
      add_comments("Refining tech: total ref liq gasoline pool consumption in transportation minus ethanol output") %>%
      add_precursors("L254.StubTranTechCalInput", "L222.StubTechProd_refining") ->
      L2261.StubTechProd_gsln

    return_data(L2261.Supplysector_en,
                L2261.SubsectorLogit_en,
                L2261.SubsectorShrwtFllt_en,
                L2261.SubsectorInterp_en,
                L2261.StubTech_en,
                L2261.GlobalTechEff_en,
                L2261.GlobalTechCost_en,
                L2261.GlobalTechShrwt_en,
                L2261.StubTechProd_gsln)
  } else {
    stop("Unknown command")
  }
}
