#' module_energy_L2222.refining_USA_OTAQ
#'
#' Prepare the assumptions and calibrated outputs for energy transformation supplysectors, subsectors, and technologies.
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
module_energy_L2222.refining_USA_OTAQ <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "energy/A222.subsector_shrwt",
             FILE = "energy/A222.subsector_logit",
             FILE = "energy/A222.stubtech_coef",
             FILE = "energy/A222.stubtech_cost",
             FILE = "energy/A222.stubtech_retirement",
             FILE = "energy/A222.stubtech_shrwt",
             FILE = "energy/A222.stubtech_interp",
             FILE = "energy/A222.stubtech_secout",
             FILE = "energy/A222.globaltech_coef"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L2222.SubsectorLogit_en",
             "L2222.SubsectorShrwt_en",
             "L2222.SubsectorShrwtFllt_en",
             "L2222.StubTechInterp_en",
             "L2222.StubTechCoef_en",
             "L2222.StubTechCoef_BlendWall",
             "L2222.StubTechCost_en",
             "L2222.StubTechShrwt_en",
             "L2222.StubTechSCurve_en",
             "L2222.StubTechProfitShutdown_en",
             "L2222.StubTechSecOut_en",
             "L2222.GlobalTechCoef_en"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Silencing global variable package checks
    coefficient <- year <- year.fillout <- technology <- region <- supplysector <- subsector <-
      minicam.energy.input <- value <- input.cost <- share.weight <- year.x <- year.y <-
      secondary.output <- output.ratio <- NULL

    # Load required inputs
    A222.subsector_logit <- get_data(all_data, "energy/A222.subsector_logit")
    A222.subsector_shrwt <- get_data(all_data, "energy/A222.subsector_shrwt")
    A222.stubtech_coef <- get_data(all_data, "energy/A222.stubtech_coef")
    A222.stubtech_cost <- get_data(all_data, "energy/A222.stubtech_cost")
    A222.stubtech_retirement <- get_data(all_data, "energy/A222.stubtech_retirement")
    A222.stubtech_shrwt  <- get_data(all_data, "energy/A222.stubtech_shrwt")
    A222.stubtech_interp <- get_data(all_data, "energy/A222.stubtech_interp")
    A222.stubtech_secout <- get_data(all_data, "energy/A222.stubtech_secout")
    A222.globaltech_coef <- get_data(all_data, "energy/A222.globaltech_coef")

    # ===================================================

    # 2. Build tables for CSVs


    L2222.SubsectorLogit_en <- mutate(A222.subsector_logit, logit.year.fillout = min(MODEL_YEARS)) %>%
      select(c(LEVEL2_DATA_NAMES[["SubsectorLogit"]], LOGIT_TYPE_COLNAME))

    if(any(!is.na(A222.subsector_shrwt$year))) {
      L2222.SubsectorShrwt_en <- filter(A222.subsector_shrwt, !is.na(year)) %>%
        select(LEVEL2_DATA_NAMES[["SubsectorShrwt"]])
    }

    if(any(!is.na(A222.subsector_shrwt$year.fillout))) {
      A222.subsector_shrwt %>%
        filter(!is.na(year.fillout)) %>%
        select(LEVEL2_DATA_NAMES[["SubsectorShrwtFllt"]]) ->
        L2222.SubsectorShrwtFllt_en
      }

    # 2c. Technology information

    # L2222.StubTechInterp_en: Technology shareweight interpolation of refining techs in the USA
    L2222.StubTechInterp_en <- set_years(A222.stubtech_interp) %>%
      rename(stub.technology = technology) %>%
      select(LEVEL2_DATA_NAMES[["StubTechInterp"]])

    # L2222.StubTechCoef_en: Energy inputs and coefficients of refining technologies
    A222.stubtech_coef %>%
      gather_years(value_col = "coefficient") %>%
      complete(nesting(region, supplysector, subsector, technology, minicam.energy.input),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(region, supplysector, subsector, technology, minicam.energy.input) %>%
      mutate(coefficient = approx_fun(year, coefficient, rule = 1)) %>%
      ungroup() %>%
      drop_na() %>% # any model years outside the envelope of years with provided values are dropped
      filter(year %in% MODEL_YEARS) %>%
      # Re-assign the name of the stub technology
      rename(stub.technology = technology) %>%
      mutate(coefficient = round(coefficient, energy.DIGITS_COEFFICIENT),
             # For the sugar cane and palm oil technologies, the market-name on the energy input is set to the region of origin
             # Note that this step is performed on the input, not the technology, as other inputs (blend wall credit) should stay within the parent region
             market.name = if_else(minicam.energy.input == "regional sugar for ethanol", "Brazil",
                                   if_else(minicam.energy.input == "regional palmfruit", "Indonesia", region),
                                   region))%>%
      select(LEVEL2_DATA_NAMES[["StubTechCoef"]])->
      L2222.StubTechCoef_en

    #Put the blend wall inputs, if any, into a separate XML file
    L2222.StubTechCoef_BlendWall <- subset(L2222.StubTechCoef_en, minicam.energy.input == "Blend Wall Credit")
      # Note 5/11/2017 - blend wall credits need to be tracked from the existing (2010) stock as well, or we will violate the
      # blend wall in future periods. Add the 2010 technologies to this table
    L2222.StubTechCoef_BlendWall_2010 <- subset(L2222.StubTechCoef_BlendWall, year == min(year)) %>%
      mutate(year = max(MODEL_BASE_YEARS))
    L2222.StubTechCoef_BlendWall <- bind_rows( L2222.StubTechCoef_BlendWall_2010, L2222.StubTechCoef_BlendWall )

    L2222.StubTechCoef_en <- subset(L2222.StubTechCoef_en, minicam.energy.input != "Blend Wall Credit")

    # L2222.StubTechCost_en: Costs of global technologies for energy transformation
    A222.stubtech_cost %>%
      fill_exp_decay_extrapolate(MODEL_YEARS) %>%
      drop_na() %>%
      rename(stub.technology = technology, input.cost = value) %>%
      mutate(input.cost = round(input.cost, energy.DIGITS_COST)) %>%
      select(LEVEL2_DATA_NAMES[["StubTechCost"]]) ->
      L2222.StubTechCost_en

    # L2222.StubTechShrwt_en: Shareweights of refining technologies
    A222.stubtech_shrwt %>%
      gather_years(value_col = "share.weight") %>%
      complete(nesting(region, supplysector, subsector, technology), year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology) %>%
      mutate(share.weight = round(approx_fun(year, share.weight, rule = 1), energy.DIGITS_SHRWT)) %>%
      ungroup() %>%
      drop_na() %>%
      filter(year %in% MODEL_YEARS) %>%
      # Assign the columns "sector.name" and "subsector.name", consistent with the location info of a global technology
      rename(stub.technology = technology) %>%
      select(LEVEL2_DATA_NAMES[["StubTechShrwt"]]) ->
      L2222.StubTechShrwt_en

    # Retirement information
    A222.stubtech_retirement %>%
      set_years() %>%
      mutate(year = as.integer(year)) %>%
      rename(stub.technology = technology) ->
      L2222.stubtech_retirement_base

    # Copies first future year retirment information into all future years and appends back onto base year
    L2222.stubtech_retirement_base %>%
      mutate(year = as.integer(year)) %>%
      filter(year == min(MODEL_FUTURE_YEARS)) %>%
      repeat_add_columns(tibble(year = MODEL_FUTURE_YEARS)) %>%
      select(-year.x) %>%
      rename(year = year.y) ->
      L2222.stubtech_retirement_future

    # filters base years from original and then appends future years
    L2222.stubtech_retirement_base %>%
      mutate(year = as.integer(year)) %>%
      filter(year == max(MODEL_BASE_YEARS)) %>%
      bind_rows(L2222.stubtech_retirement_future) ->
      L2222.stubtech_retirement

    # Retirement may consist of any of three types of retirement function (phased, s-curve, or none)
    # This section checks L2222.stubtech_retirement for each of these functions and creates a separate level 2 file for each
    # All of these options have different headers, and all are allowed
    if(any(!is.na(L2222.stubtech_retirement$shutdown.rate))) {
      L2222.stubtech_retirement %>%
        filter(!is.na(L2222.stubtech_retirement$shutdown.rate)) %>%
        select(LEVEL2_DATA_NAMES[["GlobalTechYr"]], "lifetime", "shutdown.rate") ->
        L2222.StubTechShutdown_en
    }

    if(any(!is.na(L2222.stubtech_retirement$half.life))) {
      L2222.stubtech_retirement %>%
        filter(!is.na(L2222.stubtech_retirement$half.life)) %>%
        select(LEVEL2_DATA_NAMES[["StubTechYr"]], "lifetime", "steepness", "half.life") ->
        L2222.StubTechSCurve_en
    }

    # L2222.StubTechProfitShutdown_en: Global tech profit shutdown decider and parameters
    if(any(!is.na(L2222.stubtech_retirement$median.shutdown.point))) {
      L2222.stubtech_retirement %>%
        filter(!is.na(L2222.stubtech_retirement$median.shutdown.point)) %>%
        select(LEVEL2_DATA_NAMES[["StubTechYr"]], "median.shutdown.point", "profit.shutdown.steepness") ->
        L2222.StubTechProfitShutdown_en
    }

    # L2222.StubTechSecOut_en: secondary output information
    A222.stubtech_secout %>%
      gather_years(value_col = "output.ratio") %>%
      complete(nesting(region, supplysector, subsector, technology, secondary.output),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology, secondary.output) %>%
      mutate(output.ratio = round(approx_fun(year, output.ratio, rule = 1), energy.DIGITS_COEFFICIENT)) %>%
      ungroup() %>%
      drop_na() %>% # any model years outside the specified envelope of provided years are dropped
      filter(year %in% MODEL_YEARS) %>%
      rename(stub.technology = technology,
             # TO DO: remove this. need to fix the level2 data names once there is a finished product that can avoid RPL's circular loop
             secondary.output.name = secondary.output,
             secondary.output = output.ratio) %>%
      select(LEVEL2_DATA_NAMES[["StubTechSecOut"]])->
      L2222.StubTechSecOut_en

    # L2222.GlobalTechCoef_en: Default energy inputs and coefficients of refining technologies not already in the global technology database
    A222.globaltech_coef %>%
      gather_years(value_col = "coefficient") %>%
      complete(nesting(supplysector, subsector, technology, minicam.energy.input),
               year = c(year, MODEL_YEARS)) %>%
      arrange(supplysector, year) %>%
      group_by(supplysector, subsector, technology, minicam.energy.input) %>%
      mutate(coefficient = round(approx_fun(year, coefficient, rule = 1), energy.DIGITS_COEFFICIENT)) %>%
      ungroup() %>%
      filter(year %in% MODEL_YEARS) %>%
      # Re-assign the name of the sector and subsector
      rename(sector.name = supplysector, subsector.name = subsector) %>%
      select(LEVEL2_DATA_NAMES[["GlobalTechCoef"]])->
      L2222.GlobalTechCoef_en

    # ===================================================

    # Produce outputs

    # Note GPK 3/22/2019 - a lot of these tables inherit titles from the input CSV files. Over-write = TRUE takes care of these.
    L2222.SubsectorLogit_en %>%
      add_title("Refining subsector logit exponents (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.subsector_logit") ->
      L2222.SubsectorLogit_en

    L2222.SubsectorShrwt_en %>%
      add_title("Refining subsector share-weights (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.subsector_shrwt") ->
      L2222.SubsectorShrwt_en

    L2222.SubsectorShrwtFllt_en %>%
      add_title("Refining subsector share-weight default fillout values (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.subsector_shrwt") ->
      L2222.SubsectorShrwtFllt_en

    L2222.StubTechInterp_en %>%
      add_title("Refining technology share-weight interpolation (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("Unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_interp") ->
      L2222.StubTechInterp_en

    L2222.StubTechCoef_en %>%
      add_title("Refining technology input-output coefficients (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("Unitless input/output") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_coef") ->
      L2222.StubTechCoef_en

    L2222.StubTechCoef_BlendWall %>%
      add_title("Refining technology blend wall input coefficients (for OTAQ)", overwrite = TRUE) %>%
      add_units("unitless credits per unit output") %>%
      add_comments("Copied from exogenous inputs") %>%
      same_precursors_as(L2222.StubTechCoef_en) ->
      L2222.StubTechCoef_BlendWall

    L2222.StubTechCost_en %>%
      add_title("Refining technology costs (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("1975$/GJ") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_cost") ->
      L2222.StubTechCost_en

    L2222.StubTechShrwt_en %>%
      add_title("Refining technology share-weights (reset for OTAQ)", overwrite = TRUE) %>%
      add_units("unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_shrwt") ->
      L2222.StubTechShrwt_en

    L2222.StubTechSCurve_en %>%
      add_title("Refining technology s-curve retirement (reset by OTAQ)", overwrite = TRUE) %>%
      add_units("years; unitless shape parameter") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_retirement") ->
      L2222.StubTechSCurve_en

    L2222.StubTechProfitShutdown_en %>%
      add_title("Refining technology profit shutdown parameterization (reset by OTAQ)", overwrite = TRUE) %>%
      add_units("unitless") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_retirement") ->
      L2222.StubTechProfitShutdown_en

    L2222.StubTechSecOut_en %>%
      add_title("Refining technology secondary outputs (reset by OTAQ)", overwrite = TRUE) %>%
      add_units("secondary energy out per unit of primary output") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.stubtech_secout") ->
      L2222.StubTechSecOut_en

    L2222.GlobalTechCoef_en %>%
      add_title("Refining technology default input-output coefficients (includes new techs not otherwise in the database)") %>%
      add_units("Unitless input/output") %>%
      add_comments("Copied from exogenous inputs") %>%
      add_precursors("energy/A222.globaltech_coef") ->
      L2222.GlobalTechCoef_en

    return_data(L2222.SubsectorLogit_en, L2222.SubsectorShrwt_en, L2222.SubsectorShrwtFllt_en,
                L2222.StubTechInterp_en, L2222.StubTechCoef_en, L2222.StubTechCoef_BlendWall,
                L2222.StubTechCost_en, L2222.StubTechShrwt_en, L2222.StubTechSecOut_en,
                L2222.StubTechSCurve_en, L2222.StubTechProfitShutdown_en, L2222.GlobalTechCoef_en)
  } else {
    stop("Unknown command")
  }
}
