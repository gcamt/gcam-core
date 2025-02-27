#' module_energy_LA132.industry
#'
#' Provides industrial energy consumption (not including CHP) and industrial feedstock consumption by GCAM region/fuel/historical year.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L132.in_EJ_R_indenergy_F_Yh}, \code{L132.in_EJ_R_indfeed_F_Yh}, \code{L132.in_EJ_R_agenergy_F_Yh}. The corresponding file in the
#' original data system was \code{LA132.industry.R} (energy level1).
#' @details The chunk calculates industrial feedstock consumption directly separated from enduse energy comsuption and
#'          industrial energy consumption by deducting net energy use by unconventional oil production, gas processing, refining, and CHP
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author LF September 2017; GPK added ag energy use and oil/gas/coal energy use in March 2019
module_energy_LA132.industry <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/GCAM_region_names",
             FILE = "energy/A_regions",
             FILE = "energy/enduse_fuel_aggregation",
             FILE = "energy/enduse_sector_aggregation",
             "L121.in_EJ_R_unoil_F_Yh",
             "L122.in_EJ_R_refining_F_Yh",
             "L122.in_EJ_R_gasproc_F_Yh",
             "L122.out_EJ_R_gasproc_F_Yh",
             "L123.in_EJ_R_indchp_F_Yh",
             "L124.in_EJ_R_heat_F_Yh",
             "L131.in_EJ_R_Senduse_F_Yh",
             "L131.share_R_Senduse_heat_Yh",
             "L125.LC_bm2_R_LT_Yh_GLU"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L132.in_EJ_R_indenergy_F_Yh",
             "L132.in_EJ_R_indfeed_F_Yh",
             "L132.in_EJ_R_agenergy_F_Yh",
             "L132.in_EJ_R_rsrcenergy_F_Yh"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    GCAM_region_names <- get_data(all_data, "common/GCAM_region_names")
    A_regions <- get_data(all_data, "energy/A_regions")
    enduse_fuel_aggregation <- get_data(all_data, "energy/enduse_fuel_aggregation")
    enduse_sector_aggregation <- get_data(all_data, "energy/enduse_sector_aggregation")
    L121.in_EJ_R_unoil_F_Yh <- get_data(all_data, "L121.in_EJ_R_unoil_F_Yh")
    L122.in_EJ_R_refining_F_Yh <- get_data(all_data, "L122.in_EJ_R_refining_F_Yh")
    L122.in_EJ_R_gasproc_F_Yh <- get_data(all_data, "L122.in_EJ_R_gasproc_F_Yh")
    L122.out_EJ_R_gasproc_F_Yh <- get_data(all_data, "L122.out_EJ_R_gasproc_F_Yh")
    L123.in_EJ_R_indchp_F_Yh <- get_data(all_data, "L123.in_EJ_R_indchp_F_Yh")
    L124.in_EJ_R_heat_F_Yh <- get_data(all_data, "L124.in_EJ_R_heat_F_Yh")
    L131.in_EJ_R_Senduse_F_Yh <- get_data(all_data, "L131.in_EJ_R_Senduse_F_Yh")
    L131.share_R_Senduse_heat_Yh <- get_data(all_data, "L131.share_R_Senduse_heat_Yh")
    L125.LC_bm2_R_LT_Yh_GLU <- get_data(all_data, "L125.LC_bm2_R_LT_Yh_GLU")

    # ===================================================
    # 0. Give binding for variable names used in pipeline
    sector <- sector_agg <- electricity <- heat <- bld <-
      trn <- fuel <- industry <- GCAM_region_ID <- year <-
      value <- value.x <- value.y <- has_district_heat <- fuel.y <- fuel.x <-
      Land_Type <- energy_EJ <- cropland_bm2 <- coef_GJm2 <- coef_revised <-
      ag_energy_revised <- NULL

    # 1. Perform computations

    # Calculation of industrial energy consumption
    # 3/6/2019 modification for ag energy use - in "no-aglu" regions, re-map any assigned agricultural energy use
    # back to the generic industrial energy use category
    industry_energy_name <- enduse_sector_aggregation$sector_agg[enduse_sector_aggregation$sector == "in_industry_general"]
    industry_feedstocks_name <- enduse_sector_aggregation$sector_agg[grepl("feedstock", enduse_sector_aggregation$sector)]
    industry_ag_name <- enduse_sector_aggregation$sector_agg[grepl("agricult", enduse_sector_aggregation$sector)]
    industry_rsrc_names <- enduse_sector_aggregation$sector_agg[grepl("oilgas", enduse_sector_aggregation$sector) |
                                                                  grepl("coal", enduse_sector_aggregation$sector)]

    no_ag_regID <- GCAM_region_names$GCAM_region_ID[GCAM_region_names$region %in% aglu.NO_AGLU_REGIONS]

    L131.in_EJ_R_Senduse_F_Yh %>%
      filter(grepl("industry", sector)) %>%
      left_join_error_no_match(enduse_sector_aggregation, by = "sector") %>%
      select(-sector) %>%
      rename(sector = sector_agg) %>%
      mutate(sector = if_else(GCAM_region_ID %in% no_ag_regID & sector == industry_ag_name, industry_energy_name, sector)) %>%
      left_join(enduse_fuel_aggregation, by = "fuel") %>% # left_join_error_no_match caused error so left_join was used
      select(-electricity, -heat, -bld, -trn, -fuel) %>%
      rename(fuel = industry) %>%
      group_by(GCAM_region_ID, sector, fuel, year) %>%
      summarise(value = sum(value)) %>%
      ungroup ->
      L132.in_EJ_R_ind_F_Yh

    # Split dataframe into energy and feedstocks for adjustments (feedstocks do not get adjusted)
    # 3/6/2019 - agricultural energy use is also split out here. it gets adjusted manually below, but not thereafter.
    # 3/27/2019 - energy for resource production (oil, gas, coal) is also split out here.
    L132.in_EJ_R_ind_F_Yh %>%
      filter(sector == industry_feedstocks_name) %>%
      mutate(sector = sub("in_", "", sector)) ->
      L132.in_EJ_R_indfeed_F_Yh

    L132.in_EJ_R_ind_F_Yh %>%
      filter(sector == industry_energy_name) %>%
      mutate(sector = sub("in_", "", sector)) ->
      L132.in_EJ_R_indenergy_F_Yh

    L132.in_EJ_R_ind_F_Yh %>%
      filter(sector == industry_ag_name) %>%
      mutate(sector = sub("in_", "", sector)) ->
      L132.in_EJ_R_agenergy_F_Yh

    L132.in_EJ_R_ind_F_Yh %>%
      filter(sector %in% industry_rsrc_names) %>%
      mutate(sector = sub("in_", "", sector)) ->
      L132.in_EJ_R_rsrcenergy_F_Yh

    # 3/6/2019: agricultural energy use per unit cropland is very high in some regions; South Korea, Japan, Northern
    # Africa and Colombia all have more than 2x as much energy per unit cropland as the USA. This is likely not actually
    # correct, and would cause issues later on if not addressed up front. Specifically, fuel costs would be very high,
    # potentially causing negative values for other production costs, profit rates, or both. The method below assigns
    # a maximum of the USA's energy per unit cropland times an exogenous multiplier.
    L132.coef_GJm2_R_Y <- filter(L125.LC_bm2_R_LT_Yh_GLU, Land_Type == "HarvCropLand",
                                 year %in% HISTORICAL_YEARS) %>%
      group_by(GCAM_region_ID, year) %>%
      summarise(cropland_bm2 = sum(value)) %>%
      ungroup() %>%
      left_join_error_no_match(L132.in_EJ_R_agenergy_F_Yh, by = c("GCAM_region_ID", "year")) %>%
      rename(energy_EJ = value) %>%
      mutate(coef_GJm2 = energy_EJ / cropland_bm2) %>%
      group_by(year) %>%
      mutate(coef_revised = if_else(coef_GJm2 > coef_GJm2[ GCAM_region_ID == gcam.USA_CODE] * energy.MAX_EN_PER_CRPLND_RATIO_USA,
                                    coef_GJm2[ GCAM_region_ID == gcam.USA_CODE] * energy.MAX_EN_PER_CRPLND_RATIO_USA,
                                    coef_GJm2)) %>%
      ungroup() %>%
      mutate(ag_energy_revised = coef_revised * cropland_bm2,
             ind_energy_add = round(energy_EJ - ag_energy_revised, 9)) # need to round to avoid 1e-15 values here

    # Split this into two data tables: one of energy to add, another of revised agricultural energy use
    L132.in_EJ_R_agenergy_F_Yh <- select(L132.coef_GJm2_R_Y,
                                         GCAM_region_ID, sector, fuel, year, value = "ag_energy_revised")

    L132.in_EJ_R_ind_energy_add_F_Yh <- select(L132.coef_GJm2_R_Y,
                                               GCAM_region_ID, sector, fuel, year, value = "ind_energy_add") %>%
      mutate(sector = unique(L132.in_EJ_R_indenergy_F_Yh$sector))

    # Revised industrial energy = original estimate plus energy re-assigned back from the ag sector
    L132.in_EJ_R_indenergy_F_Yh <- bind_rows(L132.in_EJ_R_indenergy_F_Yh, L132.in_EJ_R_ind_energy_add_F_Yh) %>%
      group_by(GCAM_region_ID, sector, fuel, year) %>%
      summarise(value = sum(value)) %>%
      ungroup()

    # Compile the net energy use by unconventional oil production, gas processing, refining, and CHP that were derived elsewhere
    # This energy will need to be deducted from industrial energy use
    # The electricity demands for unconventional oil has been done in LA121
    # The refining electricity is estimated in LA122
    # The ownuse and T&D losses are estimated in LA126
    # And the remainder is assigned to the end-use sectors in LA131 (LA131 is the one responsible for balancing)

    ## Unconventional oil: the only relevant fuel is gas, as electricity (if any) was taken off prior to scaling for end-use sectors
    L121.in_EJ_R_unoil_F_Yh %>%
      filter(fuel == "gas") ->
      L132.in_EJ_R_indunoil_F_Yh

    ## Gas processing: This is complicated. Coal is not deducted, as inputs to coal gasification were mapped directly
    # from the IEA energy balances, not derived from known fuel outputs multiplied by assumed IO coefs. The reason for doing this is that
    # coal is one of several possible inputs to "gas works", and there is only one output. So no way to disaggregate fuel inputs if calculating from the output.
    # Biogas is treated as primary energy in the IEA energy balances, so not relevant here.
    ## Natural gas processing net energy use is the only one that may need to be calculated (09/2013: It is currently 0 as the IO coef is 1).
    L122.in_EJ_R_gasproc_F_Yh %>%
      filter(fuel == "gas") %>%
      left_join_error_no_match(L122.in_EJ_R_gasproc_F_Yh, by = c("GCAM_region_ID", "sector", "fuel", "year")) %>%
      left_join_error_no_match(L122.out_EJ_R_gasproc_F_Yh, by = c("GCAM_region_ID", "sector", "fuel", "year")) %>%
      mutate(value = value.x - value.y) %>%
      select(-value.x, -value.y) ->
      L132.in_EJ_R_indgasproc_F_Yh

    ## Refining: crude oil refining energy consumption is not derived based on the output and assumed IO coefs so it doesn't apply here
    ## Refining: Electricity was taken off prior to scaling for end-use sectors, and in the IEA energy balances, biofuels are treated as primary energy
    L122.in_EJ_R_refining_F_Yh %>%
      filter(!grepl("oil refining", sector)) %>%
      filter(fuel %in% c("gas", "coal")) ->
      L132.in_EJ_R_indrefining_F_Yh

    # CHP: no adjustments necessary
    L123.in_EJ_R_indchp_F_Yh -> L132.in_EJ_R_indchp_F_Yh

    # Combine all of the deduction tables and multiply by -1 to indicate that these are deductions
    L132.in_EJ_R_indunoil_F_Yh %>%
      bind_rows(L132.in_EJ_R_indrefining_F_Yh) %>%
      bind_rows(L132.in_EJ_R_indgasproc_F_Yh) %>%
      bind_rows(L132.in_EJ_R_indchp_F_Yh) %>%
      mutate(value = -1 * value) ->
      L132.in_EJ_R_inddeductions_F_Yh

    ## Heat: fuel inputs to heat need to be added to industrial energy use, in regions where heat is not modeled as a final fuel
    # Calculate the share of heat consumed by the industrial sector, in regions where heat is not modeled as a separate fuel
    L131.share_R_Senduse_heat_Yh %>%
      filter(grepl("industry", sector)) %>%
      select(-sector) %>%
      group_by(GCAM_region_ID, fuel, year) %>%
      summarise(value = sum(value)) %>%
      ungroup ->
      L132.share_R_indenergy_heat_Yh

    # Multiply these shares by the energy inputs to heat
    A_regions %>%
      filter(has_district_heat == 0) %>%
      select(GCAM_region_ID) %>%
      unlist ->
      has_district_heat_GCAM_region_ID

    L124.in_EJ_R_heat_F_Yh %>%
      filter(GCAM_region_ID %in% has_district_heat_GCAM_region_ID) %>%
      left_join_error_no_match(L132.share_R_indenergy_heat_Yh, by = c("GCAM_region_ID", "year")) %>%
      mutate(value = value.x * value.y) %>%
      select(-fuel.y, -value.y, -value.x) %>%
      rename(fuel = fuel.x) ->
      L132.in_EJ_R_indheat_F_Yh

    # Re-calculate industrial energy as original estimate minus fuel inputs to unconventional oil production, gas processing, and refining, and plus inputs to heat
    L132.in_EJ_R_indenergy_F_Yh %>%
      select(sector) %>%
      unique %>%
      unlist ->
      temp_sector_value

    L132.in_EJ_R_indenergy_F_Yh %>%
      bind_rows(L132.in_EJ_R_inddeductions_F_Yh, L132.in_EJ_R_indheat_F_Yh) %>%
      mutate(sector = temp_sector_value) ->
      L132.in_EJ_R_Sindenergy_F_Yh

    # Drop heat in regions where this fuel is backed out to its fuel inputs
    # first extract regions where doesn't have district_heat
    A_regions %>%
      filter(has_district_heat == 0) %>%
      select(GCAM_region_ID) %>%
      unique %>%
      mutate(fuel = "heat") ->
      region_heat

    L132.in_EJ_R_Sindenergy_F_Yh %>%
      anti_join(region_heat, by = c("GCAM_region_ID", "fuel")) %>% # then drop the regions selected in region_heat
      group_by(GCAM_region_ID, sector, fuel, year) %>%
      summarise(value = sum(value)) ->
      ungroup ->
      L132.in_EJ_R_indenergy_F_Yh

    # Where unit conversions have produced slightly negative numbers that should be 0, re-set to 0
    L132.in_EJ_R_indenergy_F_Yh %>%
      filter(value < 0 & value > -1e-6) %>%
      mutate(value = 0) %>%
      bind_rows(filter(L132.in_EJ_R_indenergy_F_Yh, !(value < 0 & value > -1e-6))) %>%
      ungroup -> # using ungroup to address error when running driver for unknown reason
      L132.in_EJ_R_indenergy_F_Yh

    # ===================================================

    # Produce outputs
    L132.in_EJ_R_indenergy_F_Yh %>%
      add_title("Industrial energy consumption (not including CHP) by GCAM region / fuel / historical year") %>%
      add_units("EJ") %>%
      add_comments("Industrial energy consumption (not including CHP) by GCAM region / fuel / historical year") %>%
      add_legacy_name("L132.in_EJ_R_indenergy_F_Yh") %>%
      add_precursors("energy/A_regions", "energy/enduse_sector_aggregation", "energy/enduse_fuel_aggregation",
                     "L131.in_EJ_R_Senduse_F_Yh", "L121.in_EJ_R_unoil_F_Yh", "L122.in_EJ_R_gasproc_F_Yh",
                     "L122.in_EJ_R_gasproc_F_Yh", "L122.out_EJ_R_gasproc_F_Yh", "L122.in_EJ_R_refining_F_Yh",
                     "L123.in_EJ_R_indchp_F_Yh", "L131.share_R_Senduse_heat_Yh", "L124.in_EJ_R_heat_F_Yh") ->
      L132.in_EJ_R_indenergy_F_Yh

    L132.in_EJ_R_indfeed_F_Yh %>%
      add_title("Industrial feedstock consumption by GCAM region / fuel / historical year") %>%
      add_units("EJ") %>%
      add_comments("Industrial feedstock consumption by GCAM region / fuel / historical year") %>%
      add_legacy_name("L132.in_EJ_R_indfeed_F_Yh") %>%
      add_precursors("L131.in_EJ_R_Senduse_F_Yh", "energy/enduse_sector_aggregation", "energy/enduse_fuel_aggregation") ->
      L132.in_EJ_R_indfeed_F_Yh

    L132.in_EJ_R_agenergy_F_Yh %>%
      add_title("Agricultural sector energy consumption by GCAM region / fuel / historical year") %>%
      add_units("EJ") %>%
      add_comments("Disaggregated from general industrial energy use for assignment to the agricultural sector") %>%
      same_precursors_as("L132.in_EJ_R_indenergy_F_Yh") %>%
      add_precursors("common/GCAM_region_names", "L125.LC_bm2_R_LT_Yh_GLU") ->
      L132.in_EJ_R_agenergy_F_Yh

    L132.in_EJ_R_rsrcenergy_F_Yh %>%
      add_title("Resource (oil, gas, coal) production energy consumption by GCAM region / resource / fuel / historical year") %>%
      add_units("EJ") %>%
      add_comments("Disaggregated from general industrial energy use for assignment to resource production") %>%
      same_precursors_as("L132.in_EJ_R_indenergy_F_Yh") ->
      L132.in_EJ_R_rsrcenergy_F_Yh

    return_data(L132.in_EJ_R_indenergy_F_Yh, L132.in_EJ_R_indfeed_F_Yh, L132.in_EJ_R_agenergy_F_Yh, L132.in_EJ_R_rsrcenergy_F_Yh)
  } else {
    stop("Unknown command")
  }
}
