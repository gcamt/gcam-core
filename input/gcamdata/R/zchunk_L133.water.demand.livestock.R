#' module_water_L133.water.demand.livestock
#'
#' Calculate livestock water coefficients by region ID / GCAM_commodity/ water type
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L133.water_demand_livestock_R_C_W_km3_Mt}. The corresponding file in the
#' original data system was \code{L133.water.demand.livestock.R} (water level1).
#' @details Describe in detail what this chunk does.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author KRD November 2017
module_water_L133.water.demand.livestock <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "common/iso_GCAM_regID",
             "L105.an_Prod_Mt_R_C_Y",
             FILE = "water/LivestockWaterFootprint_MH2010",
             FILE = "water/FAO_an_items_Stocks",
             "L100.FAO_an_Stocks",
             "L100.FAO_an_Dairy_Stocks"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L133.water_demand_livestock_R_C_W_km3_Mt"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    # Load required inputs
    iso_GCAM_regID <- get_data(all_data, "common/iso_GCAM_regID")
    L105.an_Prod_Mt_R_C_Y <- get_data(all_data, "L105.an_Prod_Mt_R_C_Y")
    LivestockWaterFootprint_MH2010 <- get_data(all_data, "water/LivestockWaterFootprint_MH2010")
    FAO_an_items_Stocks <- get_data(all_data, "water/FAO_an_items_Stocks")
    L100.FAO_an_Stocks <- get_data(all_data, "L100.FAO_an_Stocks")
    L100.FAO_an_Dairy_Stocks <- get_data(all_data, "L100.FAO_an_Dairy_Stocks")

    # Silence package checks
    year <- iso <- item <- value <- dairy.to.total <- dairy.adj <-
      coefficient <- GCAM_region_ID <- GCAM_commodity <- water.consumption <-
      water_type <- coefficient <- Coefficient <- NULL

    # ===================================================
    # Calculate livestock water coefficients by region ID / GCAM_commodity/ water type.

    # Start by finding  the number of non-dairy producing livestock.

    # Create a tibble of dairy producing stocks by country and FAO animal
    # product name. Only use stock information from the year 2000 since that is the
    # year the water use coefficients are from. This tibble will be used in the next step to
    # remove dairy animals.
    L100.FAO_an_Dairy_Stocks %>%
      filter(year == 2000) %>%
      select(iso, item, value, year) %>%
      left_join_error_no_match(FAO_an_items_Stocks %>% select(item, dairy.to.total),
                               by = "item") %>%
      select(iso, item = dairy.to.total, dairy.adj = value, year) ->
      L133.dairy_an_adj

    # Adjust the total FAO animal stocks by removing the FAO dairy producing animals.
    # Assume the dairy stock has a value of zero if no data is available. The end
    # result is a count of non-dairy producing livestock.
    L100.FAO_an_Stocks %>%
      # Use left_join here because we do not expect a 1:1 match.
      left_join(L133.dairy_an_adj, by = c("item", "iso", "year")) %>%
      replace_na(list(dairy.adj = 0)) %>%
      mutate(value = value - dairy.adj) ->
      L133.FAO_an_heads

    # It seems the PDR stoped reporting data after 1994 for total livestock, this causes the
    # count of non-dairy producing livestock to be negative. For now set any negative
    # count of non-dairy producing livestock to zero.
    L133.FAO_an_heads <- mutate(L133.FAO_an_heads, value = if_else(value < 0, 0, value))

    # Now combine the nondairy producing livestock and dairy producing livestock information
    # into a single tibble. Subsest for the year 2000 since that is the year the water use
    # coefficients are from.
    L133.FAO_an_heads %>%
      select(iso, item, year, value) %>%
      bind_rows(L100.FAO_an_Dairy_Stocks %>%
                  select(iso, item, year, value)) %>%
      filter(year == 2000) ->
      L133.FAO_an_heads


    # Now calculate the water demand by FAO item.
    #
    # Add FAO stock information, livestock water use coefficient, and GCAM information to the dairy and non-dairy
    # livestock count form mapping files.
    L133.FAO_an_heads %>%
      # A 1:1 match is not expected and we do not want NAs introduced to the data frame so
      # use inner join here.
      inner_join(FAO_an_items_Stocks, by = "item") %>%
      # A 1:1 match is not expected and we do not want NAs introduced to the data frame so
      # use inner join here.
      inner_join(LivestockWaterFootprint_MH2010, by = "Animal") %>%
      left_join_error_no_match(iso_GCAM_regID, by = "iso") ->
      L133.FAO_an_heads

    # Multiply the livestock count by the livestock water use coefficient from Mekonnen and Hoekstra 2010.
    #
    # Since the Mekonnen and Hoekstra 2010 coefficient is in liters/head per day convert from L to m^3 per
    # 1000 heads by dividing by 1000 and then convert from daily consumption to per year.
    L133.FAO_an_heads %>%
      mutate(water.consumption = value * Coefficient / 1000 / CONV_DAYS_YEAR) ->
      L133.FAO_an_heads


    # Calculate water demand by GCAM_commodity
    #
    # Aggregate the livestock water consumption by GCAM region and commodity.
    L133.FAO_an_heads %>%
      group_by(GCAM_region_ID, GCAM_commodity) %>%
      summarise(water.consumption = sum(water.consumption)) %>%
      ungroup ->
      L133.water_demand_livestock_R_C_W_km3_Mt

    # Add FAO production information to the tibble of aggregated livestock water consumption.
    L133.water_demand_livestock_R_C_W_km3_Mt %>%
      left_join_error_no_match(L105.an_Prod_Mt_R_C_Y %>%
                                 filter(year == 2000) %>%
                                 select(GCAM_region_ID, GCAM_commodity, year, value),
        by = c("GCAM_region_ID", "GCAM_commodity")) ->
      L133.water_demand_livestock_R_C_W_km3_Mt

    # Average the aggregated livestock water consumption by the total production. Since water
    # consumption is in m^3 and production is in Mt to km^3/Mt we must divide by 1e9.
    L133.water_demand_livestock_R_C_W_km3_Mt %>%
      mutate(coefficient = water.consumption / value / 1e9) ->
      L133.water_demand_livestock_R_C_W_km3_Mt


    # Water withdrawals are assumed to be the same as consumption.
    #
    # Add the water type information to the livestock water demand tibble. Add water type information
    # to the tibble, since the water withdrawals are the same as consumption for livestock use the same
    # coefficients for the water withdrawals and water consumption.
    L133.water_demand_livestock_R_C_W_km3_Mt %>%
      repeat_add_columns(tibble(water_type = water.MAPPED_WATER_TYPES)) ->
      L133.water_demand_livestock_R_C_W_km3_Mt

    # Select the columns to output.
    L133.water_demand_livestock_R_C_W_km3_Mt %>%
      select(GCAM_region_ID, GCAM_commodity, water_type, coefficient) ->
      L133.water_demand_livestock_R_C_W_km3_Mt


    # ===================================================

    # Produce outputs
    L133.water_demand_livestock_R_C_W_km3_Mt %>%
      add_title("Livestock water coefficients by region ID / GCAM_commodity/ water type") %>%
      add_units("coefficient = m^3 / Mt") %>%
      add_comments("Separate non-dairy and dairy producing livestock and multiply by the Mekonnen and Hoekstra 2010 livestock water use coefficient.") %>%
      add_comments("Aggregate the life stock water consumption by GCAM region livestock production.") %>%
      add_legacy_name("L133.water_demand_livestock_R_C_W_km3_Mt") %>%
      add_precursors("common/iso_GCAM_regID",
                     "L105.an_Prod_Mt_R_C_Y",
                     "water/LivestockWaterFootprint_MH2010",
                     "water/FAO_an_items_Stocks",
                     "L100.FAO_an_Stocks",
                     "L100.FAO_an_Dairy_Stocks") ->
      L133.water_demand_livestock_R_C_W_km3_Mt

    return_data(L133.water_demand_livestock_R_C_W_km3_Mt)
  } else {
    stop("Unknown command")
  }
}
