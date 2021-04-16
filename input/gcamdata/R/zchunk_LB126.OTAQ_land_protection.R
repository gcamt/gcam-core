#' module_aglu_LB126.OTAQ_land_protection
#'
#' Build Total Land Cover by GCAM region, and by GCAM region and GLU, and by GCAM region/GLU/year.
#'
#' @param command API command to execute
#' @param ... other optional parameters, depending on command
#' @return Depends on \code{command}: either a vector of required inputs,
#' a vector of output names, or (if \code{command} is "MAKE") all
#' the generated outputs: \code{L125.LC_bm2_R}, \code{L125.LC_bm2_R_GLU}, \code{L125.LC_bm2_R_LT_Yh_GLU}.
#' The corresponding file in the
#' original data system was \code{LB125.LC_tot.R} (aglu level1).
#' @details This module builds three total land cover area data from the lower-level raw data:
#' 1) total land area by GCAM region; 2) total land area by GCAM region and GLU; and
#' 3) total land area by GCAM region, GLU and historical year. Units of the data are billion square meters.
#' The land area changing rates (bm2 per year) are checked to make sure they are within certain tolerances.
#' @importFrom assertthat assert_that
#' @importFrom dplyr filter mutate select
#' @importFrom tidyr gather spread
#' @author MC May 2017
module_aglu_LB126.OTAQ_land_protection <- function(command, ...) {
  if(command == driver.DECLARE_INPUTS) {
    return(c(FILE = "aglu/OTAQ_land_protection_L3_IUCN1_2",
             "L125.LC_bm2_R_GLU",
             "L125.LC_bm2_R_LT_Yh_GLU"))
  } else if(command == driver.DECLARE_OUTPUTS) {
    return(c("L126.ProtectFrac_R_LT_GLU"))
  } else if(command == driver.MAKE) {

    all_data <- list(...)[[1]]

    year <- value <- GLU_code <- `Percent Suitable` <- LC_bm2 <- GCAM_region_ID <-
      GLU <- Land_Type <- . <- HarvCropLand <- SuitableLand <- OtherArableLand <-
      Pasture <- Grassland <- Shrubland <- UnmanagedForest <- UnmanagedPasture <-
      ProtectFract <- NULL   # silence package check notes

    # Load required inputs
    OTAQ_land_protection_L3_IUCN1_2 <- get_data(all_data, "aglu/OTAQ_land_protection_L3_IUCN1_2")
    L125.LC_bm2_R_GLU <- get_data(all_data, "L125.LC_bm2_R_GLU")
    L125.LC_bm2_R_LT_Yh_GLU <- get_data(all_data, "L125.LC_bm2_R_LT_Yh_GLU")


    # -----------------------------------------------------------------------------
    # Perform computations
    # 2. Perform computations
    # The background equations and logic for the land protection fractions are as follows:
    # SuitableLand = Cropland + Pasture + (UnmanagedLand * (1 - ProtectFract))
    # SuitableLand = TotalLand * PercentSuitable
    # ProtectFract = 1 - ((SuitableLand - Cropland - Pasture) / UnmanagedLand) %>%
    #  pmin(0, ProtectFract) %>%
    #  pmax(1, ProtectFract)
    # ProtectFract = max(0, ProtectFract)
    L126.Percent_Suitable <- OTAQ_land_protection_L3_IUCN1_2 %>%
      select(GLU_code, `Percent Suitable`) %>%
      rename(GLU = GLU_code) %>%
      mutate(`Percent Suitable` = as.numeric(sub("%", "", `Percent Suitable`)) / 100)

    # Join this with the land totals by GCAM land use region to get the total suitable land by GCAM land use region
    L126.LCsuit_bm2_R_GLU <- L125.LC_bm2_R_GLU %>%
      left_join_error_no_match(L126.Percent_Suitable, by = "GLU") %>%
      mutate(SuitableLand = LC_bm2 * `Percent Suitable`) %>%
      select(GCAM_region_ID, GLU, SuitableLand)

    L126.ProtectFrac_R_LT_GLU <- filter(L125.LC_bm2_R_LT_Yh_GLU, year == max(HISTORICAL_YEARS)) %>%
      spread(key = Land_Type, value = value) %>%
      replace(., is.na(.), 0) %>%
      left_join_error_no_match(L126.LCsuit_bm2_R_GLU,
                               by = c("GCAM_region_ID", "GLU")) %>%
      mutate(ProtectFract = 1 - ((SuitableLand - HarvCropLand - OtherArableLand - Pasture) /
                                   (Grassland + Shrubland + UnmanagedForest + UnmanagedPasture)),
             ProtectFract = if_else(ProtectFract < 0, 0, ProtectFract),
             ProtectFract = if_else(ProtectFract > 1, 1, ProtectFract)) %>%
      select(GCAM_region_ID, GLU, ProtectFract)

    # Produce outputs

    L126.ProtectFrac_R_LT_GLU %>%
      add_title("Percent of unmanaged land protected by GCAM region, basin, and land use type") %>%
      add_units("unitless portion") %>%
      add_comments("land is restricted from agricultural expansion due to suitability issues") %>%
      add_precursors("aglu/OTAQ_land_protection_L3_IUCN1_2", "L125.LC_bm2_R_GLU", "L125.LC_bm2_R_LT_Yh_GLU") ->
      L126.ProtectFrac_R_LT_GLU

    return_data(L126.ProtectFrac_R_LT_GLU)
  } else {
    stop("Unknown command")
  }
}
