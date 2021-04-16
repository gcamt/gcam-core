#' module_socioeconomics_L110.ADAGE_socioeconomics
#'
#' Future population and GDP by GCAM region, consistent with ADAGE model assumptions.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs, a vector of output names, or (if
#'   \code{command} is "MAKE") all the generated outputs: \code{L110.Pop_thous_R_Y_ADAGE},
#'   \code{L110.pcgdp_thoususd_R_Y_ADAGE}.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author RPL March 2017
module_socioeconomics_L110.ADAGE_socioeconomics <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/iso_GCAM_regID",
             FILE = "socioeconomics/ADAGE_mapping",
             FILE = "socioeconomics/ADAGE_pop",
             FILE = "socioeconomics/ADAGE_gdp",
             "L100.Pop_thous_ctry_Yh",
             "L100.Pop_thous_SSP_ctry_Yfut",
             "L102.gdp_bilusd_ctry_Yfut"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L110.Pop_thous_R_Y_ADAGE",
             "L110.pcgdp_thoususd_R_Y_ADAGE"))
  } else if(command == driver.MAKE) {

    iso <- scenario <- year <- ADAGE_region <- value <- value_ADAGE <- value_GCAM <-
      scaler <- GCAM_region_ID <- gdp <- value_gdp <- value_pop <-  NULL     # silence package check.

    all_data <- list(...)[[1]]

    # Load required inputs
    iso_GCAM_regID <- get_data(all_data, "common/iso_GCAM_regID")
    ADAGE_mapping <- get_data(all_data, "socioeconomics/ADAGE_mapping")
    ADAGE_pop <- get_data(all_data, "socioeconomics/ADAGE_pop")
    ADAGE_gdp <- get_data(all_data, "socioeconomics/ADAGE_gdp")
    L100.Pop_thous_ctry_Yh <- get_data(all_data, "L100.Pop_thous_ctry_Yh")
    L100.Pop_thous_SSP_ctry_Yfut <- get_data(all_data, "L100.Pop_thous_SSP_ctry_Yfut")
    L102.gdp_bilusd_ctry_Yfut <- get_data(all_data, "L102.gdp_bilusd_ctry_Yfut")

    # Part 1: population
    L110.Pop_thous_ctry_Y <- bind_rows(L100.Pop_thous_ctry_Yh,
                                       subset(L100.Pop_thous_SSP_ctry_Yfut, scenario == socioeconomics.BASE_POP_SCEN)) %>%
      select(-scenario) %>%
      filter(year %in% c(HISTORICAL_YEARS, FUTURE_YEARS))

    L110.Pop_thous_Ra_Y_baseSSP <- left_join(L110.Pop_thous_ctry_Y, select(ADAGE_mapping, iso, ADAGE_region),
                                             by = "iso") %>%
      drop_na() %>%       # some countries aren't in the ADAGE region mapping, so drop them here
      group_by(ADAGE_region, year) %>%
      summarise(value = sum(value)) %>%
      ungroup()

    L110.ADAGE_pop_thous <- gather_years(ADAGE_pop) %>%
      select(ADAGE_region, year, value) %>%
      mutate(value = value * CONV_MIL_THOUS) %>%
      complete(nesting(ADAGE_region), year = seq(min(year), max(year))) %>%
      group_by(ADAGE_region) %>%
      mutate(value = approx_fun(year, value)) %>%
      ungroup()

    # Scalers translate from the historical data + SSP2 to the ADAGE outcomes
    # Note that scalers are normalized to their values in 2010 as no historical population changes are allowed
    L110.ADAGE_pop_scalers <- inner_join(L110.Pop_thous_Ra_Y_baseSSP, L110.ADAGE_pop_thous,
                                        by = c("ADAGE_region", "year"), suffix = c("_GCAM", "_ADAGE")) %>%
      mutate(scaler = value_ADAGE / value_GCAM) %>%
      complete(nesting(ADAGE_region), year = c(max(HISTORICAL_YEARS), FUTURE_YEARS)) %>%
      group_by(ADAGE_region) %>%
      mutate(scaler = scaler / scaler[year == 2010],
             scaler = approx_fun(year, scaler, rule = 2)) %>%
      ungroup() %>%
      select(ADAGE_region, year, scaler)

    # Scalers are multiplied by country-level population in order to get revised population in all years.
    # This is aggregated by GCAM region to return GCAM population harmonized to the ADAGE scenario
    L110.Pop_thous_R_Y_ADAGE <- left_join(L110.Pop_thous_ctry_Y, select(ADAGE_mapping, iso, ADAGE_region),
                                          by = "iso") %>%
      left_join(L110.ADAGE_pop_scalers, by = c("ADAGE_region", "year")) %>%
      replace_na(list(scaler = 1)) %>%
      mutate(value = value * scaler) %>%
      left_join_error_no_match(select(iso_GCAM_regID, iso, GCAM_region_ID), by = "iso") %>%
      group_by(GCAM_region_ID, year) %>%
      summarise(value = sum(value)) %>%
      ungroup()

    # Part 2: GDP
    # GDP is processed in similar fashion to population, though the value written out is per-capita
    L110.gdp_bilusd_ctry_Y <- filter(L102.gdp_bilusd_ctry_Yfut,
                                     scenario == socioeconomics.BASE_GDP_SCENARIO,
                                     year %in% L110.Pop_thous_R_Y_ADAGE$year) %>%
      select(iso, year, value = gdp)

    L110.gdp_bilusd_Ra_Ya <- left_join(L110.gdp_bilusd_ctry_Y, select(ADAGE_mapping, iso, ADAGE_region),
                                       by = "iso") %>%
      drop_na() %>%
      group_by(ADAGE_region, year) %>%
      summarise(value = sum(value)) %>%
      ungroup()

    L110.ADAGE_gdp_bilusd <- gather_years(ADAGE_gdp) %>%
      select(ADAGE_region, year, value) %>%
      complete(nesting(ADAGE_region), year = seq(min(year), max(year))) %>%
      group_by(ADAGE_region) %>%
      mutate(value = approx_fun(year, value)) %>%
      ungroup()

    # Scalers, normalized to 2010 scalers
    L110.ADAGE_gdp_scalers <- inner_join(L110.gdp_bilusd_Ra_Ya, L110.ADAGE_gdp_bilusd,
                                         by = c("ADAGE_region", "year"), suffix = c("_GCAM", "_ADAGE")) %>%
      mutate(scaler = value_ADAGE / value_GCAM) %>%
      complete(nesting(ADAGE_region), year = c(max(HISTORICAL_YEARS), FUTURE_YEARS)) %>%
      group_by(ADAGE_region) %>%
      mutate(scaler = scaler / scaler[year == 2010],
             scaler = approx_fun(year, scaler, rule = 2)) %>%
      ungroup() %>%
      select(ADAGE_region, year, scaler)

    # Scalers are multiplied by country-level gdp in order to get revised gdp in all years.
    # This is aggregated by GCAM region to return GCAM gdp, harmonized to the ADAGE scenario
    L110.gdp_bilusd_R_Y_ADAGE <- left_join(L110.gdp_bilusd_ctry_Y, select(ADAGE_mapping, iso, ADAGE_region),
                                          by = "iso") %>%
      left_join(L110.ADAGE_gdp_scalers, by = c("ADAGE_region", "year")) %>%
      replace_na(list(scaler = 1)) %>%
      mutate(value = value * scaler) %>%
      left_join_error_no_match(select(iso_GCAM_regID, iso, GCAM_region_ID), by = "iso") %>%
      group_by(GCAM_region_ID, year) %>%
      summarise(value = sum(value)) %>%
      ungroup()

    L110.pcgdp_thoususd_R_Y_ADAGE <- left_join_error_no_match(L110.gdp_bilusd_R_Y_ADAGE, L110.Pop_thous_R_Y_ADAGE,
                                                              by = c("GCAM_region_ID", "year"),
                                                              suffix = c("_gdp", "_pop")) %>%
      mutate(value = value_gdp * CONV_BIL_MIL / value_pop) %>%
      select(GCAM_region_ID, year, value)

    # Add the scenario names to these tables being written
    L110.Pop_thous_R_Y_ADAGE$scenario <- "ADAGE"
    L110.pcgdp_thoususd_R_Y_ADAGE$scenario <- "ADAGE"

    # Produce outputs

    L110.Pop_thous_R_Y_ADAGE %>%
      add_title("Population by GCAM region in historical and future years, scaled to match ADAGE future growth") %>%
      add_units("Thousand persons") %>%
      add_comments("Population by GCAM regions scaled to match ADAGE population by 8 macro-regions. Historical values not changed.") %>%
      add_precursors("common/iso_GCAM_regID",
                     "socioeconomics/ADAGE_pop",
                     "socioeconomics/ADAGE_mapping",
                     "L100.Pop_thous_ctry_Yh",
                     "L100.Pop_thous_SSP_ctry_Yfut") ->
      L110.Pop_thous_R_Y_ADAGE

    L110.pcgdp_thoususd_R_Y_ADAGE %>%
      add_title("ADAGE per-capita GDP by GCAM region in ADAGE future years") %>%
      add_units("thousand USD per person") %>%
      add_comments("Growth rates are scaled to match the ADAGE scenario by 8 macro-regions") %>%
      same_precursors_as("L110.Pop_thous_R_Y_ADAGE") %>%
      add_precursors("socioeconomics/ADAGE_gdp",
                     "L102.gdp_bilusd_ctry_Yfut") ->
      L110.pcgdp_thoususd_R_Y_ADAGE

    return_data(L110.Pop_thous_R_Y_ADAGE,
                L110.pcgdp_thoususd_R_Y_ADAGE)
  } else {
    stop("Unknown command")
  }
}
