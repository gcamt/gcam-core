#' module_energy_L2101.resource_energy_inputs
#'
#' Resource market information, prices, TechChange parameters, supply curves, and environmental costs.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L2101.SubDepRsrcCoef_fos}, \code{L2101.SubDepRsrcDummyInfo_fos}.
#' @details Resource production input/output coefficients and dummy input flag.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author GPK March 2019
module_energy_L2101.resource_energy_inputs <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/GCAM_region_names",
             FILE = "energy/A_regions",
             FILE = "energy/fuel_energy_input",
             FILE = "energy/A10.subrsrc_coef",
             "L132.in_EJ_R_rsrcenergy_F_Yh",
             "L210.DepRsrcCalProd"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L2101.SubDepRsrcCoef_fos",
             "L2101.SubDepRsrcDummyInfo_fos")) # Units
  } else if(command == driver.MAKE) {

    # Silence package checks
    year <- depresource <- subresource <- technology <- minicam.energy.input <-
      coefficient <- GCAM_region_ID <- region <- cal.production <- resource_class <-
      energy_input <- energy_total <- share <- value <- sector <- fuel <- NULL

    all_data <- list(...)[[1]]

    # Load required inputs
    GCAM_region_names <- get_data(all_data, "common/GCAM_region_names")
    A_regions <- get_data(all_data, "energy/A_regions")
    fuel_energy_input <- get_data(all_data, "energy/fuel_energy_input")
    A10.subrsrc_coef <- get_data(all_data, "energy/A10.subrsrc_coef")
    L132.in_EJ_R_rsrcenergy_F_Yh <- get_data(all_data, "L132.in_EJ_R_rsrcenergy_F_Yh")
    L210.DepRsrcCalProd <- get_data(all_data, "L210.DepRsrcCalProd")

    # ===================================================

    L2101.SubDepRsrcCoef_fos <- gather_years(A10.subrsrc_coef, value_col = "coefficient") %>%
      complete(nesting(depresource,subresource,technology,minicam.energy.input),
               year = c(year, MODEL_YEARS)) %>%
      group_by(depresource,subresource,technology,minicam.energy.input) %>%
      mutate(coefficient = round(approx_fun(year, coefficient), energy.DIGITS_COEFFICIENT)) %>%
      ungroup() %>%
      repeat_add_columns(GCAM_region_names) %>%
      filter(year %in% MODEL_YEARS) %>%
      arrange(GCAM_region_ID, year) %>%
      mutate(market.name = region) %>%
      select(LEVEL2_DATA_NAMES[["SubDepRsrcCoef"]])

    # These are default coefficients that apply on in future years. Base years are calculated from base-year reported
    # energy consumption divided by resource production
    # Because oil and gas are together in the base-year inventory data, they are separated according to bottom-up shares
    L2101.oilgas_shares_numerator <-
      left_join(L210.DepRsrcCalProd, L2101.SubDepRsrcCoef_fos, by = c("region", "depresource", "subresource", "year")) %>%
      mutate(energy_input = cal.production * coefficient,
             resource_class = if_else(depresource %in% c("crude oil", "natural gas"), "oilgas", depresource))
    L2101.oilgas_shares_denominator <- L2101.oilgas_shares_numerator %>%
      group_by(region, resource_class, minicam.energy.input, year) %>%
      summarise(energy_total = sum(energy_input)) %>%
      ungroup()
    L2101.oilgas_shares <- L2101.oilgas_shares_numerator %>%
      left_join(L2101.oilgas_shares_denominator, by = c("region", "resource_class", "minicam.energy.input", "year")) %>%
      mutate(share = if_else(energy_total > 0, energy_input / energy_total, 0)) %>%
      select(region, depresource, subresource, resource_class, minicam.energy.input, year, share) %>%
      left_join(fuel_energy_input, by = "minicam.energy.input")

    # Calculate historical coefficients as energy_input * share / cal.production
    L2101.RsrcClassInput <-
      filter(L132.in_EJ_R_rsrcenergy_F_Yh, year %in% MODEL_BASE_YEARS) %>%
      rename(energy_input = value) %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID") %>%
      mutate(resource_class = sub("industry_", "", sector)) %>%
      select(region, resource_class, fuel, year, energy_input)
    L2101.SubDepRsrcCoef_fos_hist <-
      L210.DepRsrcCalProd %>%
      left_join(L2101.oilgas_shares, by = c("region", "depresource", "subresource", "year")) %>%
      left_join(L2101.RsrcClassInput, by = c("region", "resource_class", "fuel", "year")) %>%
      mutate(coefficient = if_else(cal.production > 0,
                                   round(energy_input * share / cal.production, energy.DIGITS_CALOUTPUT),
                                   0),
             technology = depresource,
             market.name = region) %>%
      select(LEVEL2_DATA_NAMES[["SubDepRsrcCoef"]])

    L2101.SubDepRsrcCoef_fos <- bind_rows(L2101.SubDepRsrcCoef_fos_hist,
                                       subset( L2101.SubDepRsrcCoef_fos, year %in% MODEL_FUTURE_YEARS))

    L2101.SubDepRsrcDummyInfo_fos <-
      select(L2101.SubDepRsrcCoef_fos, region, depresource, subresource, technology, year) %>%
      distinct() %>%
      mutate(dummy.input = depresource,
             share.weight = 1,
             hack = 1)

    # ===================================================

    # Produce outputs

    L2101.SubDepRsrcCoef_fos %>%
      add_title("Energy consumption per unit resource production") %>%
      add_units("Unitless input/output") %>%
      add_comments("historical values calibrated based on IEA energy balances; future years are default assumptions") %>%
      add_precursors("common/GCAM_region_names", "energy/A_regions", "energy/fuel_energy_input",
                     "energy/A10.subrsrc_coef", "L132.in_EJ_R_rsrcenergy_F_Yh", "L210.DepRsrcCalProd" ) ->
      L2101.SubDepRsrcCoef_fos

    L2101.SubDepRsrcDummyInfo_fos %>%
      add_title("Dummy input flag for resource production") %>%
      add_units("Unitless") %>%
      add_comments("used by the model for carbon emissions accounting") %>%
      same_precursors_as(L2101.SubDepRsrcCoef_fos) ->
      L2101.SubDepRsrcDummyInfo_fos

    return_data(L2101.SubDepRsrcCoef_fos,
                L2101.SubDepRsrcDummyInfo_fos)
  } else {
    stop("Unknown command")
  }
}
