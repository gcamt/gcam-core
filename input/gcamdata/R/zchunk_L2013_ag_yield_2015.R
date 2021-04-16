#' module_aglu_ag_yield_2015
#'
#' Creates marginal abatement cost curves "MACC", for fossil resources, agriculture, animals, and processing.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L2013.AgProdChange_2015}.
#' @details Creates marginal abatement cost curves "MACC", for fossil resources, agriculture, animals, and processing.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author RH August 2017
module_aglu_ag_yield_2015 <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/iso_GCAM_regID",
             FILE = "common/GCAM_region_names",
             FILE = "aglu/AGLU_ctry",
             FILE = "aglu/FAO/FAO_ag_items_PRODSTAT",
             FILE = "aglu/FAO/FAO_ag_Prod_HA_recent",
             FILE = "water/basin_to_country_mapping",
             "L100.LDS_ag_HA_ha",
             "L2052.AgProdChange_ag_irr_ref"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L2013.AgProdChange_2015"))
  } else if(command == driver.MAKE) {

    # Silence package checks
    Value <- Area <- Element <- Code <- Year <- FAO_country <- iso <-
      `Area harvested` <- Production <- year <- item.code <- `Item Code` <- Yield <-
      GTAP_crop <- GLU <- value <- `2010` <- `2015` <- area <- yield_2010 <-
      yield_2015 <- GCAM_commodity <- GCAM_region_ID <- prod_2010 <- prod_2015 <-
      region <- AgSupplySector <- AgSupplySubsector <- AgProductionTechnology <-
      AgProdChange <- NULL

    all_data <- list(...)[[1]]

    # Load required inputs
    iso_GCAM_regID <- get_data(all_data, "common/iso_GCAM_regID")
    GCAM_region_names <- get_data(all_data, "common/GCAM_region_names")
    AGLU_ctry <- get_data(all_data, "aglu/AGLU_ctry")
    FAO_ag_items_PRODSTAT <- get_data(all_data, "aglu/FAO/FAO_ag_items_PRODSTAT")
    FAO_ag_Prod_HA_recent <- get_data(all_data, "aglu/FAO/FAO_ag_Prod_HA_recent")
    basin_to_country_mapping <- get_data(all_data, "water/basin_to_country_mapping")
    L100.LDS_ag_HA_ha <- get_data(all_data, "L100.LDS_ag_HA_ha")
    L2052.AgProdChange_ag_irr_ref <- get_data(all_data, "L2052.AgProdChange_ag_irr_ref")

    # ===================================================

    # Select relevant columns, join in iso codes, spread to compare HA and Prod, and average the 5-year blocks
    # using inner_join on the country data as there are several minor new countries not in AGLU_ctry.csv
    L2013.AgYieldGrowth_FAO <- select(FAO_ag_Prod_HA_recent, Area, Element, item.code = `Item Code`, Year, Value) %>%
      drop_na() %>%
      inner_join(select(AGLU_ctry, FAO_country, iso),
                               by = c(Area = "FAO_country")) %>%
      spread(Element, Value) %>%
      mutate(Yield = if_else(`Area harvested` > 0, Production / `Area harvested`, 0),
             year = if_else(Year %in% 2008:2012, 2010,
                            if_else(Year %in% 2013:2017, 2015, 0))) %>%
      # drop any years that are queried but not used in the calculations
      filter(year != 0) %>%
      group_by(iso, item.code, year) %>%
      summarise(Yield = mean(Yield)) %>%
      spread(year, Yield) %>%
      # drop any observations with NA for yield in either year (e.g., where production and harvested area were zero)
      drop_na()

    # This country- and item-level yield data needs to be downscaled to the basin prior to aggregating by GCAM region and commodity
    # Multiply the harvested area by the yields in each year to get the weighted yields
    # left_join followed by drop_na to drop the minor crops that are in FAO_ag_items_PRODSTAT, but aren't mapped between the databases
    L2013.WeightedYieldGrowth <- left_join(L100.LDS_ag_HA_ha,
                                           select(FAO_ag_items_PRODSTAT, item.code, GTAP_crop),
                                           by = "GTAP_crop") %>%
      # drop missing values. this takes place at several points. here it's to avoid dropping all data points if some years are available but not others.
      drop_na() %>%
      inner_join(L2013.AgYieldGrowth_FAO, by = c("iso", "item.code")) %>%
      select(iso, GLU, GTAP_crop, area = value, yield_2010 = `2010`, yield_2015 = `2015`) %>%
      mutate(prod_2010 = area * yield_2010,
             prod_2015 = area * yield_2015) %>%
      left_join(select(FAO_ag_items_PRODSTAT, GTAP_crop, GCAM_commodity), by = "GTAP_crop") %>%
      # drop crops in the mapping (e.g., natural rubber) that aren't assigned to any GCAM commodity
      drop_na() %>%
      left_join_error_no_match(select(iso_GCAM_regID, iso, GCAM_region_ID), by = "iso") %>%
      group_by(GCAM_region_ID, GCAM_commodity, GLU) %>%
      summarise(area = sum(area),
                prod_2010 = sum(prod_2010),
                prod_2015 = sum(prod_2015)) %>%
      ungroup() %>%
      mutate(yield_2010 = prod_2010 / area,
             yield_2015 = prod_2015 / area,
             AgProdChange = (yield_2015 / yield_2010)^(1/5) - 1) %>%
      drop_na()

    # To generate the CSV file that will be written to XML, replace the region ID with region name, GLU code with GLU name,
    # and fill out the technologies in the model (using the baseline AgProdChange file to determine which technologies to include)

    # First, create a table with all of the potential techs with yield growth rate
    L2013.AgTechs <- select(L2052.AgProdChange_ag_irr_ref, region, AgSupplySector, AgSupplySubsector, AgProductionTechnology) %>%
      distinct()

    L2013.AgProdChange_2015 <- L2013.WeightedYieldGrowth %>%
      left_join_error_no_match(GCAM_region_names, by = "GCAM_region_ID") %>%
      replace_GLU(basin_to_country_mapping) %>%
      mutate(AgSupplySector = GCAM_commodity,
             AgSupplySubsector = paste(GCAM_commodity, GLU, sep = aglu.CROP_GLU_DELIMITER),
             year = 2015,
             AgProdChange = round(AgProdChange, aglu.DIGITS_AGPRODCHANGE)) %>%
      left_join(L2013.AgTechs,
                by = c("region", "AgSupplySector", "AgSupplySubsector")) %>%
      select(LEVEL2_DATA_NAMES[["AgProdChange"]])

    # ===================================================

    # Produce outputs
    L2013.AgProdChange_2015 %>%
      add_title("Ag productivity change 2010-2015") %>%
      add_units("annual rate of increase") %>%
      add_comments("revision to existing default yield assumptions, based on FAOSTAT 2008-2017 data") %>%
      add_precursors("common/iso_GCAM_regID", "common/GCAM_region_names", "aglu/FAO/FAO_ag_Prod_HA_recent",
                     "aglu/FAO/FAO_ag_items_PRODSTAT", "aglu/AGLU_ctry", "water/basin_to_country_mapping", "L100.LDS_ag_HA_ha",
                     "L2052.AgProdChange_ag_irr_ref") ->
      L2013.AgProdChange_2015

    return_data(L2013.AgProdChange_2015)
  } else {
    stop("Unknown command")
  }
}
