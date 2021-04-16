#' module_energy_L271.ag_en_freight_inputs
#'
#' Generate inputs of freight transportation to energy and agricultural commodities, and modify the
#' final demands of freight transportation services accordingly
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L271.TechCoef_freight}, \code{L271.TechPMult_freight}, \code{L271.TechCost_freight}, \code{L271.BaseService_freightNetEnAg}.
#' @details The freight input-output coefficients are exogenous, as are cost adjustments and price unit conversions.
#'   They are multiplied by commodity flow volumes to compute the trn_freight quantities that are no longer part of the
#'   final demands, and this deduction is performed here.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter group_by if_else inner_join mutate rename select summarise ungroup
#' @importFrom tidyr complete nesting
#' @author GPK March 2019
module_energy_L271.ag_en_freight_inputs <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/GCAM_region_names",
             FILE = "energy/A271.freight_coef",
             FILE = "energy/A271.freight_cost_adj",
             "L1011.en_bal_EJ_R_Si_Fi_Yh",
             "L121.in_EJ_R_TPES_crude_Yh",
             "L121.in_EJ_R_TPES_unoil_Yh",
             "L122.in_EJ_R_gasproc_F_Yh",
             "L122.out_EJ_R_refining_F_Yh",
             "L222.GlobalTechCoef_en",
             "L254.BaseService_trn",
             "L202.StubTechProd_in",
             "L203.StubTechProd_food_crop",
             "L203.StubTechProd_nonfood_crop",
             "L240.Production_reg_imp",
             "L240.Production_tra"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L271.TechCoef_freight",
             "L271.TechPMult_freight",
             "L271.TechCost_freight",
             "L271.BaseService_freightNetEnAg"))
  } else if(command == driver.MAKE) {

    value <- region <- supplysector <- subsector <- technology <- minicam.energy.input <-
      price.unit.conversion <- year <- coefficient <- minicam.non.energy.input <- input.cost <-
      fuel <- energy_EJ <- freight_tkm <- sector <- biomassOil_coef <- GCAM_region_ID <-
      stub.technology <- calOutputValue <- base.service <- NULL # silence package check notes

    all_data <- list(...)[[1]]

    # Load required inputs
    GCAM_region_names <- get_data(all_data, "common/GCAM_region_names")
    A271.freight_coef <- get_data(all_data, "energy/A271.freight_coef")
    A271.freight_cost_adj <- get_data(all_data, "energy/A271.freight_cost_adj")
    L1011.en_bal_EJ_R_Si_Fi_Yh <- get_data(all_data, "L1011.en_bal_EJ_R_Si_Fi_Yh")
    L121.in_EJ_R_TPES_crude_Yh <- get_data(all_data, "L121.in_EJ_R_TPES_crude_Yh")
    L121.in_EJ_R_TPES_unoil_Yh <- get_data(all_data, "L121.in_EJ_R_TPES_unoil_Yh")
    L122.in_EJ_R_gasproc_F_Yh <- get_data(all_data, "L122.in_EJ_R_gasproc_F_Yh")
    L122.out_EJ_R_refining_F_Yh <- get_data(all_data, "L122.out_EJ_R_refining_F_Yh")
    L222.GlobalTechCoef_en <- get_data(all_data, "L222.GlobalTechCoef_en")
    L254.BaseService_trn <- get_data(all_data, "L254.BaseService_trn")
    L202.StubTechProd_in <- get_data(all_data, "L202.StubTechProd_in")
    L203.StubTechProd_food_crop <- get_data(all_data, "L203.StubTechProd_food_crop")
    L203.StubTechProd_nonfood_crop <- get_data(all_data, "L203.StubTechProd_nonfood_crop")
    L240.Production_reg_imp <- get_data(all_data, "L240.Production_reg_imp")
    L240.Production_tra <- get_data(all_data, "L240.Production_tra")

    # L271.TechCoef_freight: technology coefficients of LCA-type inputs
    L271.TechCoef_Pmult_freight <- gather_years( A271.freight_coef, value_col = "coefficient") %>%
      complete(nesting(region, supplysector, subsector, technology, minicam.energy.input, price.unit.conversion),
               year = unique(c(year, MODEL_YEARS))) %>%
      group_by(region, supplysector, subsector, technology, minicam.energy.input) %>%
      mutate(coefficient = round(approx_fun(year, coefficient, rule = 2),
                                 energy.DIGITS_COEFFICIENT),
             price.unit.conversion = round(approx_fun(year, price.unit.conversion),
                                           energy.DIGITS_COEFFICIENT),
             market.name = if_else(grepl("traded", supplysector),
                                   substr(subsector, 1, nchar(subsector) - nchar(supplysector) - 1),
                                   region)) %>%
      ungroup() %>%
      filter(year %in% MODEL_YEARS)

    L271.TechCoef_freight <- select(L271.TechCoef_Pmult_freight, LEVEL2_DATA_NAMES[["TechCoef"]])
    L271.TechPMult_freight <- select(L271.TechCoef_Pmult_freight, LEVEL2_DATA_NAMES[["TechPMult"]])

    # L271.TechCost_freight: technology costs for techs that take freight transportation inputs
    L271.TechCost_freight <- gather_years( A271.freight_cost_adj, value_col = "input.cost") %>%
      complete(nesting(region, supplysector, subsector, technology, minicam.non.energy.input),
               year = unique(c(year, MODEL_YEARS))) %>%
      group_by(region, supplysector, subsector, technology, minicam.non.energy.input) %>%
      mutate(input.cost = round(approx_fun(year, input.cost, rule = 2),
                                energy.DIGITS_COST)) %>%
      ungroup() %>%
      filter(year %in% MODEL_YEARS) %>%
      select(LEVEL2_DATA_NAMES[["TechCost"]])

    # Computing the tkm to deduct from freight transportation service demands for OIL
    L271.in_EJ_R_TPES_oil <- bind_rows(L121.in_EJ_R_TPES_crude_Yh, L121.in_EJ_R_TPES_unoil_Yh) %>%
      filter(year %in% MODEL_YEARS) %>%
      rename(energy_EJ = value) %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    L271.tkm_oil <- filter(L271.TechCoef_freight,
                           supplysector == "regional oil",
                           year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.in_EJ_R_TPES_oil, region, fuel, year, energy_EJ),
                               by = c("region", subsector = "fuel", "year")) %>%
      mutate(freight_tkm = coefficient * energy_EJ) %>%
      group_by(region, minicam.energy.input, year) %>%
      summarise(freight_tkm = sum(freight_tkm))

    # Computing the tkm to deduct from freight transportation service demands for COAL
    L271.in_EJ_R_TPES_coal <- filter(L1011.en_bal_EJ_R_Si_Fi_Yh,
                                     sector == "TPES",
                                     fuel == "coal",
                                     year %in% MODEL_BASE_YEARS) %>%
      rename(energy_EJ = value) %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    L271.tkm_coal <- filter(L271.TechCoef_freight,
                            supplysector == "regional coal",
                            year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.in_EJ_R_TPES_coal, region, year, energy_EJ),
                               by = c("region", "year")) %>%
      mutate(freight_tkm = coefficient * energy_EJ) %>%
      select(region, minicam.energy.input, year, freight_tkm)

    # Computing the tkm to deduct from freight transportation service demands for regional BIOMASS
    # 8/13/2020 - gpk - the IEA energy balances don't track biomass feedstock inputs to biogas production,
    # so they aren't in L1011.en_bal, though they are in the model.
    # Need to add these in specifically
    L271.in_EJ_R_TPES_bio <- filter(L1011.en_bal_EJ_R_Si_Fi_Yh,
                                    sector == "TPES",
                                    fuel == "biomass",
                                    year %in% MODEL_BASE_YEARS) %>%
      bind_rows(filter(L122.in_EJ_R_gasproc_F_Yh, fuel == "biomass")) %>%
      group_by(GCAM_region_ID, fuel, year) %>%
      summarise(energy_EJ = sum(value)) %>%
      ungroup() %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    L271.tkm_bio <- filter(L271.TechCoef_freight,
                           supplysector == "regional biomass",
                           year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.in_EJ_R_TPES_bio, region, year, energy_EJ),
                               by = c("region", "year")) %>%
      mutate(freight_tkm = coefficient * energy_EJ) %>%
      select(region, minicam.energy.input, year, freight_tkm)

    # Computing the tkm to deduct from freight transportation service demands for ETHANOL FEEDSTOCKS
    L271.out_EJ_R_ethanol <- filter(L122.out_EJ_R_refining_F_Yh,
                                    grepl("ethanol", sector),
                                    year %in% MODEL_BASE_YEARS) %>%
      rename(energy_EJ = value) %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    L271.tkm_ethanolfeed <- filter(L271.TechCoef_freight,
                                   grepl("for ethanol", supplysector),
                                   year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.out_EJ_R_ethanol, region, year, energy_EJ),
                               by = c("region", "year")) %>%
      mutate(freight_tkm = coefficient * energy_EJ) %>%
      select(region, minicam.energy.input, year, freight_tkm)

    # Computing the tkm to deduct from freight transportation service demands for BIODIESEL FEEDSTOCKS (soy)
    L271.out_EJ_R_biodiesel <- filter(L122.out_EJ_R_refining_F_Yh,
                                      sector == "biodiesel",
                                      year %in% MODEL_BASE_YEARS) %>%
      rename(energy_EJ = value) %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    # Note - biomass oil IO coef to biodiesel is not necessarly 1 - need to get it from the table
    L271.IOcoef_biodiesel <- filter(L222.GlobalTechCoef_en,
                                    technology == "biodiesel",
                                    minicam.energy.input == "regional biomassOil") %>%
      rename(biomassOil_coef = coefficient)

    L271.tkm_soy <- filter(L271.TechCoef_freight,
                           supplysector == "regional biomassOil",
                           year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.out_EJ_R_biodiesel, region, year, energy_EJ),
                               by = c("region", "year")) %>%
      left_join_error_no_match(select(L271.IOcoef_biodiesel, year, biomassOil_coef),
                               by = "year") %>%
      mutate(freight_tkm = coefficient * energy_EJ * biomassOil_coef) %>%
      select(region, minicam.energy.input, year, freight_tkm)

    # Computing the tkm to deduct from freight transportation service demands for REFINED LIQUIDS
    L271.out_EJ_R_refliq <- filter(L122.out_EJ_R_refining_F_Yh,
                                   year %in% MODEL_BASE_YEARS) %>%
      group_by(GCAM_region_ID, year) %>%
      summarise(energy_EJ = sum(value)) %>%
      ungroup() %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID")

    # Note - using "refined liquids enduse" as a proxy for all refined liquids. As noted in the assumptions table, the
    # method is not set up to handle different tkm coefficients for the different consumer classes of refined liquids. This
    # is fine for now as there is no data on that anyway. Still the issue is that there is nowhere in the data system that
    # the quantities of refined liquids enduse vs industrial are actually written out.
    L271.tkm_refliq <- filter(L271.TechCoef_freight,
                              supplysector == "refined liquids enduse",
                              year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(select(L271.out_EJ_R_refliq, region, year, energy_EJ),
                               by = c("region", "year")) %>%
      mutate(freight_tkm = coefficient * energy_EJ) %>%
      select(region, minicam.energy.input, year, freight_tkm)

    # Computing the tkm to deduct from freight transportation service demands for CROP CONSUMPTION (domestic + imports)
    # 11/14/2018 modification - this needs to include the individual components to the demands (food, non-food, feed)
    # in order to not double-count the freight transport for crops used for biofuel production (accounted elsewhere)
    L271.in_Mt_R_DomSupply_crops <- bind_rows( L202.StubTechProd_in, L203.StubTechProd_food_crop,
                                               L203.StubTechProd_nonfood_crop, L240.Production_reg_imp) %>%
      mutate(technology = if_else(is.na(technology), stub.technology, technology)) %>%
      select(region, supplysector, subsector, technology, year, calOutputValue)

    L271.tkm_crop_domSupply <- filter(L271.TechCoef_freight,
                                      supplysector %in% L271.in_Mt_R_DomSupply_crops$supplysector,
                                      year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(L271.in_Mt_R_DomSupply_crops,
                               by = c("region", "supplysector", "subsector", "technology", "year")) %>%
      mutate(freight_tkm = coefficient * calOutputValue) %>%
      group_by(region, minicam.energy.input, year) %>%
      summarise(freight_tkm = sum(freight_tkm))

    # "Computing the tkm to deduct from freight transportation service demands for CROP EXPORTS" )
    L271.in_Mt_R_Exports_crops <- select(L240.Production_tra,
                                         region, supplysector, subsector, technology, year, calOutputValue)

    L271.tkm_crop_exports <- filter(L271.TechCoef_freight,
                                    supplysector %in% L271.in_Mt_R_Exports_crops$supplysector,
                                    year %in% MODEL_BASE_YEARS) %>%
      left_join_error_no_match(L271.in_Mt_R_Exports_crops,
                               by = c("region", "supplysector", "subsector", "technology", "year")) %>%
      mutate(freight_tkm = coefficient * calOutputValue,
             region = substr(subsector, 1, nchar(subsector) - nchar(supplysector) - 1)) %>%
      group_by(region, minicam.energy.input, year) %>%
      summarise(freight_tkm = sum(freight_tkm))

    # L271.BaseService_freightNetEnAg: Applying the deductions to total tkm
    L271.tkm_tot <- bind_rows( L271.tkm_oil, L271.tkm_coal, L271.tkm_bio, L271.tkm_ethanolfeed, L271.tkm_soy,
                               L271.tkm_refliq, L271.tkm_crop_domSupply, L271.tkm_crop_exports) %>%
      group_by(region, minicam.energy.input, year) %>%
      summarise(freight_tkm = sum(freight_tkm)) %>%
      ungroup()

    L271.BaseService_freightNetEnAg <- inner_join(L254.BaseService_trn,
                                                  L271.tkm_tot,
                                                  by = c("region", "year", energy.final.demand = "minicam.energy.input")) %>%
      mutate(base.service = if_else(is.na(freight_tkm), base.service, base.service - freight_tkm)) %>%
      select(LEVEL2_DATA_NAMES[["BaseService"]])

    # Produce outputs
    L271.TechCoef_freight %>%
      add_title("Input-output coefficients of freight transport into energy and ag commodities") %>%
      add_units("million tkm per EJ for energy goods; km of travel distance for ag goods") %>%
      add_comments("Adds a trn_freight input to commodities that are shipped") %>%
      add_comments("IO coefs reflect travel distances and, for energy goods, energy contents") %>%
      add_precursors("energy/A271.freight_coef") ->
      L271.TechCoef_freight

    L271.TechPMult_freight %>%
      add_title("Price-unit-conversions on trn_freight inputs to shipped commodities") %>%
      add_units("Uniteless multiplier") %>%
      add_comments("Reduces the cost paid for shipping from the composite trn_freight cost") %>%
      add_comments("Applies to goods mostly shipped by rail or ship, not truck, so initial costs are over-estimated") %>%
      add_precursors("energy/A271.freight_coef") ->
      L271.TechPMult_freight

    L271.TechCost_freight %>%
      add_title("Non-energy costs of shipped commodities, adjusted for explicitly modeled shipping costs") %>%
      add_units("1975$/GJ, 1975$/kg") %>%
      add_comments("Counter-balances the cost effects of explicitly including freight transport costs") %>%
      add_precursors("energy/A271.freight_cost_adj") ->
      L271.TechCost_freight

    L271.BaseService_freightNetEnAg %>%
      add_title("Revised base service of freight transportation final demand sectors") %>%
      add_units("million tonne-km") %>%
      add_comments("Counter-balances the effects of explicitly including freight transport inputs to energy and ag commodities") %>%
      add_precursors("common/GCAM_region_names", "energy/A271.freight_coef", "L1011.en_bal_EJ_R_Si_Fi_Yh", "L121.in_EJ_R_TPES_crude_Yh",
                     "L121.in_EJ_R_TPES_unoil_Yh", "L122.in_EJ_R_gasproc_F_Yh", "L122.out_EJ_R_refining_F_Yh", "L222.GlobalTechCoef_en",
                     "L254.BaseService_trn", "L202.StubTechProd_in", "L203.StubTechProd_food_crop", "L203.StubTechProd_nonfood_crop",
                     "L240.Production_reg_imp", "L240.Production_tra") ->
      L271.BaseService_freightNetEnAg

    return_data(L271.TechCoef_freight,
                L271.TechPMult_freight,
                L271.TechCost_freight,
                L271.BaseService_freightNetEnAg)

  } else {
    stop("Unknown command")
  }
}
