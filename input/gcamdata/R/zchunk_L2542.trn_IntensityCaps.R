#' module_energy_L2542.trn_IntensityCaps
#'
#' Set the limits on intensity of specified vehicle size classes
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
module_energy_L2542.trn_IntensityCaps <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "energy/A2542.IntensityCaps",
             "L254.StubTranTechCoef",
             "L254.StubTranTechLoadFactor"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L2542.StubTranTechCoef_caps",
             "L2542.StubTranTechRES_caps",
             "L2542.PortfolioStdConstraint_RES"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Silencing global variable package checks
    region <- supplysector <- tranSubsector <- year <- cap_MJvkm <- loadFactor <- res.secondary.output <-
      policy.portfolio.standard <- market <- policyType <- constraint <- NULL

    # Load required inputs
    A2542.IntensityCaps <- get_data(all_data, "energy/A2542.IntensityCaps")
    L254.StubTranTechCoef <- get_data(all_data, "L254.StubTranTechCoef")
    L254.StubTranTechLoadFactor <- get_data(all_data, "L254.StubTranTechLoadFactor")

    # ===================================================

    # 2. Build tables for CSVs

    A2542.IntensityCaps <- gather_years(A2542.IntensityCaps, value_col = "cap_MJvkm") %>%
      select(region, supplysector, tranSubsector, year, cap_MJvkm) %>%
      complete(nesting(region, supplysector, tranSubsector),
               year = c(year, MODEL_FUTURE_YEARS)) %>%
      arrange(tranSubsector, year) %>%
      group_by(region, supplysector, tranSubsector) %>%
      mutate(cap_MJvkm = approx_fun(year, cap_MJvkm, rule = 1)) %>%
      ungroup() %>%
      drop_na() %>%
      filter(year %in% MODEL_FUTURE_YEARS)

    # L2542.StubTranTechCoef_caps: Input coefficient of technologies that are subject to intensity caps
    # The input coefficient is the same as the energy intensity; the name of the input needs to be the appropriate cap target
    L2542.StubTranTechCoef_caps <- inner_join(L254.StubTranTechCoef,
                                              select(A2542.IntensityCaps, region, supplysector, tranSubsector, year),
                                              by = c("region", "supplysector", "tranSubsector", "year")) %>%
      mutate(minicam.energy.input = paste(year, tranSubsector, "Intensity"))

    # The units of the output ratio are EJ per million passenger-km, equal to TJ per pkm
    CONV_MJ_TJ <- 1e-6
    CONV_GIGA <- 1e9 # for translating prices between EJ and GJ; see C++ parameter GIGA
    energy.DIGITS_trnRES <- 9 # we need a lot of digits for rounding here, because we're working with #s on the order of 1e-6

    # L2542.StubTranTechRES_caps: RES-secondary output coef and pMultiplier
    L2542.StubTranTechRES_caps <- inner_join(L254.StubTranTechLoadFactor,
                                             A2542.IntensityCaps,
                                             by = c("region", "supplysector", "tranSubsector", "year")) %>%
      mutate(res.secondary.output = paste(year, tranSubsector, "Intensity"),
             output.ratio = round(cap_MJvkm / loadFactor * CONV_MJ_TJ, energy.DIGITS_trnRES),
             pMultiplier = loadFactor * CONV_GIGA) %>%
      select(-loadFactor, -cap_MJvkm)

    # L2542.PortfolioStdConstraint_RES: impementation of the constraints
    L2542.PortfolioStdConstraint_RES <- distinct(L2542.StubTranTechRES_caps, region, res.secondary.output, year) %>%
      mutate(policy.portfolio.standard = res.secondary.output,
             market = region,
             policyType = "RES",
             constraint = 1) %>%
      select(region, policy.portfolio.standard, market, policyType, year, constraint)

    # ===================================================

    # Produce outputs

    L2542.StubTranTechCoef_caps %>%
      add_title("Consumption of vehicle intensity credits by partipating transportation technologies") %>%
      add_units("btu/veh-km (ish)") %>%
      add_comments("Consumption of credits matches the intensity of each tranTechnology") %>%
      add_precursors("L254.StubTranTechCoef") ->
      L2542.StubTranTechCoef_caps

    L2542.StubTranTechRES_caps %>%
      add_title("RES secondary outputs of credits from each tranTechnology participating in the intensity cap") %>%
      add_units("Strange") %>%
      add_comments("The values reflect hard-wired unit conversions in the tranTechnology") %>%
      add_precursors("energy/A2542.IntensityCaps", "L254.StubTranTechLoadFactor") ->
      L2542.StubTranTechRES_caps

    L2542.PortfolioStdConstraint_RES %>%
      add_title("Constraint policy switch") %>%
      add_units("Unitless") %>%
      add_comments("Boolean; indicates which years the intensity constraints are active") %>%
      same_precursors_as(L2542.StubTranTechRES_caps) ->
      L2542.PortfolioStdConstraint_RES

    return_data(L2542.StubTranTechCoef_caps,
                L2542.StubTranTechRES_caps,
                L2542.PortfolioStdConstraint_RES)
  } else {
    stop("Unknown command")
  }
}
