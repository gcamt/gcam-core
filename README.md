# GCAM-T 2020.0
This documentation describes GCAM-T 2020.0 (hereafter “GCAM-T”), a version of the Global Change Analysis Model (GCAM)
 developed through modifications to GCAM v5.1.2 (Calvin, Patel et al. 2019). GCAM-T was developed as a collaboration
 between the Pacific Northwest National Lab (PNNL) Joint Global Change Research Institute (JGCRI) and the Environmental
 Protection Agency (EPA) Office of Transportation and Air Quality (OTAQ). EPA OTAQ has supported development of GCAM for
 several years. A number of these development efforts, supported in whole or in part, by OTAQ have been adopted into
 GCAM-core releases available at: https://github.com/JGCRI/gcam-core/releases. This document describes only modifications
 which are present in GCAM-T, but which were not included in the released GCAM-v5.1.2. Where developments in GCAM-T have
 been adopted in later GCAM-core releases (GCAM-v5.2 or later), we refer to core release documentation for further details.
 
## Regional Agricultural Markets and Trade
GCAM-T includes the representation of regional agricultural markets with global trade adopted for GCAM v5.2. (For
 more information see the section titled “Regional Agricultural Markets and Trade” at
 http://jgcri.github.io/gcam-doc/aglu.html.) This approach models the following: differentiated regional markets
 and prices, Armington regional preferences for domestic versus imported crops calibrated to historical agricultural
 trade data, and gross imports and exports through a single global market for each crop.  
 
### Upstream Energy and Agricultural, and Transportation Linkages
GCAM v5.1 does not dynamically track some streams of energy consumption related to agricultural and energy resource
 production and transport. This energy consumption is accounted for at an aggregate level in the 2010 base year, but
 shifts in energy demand and emissions associated with production or transport of individual commodities are not tracked
 over time. As an example, in GCAM v5.1 an increase in the demand for corn would not, all else equal, change the demand
 for agricultural energy, as the energy used to operate tractors, combines, and other agricultural equipment is represented
 in the aggregate industrial sector, which has no linkage to agricultural production. The quantity of energy demanded for
 this use is therefore not directly driven by changes in crop demands in GCAM v5.1. For GCAM-T the inputs to production
 technologies have been expanded in two different categories: agricultural energy inputs to agricultural production and
 energy inputs to resource production. The vast majority of energy data in GCAM’s 2010 base year comes from the IEA Energy
 Balances. For some regions of the world, this is the only consistently reported data set available.  Therefore, except
 where otherwise noted, we continued to rely on IEA data to enhance the detail and dynamics of the energy sector
 representation.
 
### Agricultural energy inputs
In GCAM v5.1, agricultural energy consumption is assigned to the aggregate industrial sector, which also includes all
 industrial subsectors, such as manufacturing, mining, and construction.  Agricultural energy consumption is not
 disaggregated from other industrial energy use. To better represent the feedbacks between the agricultural and energy
 systems, GCAM-T disaggregates and tracks the liquid fuels consumed to produce crops (e.g, liquid fuels used by farm
 equipment), in all model regions and time periods, separately from this aggregated industrial sector. The source data
 for 2010 base year energy consumption in GCAM comes from the IEA Energy Balances, which is the IEA’s historical database
 of energy consumption at the country level (IEA 2011). This data set includes specific reporting of liquid fuel use in the
 agricultural sector, which we used to perform the disaggregation. While agricultural sector consumption of other fuels
 (including coal, biomass, electricity, natural gas, and heat) is also reported in the IEA Energy Balances in some cases,
 the coverage is sparse. In addition, some of the energy consumption of non-liquid fuels that are reported in the
 agricultural sector in the IEA Energy Balances is tracked in sectors other than the agricultural sector in GCAM; for
 example electricity for irrigation pumping would be handled in the water sectors of GCAM rather than the agricultural
 production technologies. Dynamic consumption of these other fuels (i.e., consumption that shifts in response to changes
 in price) was therefore not added to GCAM-T. Moreover, fuel energy inputs per hectare of cellulosic bioenergy crop
 production are obtained from Adler et al., (2007).
 
In GCAM-T, the method of estimating agricultural energy consumption associated with individual crops and crop groups in
 the 2010 base year is to map the liquid fuel inputs required for each crop, based on cropland area by crop in each region.
 In the source data, some countries (e.g., South Korea, Japan) had extremely high energy use coefficients, which seem
 likely to result from reporting or data collection errors. To account for this, the maximum amount of energy per unit
 cropland was set to 20 percent higher than the value for the USA in each time step, based on expert judgment. The energy
 usage for crops tends to be higher for low-yielding crops, all else equal, since the energy usage is determined on a per
 acre basis. In future periods, the input-output coefficients of crops stay constant for any countries at or greater than
 the levels in the USA, and for the rest of the countries, the input-output coefficients increase at a rate equal to the
 assumed rate of crop yield improvement, until the coefficients reach the USA level.
 
Because both GCAM 5.1 and GCAM-T differentiate agricultural production technologies within each land use region and
 irrigation level into two representative yield levels, representing a spectrum of agricultural practices, the energy
 input-output coefficients are assigned differentially. Specifically, the representative high-yielding technology is
 assumed to have an energy input-output coefficient that is twice as high as the low-yielding technology. This ratio is
 currently assumed equal across all crops and regions, given the relatively simple means of modeling of the high- and
 low-input technologies at present.
 
### Energy Inputs to Energy Resource Production
We added several energy inputs to energy resource production in GCAM-T, including electricity and liquid fuels for coal
 mining, and natural gas and liquid fuels consumed for natural gas and crude oil production. As is the case for other
 energy consumption data, this energy quantity flow data in the 2010 base year is primarily taken from IEA (2011). Data
 for coal however are instead taken from USDOE (2007). Because natural gas and oil production energy demands are
 reported under the same sector in the IEA Energy Balances, the natural gas inputs to this sector are disaggregated
 using production volumes multiplied by assumed default coefficients that are differentiated between oil and gas
 production. Note that the energy inputs to coal mining are either not reported or very low in most countries' data
 in the energy balances.
 
In all modeled periods (i.e., from 2015 onward), coefficients are used uniformly across regions.  This is intended
 to address inconsistent reporting practices in the historical data. The coefficients are indicated on an energy in
 per unit of energy out basis. The specific values are estimated from data in countries where it seemed to be reported
 accurately, based on expert judgment.
 
### Upstream Freight Transportation Inputs
The core version of GCAM 5.1 does not dynamically track freight transportation demand related to agricultural and
 energy resource production and transport but instead accounts for its demand and energy consumption at an aggregate
 level. As an example, in GCAM 5.1 an increase in the demand for liquid fuels would not, all else equal, directly
 change the demand for freight transportation, as the tanker trucks and ships used to transport liquid fuels are
 represented in the freight transportation sectors, not disaggregated from the remainder of freight transport, and
 therefore not directly driven by changes in liquid fuel demands. This approach has limitations to tracking upstream
 impacts of individual fuels
 
In GCAM-T, freight transportation inputs are modeled as inputs to the domestic consumption sectors of all energy and
 agricultural goods that are shipped by freight transport technologies in GCAM.  Note that the natural gas used to move
 natural gas through pipelines, and the electricity used to move electricity through the transmission and distribution
 network were both already explicitly modeled in GCAM.  But for all other commodities (over 1,400 technologies), there
 is now an input of either freight transportation (road/rail/domestic ship) or international shipping, where the latter
 is used for the goods like crude oil that are assumed to be mostly shipped internationally. 
 
The specific assumptions for each commodity reflect the average transit distance of the stage being modeled. The
 distance coefficients are assigned to each resource (produced or imported) based on the Commodity Flow Survey of the
 United States (U.S. Department of Transportation, 2012), and extended to all regions.
 
For energy commodities, the coefficients also take into account the energy content of the good by using an input-output
 coefficient measured in tonne-kilometers per terajoule. So, even if two energy commodities were assumed to have the
 same travel distance, they would only have the same freight transport input coefficients if their energy contents
 were the same. Note that for oil, GCAM-T includes freight inputs for oil transported regionally by trucks and for
 oil imports transported by international ships. However, there is no aggregated or bottom-up data on pipeline transport
 of oil in the USA, so this is not included in the model. 
 
For agricultural commodities, the coefficient is simply tonne-kilometers per tonne, which simplifies to kilometers,
 and indicates the average distance traveled. Moreover, GCAM-T captures some differences on freight distances across
 different agricultural commodities. For example, biomass liquids feedstocks are assumed to have lower distance
 coefficients than crops used for other purposes, as some studies show that biorefineries are located close to the
 croplands which supply them (Uria-Martinez et al., 2017).
 
In certain regions and historical time periods, coefficients were adjusted downwards to prevent the given technology
 from taking an infeasibly large share of the region's total freight transportation. For the most part all coefficients
 in all regions are based on US-specific data due to lack of data for specific commodities in other regions, but many
 other regions' values are reduced significantly, particularly for the agricultural commodities. Also, all technologies
 are assigned a price unit conversion that serves several purposes. First, the units of freight transport are quite
 different than the units used elsewhere in the model; this factor re-sets the dollar year to the appropriate year and
 sets the correct order of magnitude. Second, some of the commodities are shipped primarily by rail, whereas the price
 of the generic freight input is a weighted average of all modes and is often far higher than the price of rail shipping.
 So, for bulk commodities such as coal and grains that tend to be shipped by rail, the price unit conversion also
 considers that the average freight transport price should not be passed entirely to the technology consuming this input.
 
## Bioenergy Development
### Oilseed Disaggregation
“OilCrop” in GCAM 5.1 is a composite commodity, consisting of 17 of the crop commodities in the FAOSTAT crop production
 databases, which have a range of yields, oil contents, and suitability for biodiesel production. In GCAM-T, “OilCrop”
 is disaggregated into soybean, rapeseed, and other oilcrops, in order to improve the characterization of the biodiesel
 production technologies, and the land requirements thereof. Specifically, OilCrop in GCAM-T is disaggregated into three
 commodity classes: Soybean (FAO item code 236), Rapeseed (FAO item code 270), and OilCrop. Base-year biodiesel production
 by each region is disaggregated into these three feedstocks based on a dataset put together for the AgMIP project,
 described in Lotze-Campenn et al. (2014). The characteristics of the production technologies from crop to vegetable
 oil—both the amount of oil produced from a given amount of harvested crop, and also the amounts of feedcakes produced—are
 based on the crop-specific oilcrop processing mass balances in Fine et al. (2015), using sunflower as a proxy for the
 remaining “OilCrop” commodity class. Thus, in the approach in GCAM, the oilcrop processing for biodiesel production
 includes two outputs: vegetable oil that is used as biodiesel feedstock, and feedcakes used as animal feed. Both of these
 revenue streams are tracked in the model and contribute to reported biodiesel prices.
 
### Ethanol
In order to represent ethanol targets with more structural fidelity, a distinct ethanol sector was disaggregated from the
 refining sector for GCAM-T.  In core GCAM 5.1.2, ethanol technologies are mixed with fossil liquid fuels upstream of the
 transportation sector as a single refined liquids sector. In GCAM-T, ethanol is structured as a separate model sector,
 which makes it easier to model as a distinct product. A separate gasoline pool sector is also created for the GCAM-T model.
 Ethanol from all production technologies goes into the gasoline pool sector along with refined oil, and then the gasoline
 pool product is consumed by vehicles in the transportation sector. With this structure, ethanol can only be consumed by
 passenger and light duty trucks that consume the gasoline pool. This structure also allows an ethanol blend wall constraint
 where a fixed percentage of the gasoline pool, here growing from 10% to 12.55 by volume from 2015 to 2050, is set as a
 ceiling on ethanol consumption. For ethanol consumption in excess of the blend wall, a nominal $1/gallon ethanol is
 added to the cost to reflect further fuel or vehicle processing.
 
### Corn Ethanol and its Coproducts
Modeling of biofuel production technologies in GCAM requires several different assumptions about the cost and efficiency
 of that production. GCAM v5.1’s assumptions in these areas were several years old in some instances, and GCAM-T includes
 updates of many of these assumptions where newer data suggested a different value was appropriate. This includes
 assumptions about the ethanol, distillers grain, and corn oil yield per quantity of corn input to the process, as
 well as assumptions about some of the costs of production. Numerous production process configuration options exist
 for each of these three fuels. However, modeling all or even a handful of configurations for each fuel in a global
 modeling system like GCAM would present significant technical difficulties. For GCAM-T, we made the simplifying assumption
 that all corn ethanol produced in the USA is produced using a representative dry mill technology, with natural gas for
 process energy and dried distillers grains coproduct.  
 
GCAM endogenously models many of the input costs to corn ethanol production, including the price of corn feedstock,
 the price of natural gas, and the price of electricity faced by the representative corn ethanol producer in the refining
 sector of the model. However, the other costs of biofuel refining, including fixed capital costs and all variable
 non-energy, non-feedstock costs, must be set by assumption. In addition, the yield of ethanol, distillers grains,
 and corn oil per unit of corn processed must also be set exogenously. While dry mill corn ethanol is a mature technology,
 based on recent industry trends we anticipate there will be some additional technological learning over time.
 As a result, we assume that production costs and fuel and coproduct yields improve slightly over time. Our enhancements
 began with 2015, the first modeled period in GCAM.  
 
We assume that ethanol yields improve by 0.4 percent per year to reflect technological learning from 2016 through 2050,
 and that there are no further improvements in cost or efficiency after 2050.  As ethanol yields increase, we assume a
 corresponding decrease in coproduct yields to preserve mass balance. The table below describes the exogenous assumptions
 we made for corn ethanol production in GCAM-T. 
 
Table 1 – Exogenous Corn Ethanol Technoeconomic Assumptions in GCAM-T

|     Year    	|     Non-Energy, Non-Feedstock Cost of Refining    	|        DDG Output       	|     Corn Ethanol Yield    	|
|:-----------:	|:-------------------------------------------------:	|:-----------------------:	|:-------------------------:	|
|             	|                     2010$ / GJ                    	|     kg DDG / GJ fuel    	|      kg corn / GJ fuel    	|
|     2015    	|     $7.36                                         	|     33.8                	|     115.2                 	|
|     2020    	|     $7.23                                         	|     33.3                	|     114                   	|
|     2025    	|     $6.98                                         	|     32.9                	|     113.1                 	|
|     2030    	|     $6.94                                         	|     32.1                	|     111.1                 	|
|     2035    	|     $6.89                                         	|     31.3                	|     109                   	|
|     2040    	|     $6.84                                         	|     30.5                	|     107                   	|
|     2045    	|     $6.80                                         	|     29.7                	|     105                   	|
|     2050    	|     $6.75                                         	|     29.1                	|     103.5                 	|
|     2055    	|     $6.75                                         	|     29.1                	|     103.5                 	|

Fixed and variable costs of ethanol production can vary widely, and representative data can be difficult to identify.
 However, one such source is the Center for Agricultural and Rural Development’s (CARD) database of historical ethanol
 operating margins.  CARD estimates that the average cost of capital and other fixed costs for ethanol production is about
 $0.25 per gallon.  We are not aware of any more authoritative estimates, so we have used this estimate as a basis for our
 own assumptions about ethanol fixed costs of production. According to the CARD database, non-energy, non-feedstock variable
 costs of production averaged about $0.34 per wet gallon nationwide in 2015.  We used this figure as our estimate for 2015
 non-energy, non-feedstock variable costs of production (e.g., labor, operations and maintenance) and then assumed that
 technological learning leads to reductions in these other variable costs of 0.25 percent per year, every year from 2016 to
 2050. Costs in 2055 are held constant at their 2050 levels. We then converted these projections into 1975 dollars per gigajoule
 (GJ), the units needed for input into GCAM.
 
Our estimates for fuel and coproduct yield were formed by first determining the ethanol yield per unit of corn input, and then
 determining the output coproducts of distillers grains and corn oil through a mass balance (applying some additional assumptions
 about oil extraction, described below).  We assume that current nationwide average corn ethanol yields is approximately 2.75
 gallons per bushel, or about 115.2 kilograms of corn per gigajoule of ethanol produced. This same data suggest that newer
 dry mill plants may achieve yields more in the range of 2.8 gallons per bushel. In GCAM-T, we assume that the nationwide
 average improves to this latter estimate by 2025. Further growth in ethanol yields between 2025 and 2050 is based on the
 DOE Alternative Fuels Database’s estimate of the theoretical maximum yield for dry mill corn ethanol production. We assume
 that slow but steady technological improvement approaches (but does not ever attain) this maximum theoretical yield in 2050.
 We then linearly interpolate yields between 2025 and 2050 to estimate the trend in technological learning over time. Yields
 in 2055 are held constant at their 2050 levels based on assumption that yields would be maximized by 2050.
 
As ethanol yields improve and more feedstock is converted, the distillers grains yield will decline proportionally. The
 distillers grains yield also decreases as technology to extract corn oil improves and more corn oil is extracted from the
 distillers grains. We therefore assume that the amount of DDG production is the residual after corn ethanol and corn oil
 is produced. We estimate that the average dry mill ethanol plant produced about 17 pounds of full-oil dried distillers grains
 (DDG) per bushel of corn processed in 2015. After corn oil extraction, the ultimate yield of DDG feed product is reduced by
 about 3 percent, to approximately 16.5 pounds per bushel, which translates to about 33.8 kg per GJ of ethanol produced. We
 assume that as yields for corn ethanol improve over time, that this yield falls to approximately 29.1 kg/GJ. In the livestock
 feed sector in GCAM, we assume that each kg of DDG displaces 1 kg of other feed.
 
GCAM-T also includes modified assumptions associated with corn oil biodiesel production. Because we are making the simplifying
 assumption that all corn ethanol produced in the USA comes from a dry mill process, we must also make the simplifying
 assumption that all of the corn oil produced is non-food grade (since corn oil produced from dry mill processes is generally
 not refined to food grade). The share of distillers corn oil used for biodiesel has been increasing in recent years, and now
 the majority of all distillers corn oil produced at domestic ethanol facilities is subsequently used to produce biodiesel.
 GCAM-T makes a simplifying assumption that the corn oil produced by USA ethanol feeds directly into corn oil biodiesel
 production.  Production of corn oil biodiesel in GCAM-T is therefore a function of corn ethanol production and the assumed
 rate of corn oil extraction from the distillers grains coproduct. 
 
We did not identify an authoritative estimate of the historical average yield of extracted corn oil per unit of corn
 processed. Estimates from Wang et al. 2015 suggest that it is probably approximately 0.55 pounds per bushel of corn
 processed.  We use this estimate as our assumption for the 2015 modeled period in GCAM-T.  Assuming that approximately
 115.2 kg of corn is required to generate one GJ of corn ethanol, this assumption translates to about 1.13 kg of corn oil
 per GJ of fuel produced.  Other data suggests that some producers outperform this average and in some cases achieve yields
 above 0.6 lbs/bushel.   Therefore, while corn oil extraction is a very mature technology, we assume there is some improvement
 in the nationwide average as older plants either improve their rates of extraction or are replaced by newer technology, and
 that corn oil yields gradually improve to 1.2 kg oil per GJ of fuel by 2040, or about 0.65 lbs/bushel. Corn oil yields per
 GJ of ethanol are non-linear and decrease after 2035 due to simultaneous increases in ethanol yield per bushel.
 
 Table 2 – Exogenous Corn Oil Assumptions in GCAM-T 
 
|     Year    	|     Corn Oil Yield      	|     Corn Oil Biodiesel Yield    	|     Natural Gas Input for Biodiesel Refining    	|     Electricity Input for Biodiesel Refining    	|
|-------------	|-------------------------	|---------------------------------	|-------------------------------------------------	|-------------------------------------------------	|
|             	|     kg oil / GJ fuel    	|     GJ oil / GJ fuel            	|     GJ input / GJ   fuel                        	|     GJ input / GJ   fuel                        	|
|     2015    	|     1.13                	|     1.06                        	|     0.058                                       	|     0.008                                       	|
|     2020    	|     1.17                	|     1.05                        	|     0.058                                       	|     0.008                                       	|
|     2025    	|     1.21                	|     1.03                        	|     0.058                                       	|     0.008                                       	|
|     2030    	|     1.21                	|     1.03                        	|     0.058                                       	|     0.008                                       	|
|     2035    	|     1.21                	|     1.02                        	|     0.058                                       	|     0.008                                       	|
|     2040    	|     1.20                	|     1.02                        	|     0.058                                       	|     0.008                                       	|
|     2045    	|     1.20                	|     1.01                        	|     0.058                                       	|     0.008                                       	|
|     2050    	|     1.20                	|     1.01                        	|     0.058                                       	|     0.008                                       	|
|     2055    	|     1.20                	|     1.01                        	|     0.058                                       	|     0.008                                       	|
 
Non-food grade corn oil is higher in free-fatty acids than soybean oil and requires pre-treatment to remove these free fatty
 acids. For this reason, when the same processing techniques and equipment are used for each, the biodiesel yield from corn
 oil will be lower than from soybean oil. We assume a biodiesel yield of 7.9 lbs per gallon, or about 1.06 GJ of corn oil per
 GJ of fuel in the 2015 modeled period of GCAM-T.  As we do for soybean oil biodiesel (discussed in the next section below),
 we assume that there is some small rate of technological learning for corn oil biodiesel production between 2015 and 2050,
 even though this is a fairly mature technology. Specifically, we assume that corn oil biodiesel yields improve to 1.01 GJ oil
 per GJ fuel by 2050.  Assumptions for modeled GCAM-T periods between 2015 and 2050 were derived from linear interpolation
 between these two assumptions (see above).  Assumptions in 2055 are held constant at their 2050 levels. For energy use, we
 assume the same inputs per unit of fuel produced as for soybean oil biodiesel.
 
### Soybean Oil Biodiesel and its Coproducts
We have made enhancements to several of the soybean biodiesel processing assumptions for the purposes of our analysis. These
 included assumptions about the yield of oil and meal produced per unit of soybeans crushed, the yield of biodiesel per unit
 of oil input to the process, and assumptions about some of the costs of crushing and biodiesel production.
 
In GCAM-T, we made the simplifying assumption that all soybean oil biodiesel produced in the USA is produced using a
 representative technology, with only natural gas and electricity used for energy inputs.  With regards to process energy,
 there exist a wide array of biodiesel plant configurations that differ from the one we have modeled. Some plants utilize
 coal, biogas, or other sources of process energy that may reduce inputs of natural gas. The glycerin co-product from biodiesel
 production is not currently represented in GCAM-T. This is in part due to the fact that we have not identified reliable data
 on glycerin co-product trade and market prices, and in part because the volume produced is small enough that shifts in
 quantities probably cannot be modeled precisely in GCAM.
 
Oilseed crushing is a mature technology and the ratios of meal and oil produced from it are well-understood. In GCAM v5.1,
 consumption of vegetable oil and meal are modeled as oil crop equivalents. There is no explicit crushing sector in GCAM-core,
 nor are there explicit assumptions about the energy needed to separate oil from meal. GCAM-T includes these capabilities.
 The energy required to crush soybeans to make oil for biofuel feedstock use is explicitly tracked. We assume that 19 percent
 of the product output of this crushing process goes to biodiesel feedstock, representing the oil output, and we assume that
 80 percent of the output goes to the feed markets. 
 
In GCAM, biofuel feedstocks are tracked within the biofuel sector in energy terms. We assume that one gigajoule (GJ) of soybean
 oil weighs 26.99 kg, based on established fixed factors from the GREET model.  We also use GREET factors for crushing energy
 requirements, assuming that each GJ of oil produced requires 0.123 GJ of natural gas and 0.024 GJ of electricity. For biofuel
 production process energy needs, we assume consumption of 0.058 GJ of natural gas and 0.008 GJ of electricity per GJ of
 biodiesel produced.
 
GCAM endogenously models many of the input costs to oil crop biodiesel production, including the price of feedstock, the
 price of natural gas, and the price of electricity faced by the representative biodiesel producer in the refining sector
 of the model. However, the other costs of biofuel refining, including fixed capital costs and all variable non-energy,
 non-feedstock costs, must be set by assumption. In addition, the yield of biodiesel per unit of feedstock processed must
 also be set by assumption. While vegetable oil biodiesel production is a relatively mature technology, we do anticipate
 that there will be some amount of additional technological learning over time for some of the factors that determine biodiesel
 production cost and efficiency. For several of these assumptions, specifically the natural gas and electricity inputs to
 oilseed crushing and biodiesel refining, and the quantity of soybean meal produced per unit of soybeans crushed, we found no
 evidence that these factors are likely to improve over time. However, there is evidence that production costs and biodiesel
 yield continue to improve over time. Our enhancements began with 2015, the first modeled period in GCAM-T. We describe these
 and other yield and cost assumptions further below. The table below describes the exogenous assumptions we made for soybean
 oil production in GCAM-T. Note that in the livestock feed sector, we assume that each kg of meal displaces a kg of generic feed.
 
Table 3 – Exogenous Soybean Oil Biodiesel Technoeconomic Assumptions in GCAM-T 

|     Year    	|     Non-Energy, Non-Feedstock Cost of Refining    	|     Oil Crop Input per Unit of Soybean Oil    	|     Soybean Oil Input per Unit of Biodiesel    	|     Natural Gas Input for Crushing    	|     Electricity Input for Crushing    	|     Natural Gas Input for Refining    	|     Electricity Input for Refining    	|     Soybean Meal Output       	|
|-------------	|---------------------------------------------------	|-----------------------------------------------	|------------------------------------------------	|---------------------------------------	|---------------------------------------	|---------------------------------------	|---------------------------------------	|-------------------------------	|
|             	|     2010$ / GJ                                    	|     kg oilseed / GJ   oil                     	|     GJ oil /       GJ fuel                     	|     GJ input / GJ oil                 	|     GJ input / GJ oil                 	|     GJ input / GJ   fuel              	|     GJ input / GJ   fuel              	|     kg meal / kg   oilseed    	|
|     2015    	|     $5.22                                         	|     142.05                                    	|     1.04                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2020    	|     $4.98                                         	|     142.05                                    	|     1.03                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2025    	|     $4.82                                         	|     142.05                                    	|     1.01                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2030    	|     $4.81                                         	|     142.05                                    	|     1.01                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2035    	|     $4.80                                         	|     142.05                                    	|     1.00                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2040    	|     $4.79                                         	|     142.05                                    	|     1.00                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2045    	|     $4.78                                         	|     142.05                                    	|     0.99                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2050    	|     $4.77                                         	|     142.05                                    	|     0.99                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|
|     2055    	|     $4.77                                         	|     142.05                                    	|     0.99                                       	|     0.123                             	|     0.024                             	|     0.058                             	|     0.008                             	|     113.64                    	|

CARD estimates that the average cost of capital and other fixed costs for soybean oil biodiesel production is about $0.12 per
 wet gallon. According to the CARD database, non-energy, non-feedstock variable costs of production (including the costs of
 methanol inputs) averaged about $0.53 per wet gallon nationwide in 2015. We used this figure as our estimate for 2015
 non-energy, non-feedstock variable costs of production (e.g., labor, operations and maintenance) and then assumed that
 technological learning leads to reductions in these other variable costs. For 2020, we estimated declines in costs based
 on trends evident in petition and registration information since 2010. For 2020, we assume that most new facilities adopt
 facility design innovations present in recent petitions and registrations, leading to further declines in average cost. We
 assume that declines after 2020 are much more modest, 0.25 percent per year, every year from 2025 to 2050. At this rate of
 improvement, plants that are state of the art today will represent the industry average by 2050. Costs in 2055 are held
 constant at their 2050 levels. We then converted these projections into 1975 dollars per gigajoule, the units needed for
 input into GCAM.
 
We assume that 2015 nationwide average soybean oil biodiesel yield is approximately 7.7 lbs of oil per wet gallon of biodiesel,
 or about 1.04 GJ of oil per GJ of biodiesel produced.  Most newer plants already exceed this level of performance however.
 We assume that the nationwide industry average yield improves to 7.6 lbs per gallon by 2020 and to 7.5 lbs per gallon by 2025,
 as newer technology becomes more widespread. A report prepared for the USA Soybean Board suggests that a very efficient plant
 may achieve a yield more in the range of 7.33 lbs per gallon, or about 0.99 GJ oil per GJ biodiesel. For the purposes of this
 analysis, we assume that by 2050, this state of the art performance becomes the nationwide industry average. We then linearly
 interpolate yields between 2025 and 2050 to estimate the trend in technological learning over time. Yields in 2055 are held
 constant at their 2050 levels.
 
### Other Bioenergy and Synfuel Assumptions
Given their uncertain future production and use, the trajectories of energy grasses and woody bioenergy crops are greatly
 reduced in GCAM-T in order to minimize potential compensating land use and energy system interactions with the biofuels and
 scenarios of focus. Specifically, we turned off production of energy grass and woody biomass crops in the U.S. for all
 future years, and we turned off production globally of biochemical and thermochemical biofuel production from all
 lignocellulosic feedstock. Outside the U.S., bioenergy crop yields are not altered from GCAM 5.1, but the demand is much
 reduced because they are not available for biofuel production. The modeling of biomass from agriculture and forestry residues
 and organic municipal solid wastes are not altered from GCAM 5.1, and they are necessary for historical model calibration
 as they are in use. Biomass can still be used in GCAM-T for energy in the industrial and buildings sectors as well as for
 electric power, and the quantities will vary slightly by scenario. 
 
Additionally, the fuel technologies of coal to liquids, and gas to liquids that exist in GCAM 5.1 are turned off globally. 

## Modified Baseline US Coal Electric Power
We modified the parameterization of the future path of electric power production from coal in the US to be more consistent
 with results from the Integrated Planning Model (IPM) baseline from June 2018, which resulted in a decrease in production
 compared to the GCAM 5.1 reference results. This coal electric path was not set as a fixed constraint but instead as a soft
 calibration to levels that would still vary from these reference values in other scenarios, although not by much as the
 scenarios studies here do not strongly directly impact the electric fuel mix. In GCAM-T, we modified the path through the
 parameters that set the retirement profile of capacity in place in 2015 over future years. In addition, we decreased the
 share weights on new investment to very low values. Figure 1 below shows the GCAM-T Baseline scenario US coal electric
 production.
 
 Figure 1 – GCAM-T Baseline US Coal Electricity Production
 
![Figure 1](figures/GCAM-T_2020.0_figure_1.png)

## Updated Crop Yields for 2015
Because GCAM 5.1 is calibrated to a base year of 2010, the year 2015 is a future period where crop yields are based on
 assumptions of technological change. In GCAM-T, we update 2015 crop yields to match 2015 historical values based on FAO
 data. Assumed yield growth rates then resume in 2020 as in GCAM 5.1, but future year realized yields will also be different
 here because of the updates to 2015 yields. This change was implemented in order to better match the available yield
 information for the year 2015; as an example of the impact, year 2015 yields of corn and soybeans in the USA are 12% and
 13% higher, respectively, in GCAM-T than in GCAM 5.1.
 
## Transportation Sector Updates
For vehicle transportation, battery electric vehicle (BEV) technologies were added to the potential options for freight
 trucks. Costs and efficiencies for light duty passenger vehicles were also updated. Specifically, the efficiencies of
 the liquid fueled vehicle technologies (“Liquids” and “Hybrid Liquids”) were increased in order to be able to meet projected
 fuel economy targets from the 2017 Annual Energy Outlook to 2050 (see Table 4 for the target values). Capital costs
 (i.e., purchase prices) of LDVs were adjusted upwards for consistency with the assumed fuel economy improvements; these
 adjustments scaled with the vehicle sizes. Compact car costs were increased by 4% in 2050 as compared with the GCAM 5.1
 core assumptions, and the Light Truck and SUV class had its costs increase by 17%. These adjustments were based on the
 cost/efficiency trade-offs from vehicle projection data provided by the NEMS (US Energy Information Administration’s National
 Energy Modeling System) modeling team in 2016, for representative “reference” and “advanced technology” scenarios.
 Fuel economy for LDVs and freight trucks reflect Phase II light duty and heavy duty GHG rules. For LDVs, these rules
 were modeled as targets for which the model would economically choose among technology options, including BEVs and HEVs
 in addition to internal combustion engines, in order to meet the targets in each year for each class of vehicle represented
 in GCAM. Table 4 below shows the targets, which are consistent with the EIA’s Annual Energy Outlook 2016 values for 2015.
 Subsequent time steps follow the pattern laid out in the LDVR for Phase 2: vehicle fuel economy minimum requirements decrease
 by 3.5%/yr from 2017 to 2021, and by 5%/yr from 2022 to 2025, remaining constant thereafter.

Table 4 – New Light Duty Vehicle Fuel Economy Targets (gasoline equivalent mpg)

|     GCAM Vehicle         	|     2015    	|     2020    	|     2025    	|     2030    	|     2035    	|     2040    	|     2045    	|     2050    	|
|--------------------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|
|     Compact Car          	|     30      	|     37      	|     45      	|     45      	|     45      	|     45      	|     45      	|     45      	|
|     Midsize Car          	|     30      	|     37      	|     46      	|     46      	|     46      	|     46      	|     46      	|     46      	|
|     Large Car            	|     27      	|     34      	|     44      	|     44      	|     44      	|     44      	|     44      	|     44      	|
|     Light Truck & SUV    	|     22      	|     25      	|     32      	|     32      	|     32      	|     32      	|     32      	|     32      	|

Table 5 shows the energy fuel economy assumptions for medium and heavy-duty vehicles. Unlike the LDVS which are set as targets
 for the model to solve, these are more simply set by definition as meeting the Phase II rules.
 
Table 5 – New Medium and Heavy-Duty Vehicle Fuel Economy Assumptions (gasoline equivalent mpg)

|     EPA/EIA Description                   	|     GCAM Vehicle            	|     2010    	|     2015    	|     2020    	|     2025    	|     2030    	|     2035    	|     2040    	|     2045    	|     2050    	|
|-------------------------------------------	|-----------------------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|-------------	|
|     Light Trucks      (Class 1-2A)        	|     Truck     (0-2.7t)      	|     19      	|     20      	|     23      	|     26      	|     29      	|     31      	|     32      	|     32      	|     32      	|
|     Commercial Light Trucks (Class 2B)    	|     Truck     (2.7-4.5t)    	|     18      	|     19      	|     22      	|     25      	|     25      	|     25      	|     25      	|     25      	|     25      	|
|     Medium     (Class 3-6)                	|     Truck     (4.5-12t)     	|     10      	|     11      	|     12      	|     13      	|     13      	|     13      	|     13      	|     13      	|     13      	|
|     Heavy     (Class 7-8)                 	|     Truck     (>12t)        	|     6       	|     7       	|     8       	|     9       	|     9       	|     9       	|     9       	|     9       	|     9       	|
|     Bus                                   	|     Bus                     	|     7       	|     7       	|     8       	|     9       	|     9       	|     9       	|     9       	|     9       	|     9       	|

For the new BEV trucks that are added to GCAM-T, Table 6 and Table 7 show the efficiency and cost ratios relative to the internal
 combustion engine (ICE) vehicles in the model.
 
Table 6 – Vehicle Efficiency Ratios Relative to Internal Combustion Engines (ICE)

|            	|     Freight   Trucks    	|
|------------	|-------------------------	|
|     ICE    	|     100%                	|
|     BEV    	|     300%                	|

Table 7 – Vehicle Cost Ratios Relative to Internal Combustion Engines (ICE)

|             	|     All Class   2B-6 Trucks    	|             	|     All Class   7&8 Trucks    	|             	|
|-------------	|--------------------------------	|-------------	|-------------------------------	|-------------	|
|             	|     ICE                        	|     BEV     	|     ICE                       	|     BEV     	|
|     2020    	|     100%                       	|     180%    	|     100%                      	|     193%    	|
|     2025    	|     100%                       	|     161%    	|     100%                      	|     173%    	|
|     2030    	|     100%                       	|     142%    	|     100%                      	|     152%    	|
|     2035    	|     100%                       	|     132%    	|     100%                      	|     141%    	|
|     2040    	|     100%                       	|     128%    	|     100%                      	|     136%    	|
|     2045    	|     100%                       	|     125%    	|     100%                      	|     134%    	|
|     2050    	|     100%                       	|     123%    	|     100%                      	|     131%    	|

## Suitable Land for Agriculture
In the GCAM v5.1 land database, land is divided into arable and non-arable land. Arable land is then divided into pasture
 and non-pasture. This nest is further broken down into commercial and non-commercial lands. Commercial land areas in GCAM
 are calculated based on historical data of animal production, and timber and crop harvested, in each water basin.
 Non-commercial land includes grassland, shrubland, fallow land (labeled other arable land in GCAM data), forest,
 and pasture. Not all non-commercial land may be suitable for agricultural purposes. In GCAM v5.1, each water basin is
 assumed to have 10 percent of its total non-commercial land available for conversion to agriculture.
 
We analyzed existing literature and datasets to identify improvements to estimates of existing non-commercial land that
 could readily be converted to agriculture. We identified two studies that generated a global potential agricultural map:
 Zabel, Putzenlechner et al. (2014) and the follow-up study Delzeit, Zabel et al. (2017). These studies created global
 maps of potential agricultural land suitability based on natural constraints evaluating the following data: climate data
 from ECHAM5, soil quality parameters from the Harmonized World Soil Database, topography (i.e. slope, elevation, aspect)
 from the Shuttle Radar Topography Mission (SRTM), crop-requirements from FAO Land Evaluation Part III Crop Requirements,
 and irrigation data from the Global Map of Irrigation Areas (v 5.0).
 
We made minor improvements upon the Delzeit, Zabel et al. (2017) dataset when determining the amount of non-commercial
 land that could be converted to agriculture without the use of additional irrigation and other non-geophysical improvements.
 First, we refined areas where major waterbodies (e.g., lakes, rivers) or developed urban areas remained in the dataset using
 the European Space Agency’s Climate Change Initiative Land cover product (2015). Second, we included current cropland areas
 as identified by the latest data products from European Space Agency  and the Global Food Security Analysis and Support
 Database.  By including these existing cropland data layers in our suitability dataset, we ensured that regions proven to
 be recently capable of agricultural production were included as suitable land. Conversely, we accounted for regions of
 designated protected areas as defined by individual countries and tracked by the International Union for Conservation of
 Nature’s (IUCN) World Database of Protected Areas. Specifically, IUCN categories Ia, Ib, and II were accounted for as areas
 designated to have permanent protection from land conversion, and where non-natural disturbance events are minimized,
 and other use practices are disallowed.  These protected areas were made unavailable to be converted for agricultural
 purposes in the model. However, some of these protected areas around the globe have already seen some forest loss as
 identified in the work of Hansen, Potapov et al. (2013). We allowed deforested land already identified within these
 protected areas to potentially be used for agricultural purposes in GCAM.
 
The result of the above analysis was a refined global geospatial raster with resolution of 300m estimating total land
 available for agricultural uses considering natural constraints such as climate, slope, soil quality, and existing
 cropland based upon the most recently available datasets showing agricultural viability. The resulting dataset represents
 the areas suitable for agricultural crop production based on area-specific physical conditions such as climate, terrain,
 and soil properties. This spatial dataset was then used to calculate the area of land unavailable for crop production for
 each land type in each GCAM water basin. These estimates are used to revise the protected land assumptions in GCAM-T.
 The following table summarizes the resulting fractions of non-commercial land protected in GCAM-T.
 
Table 8 – Fraction of non-commercial land protected in 2010 as a result of land suitability assessment (protected fraction
 = protected area / protected area + unprotected non-commercial area). The column labeled “Total” shows the fraction
 of non-commercial land protected in each region. The row labeled “Total” shows the overall fraction of land protected
 in each category, globally. In total, 36% of all non-commercial land is protected.
 
 |     Region     	|     Non-Commercial   Pasture    	|     Non-Commercial   Forest    	|     Shrubland    	|     Grassland    	|     Total    	|
|----------------	|---------------------------------	|--------------------------------	|------------------	|------------------	|--------------	|
|     USA        	|     21%                         	|     27%                        	|     58%          	|     40%          	|     32%      	|
|     Non-USA    	|     37%                         	|     30%                        	|     50%          	|     35%          	|     36%      	|
|     Total      	|     36%                         	|     30%                        	|     51%          	|     35%          	|     36%      	|


## Biofuel Volume Assumptions
In GCAM-T, we set explicit targets for corn ethanol and biodiesel in the US. These constraints are set in the model as targets
 that must be matched exactly in each year. 

Table 9 – Biofuel Volumes (in Billion Gallons per Year)

|             	|      Corn Ethanol                   	|      Soybean Biodiesel               	|      Corn Oil Biodiesel              	|      All Fuels                      	|
|-------------	|-------------------------------------	|--------------------------------------	|--------------------------------------	|-------------------------------------	|
|     2015    	|                           14.00     	|                             0.56     	|                             0.35     	|                           14.91     	|
|     2020    	|                           14.00     	|                             0.56     	|                             0.37     	|                           14.93     	|
|     2025    	|                           14.00     	|                             0.56     	|                             0.39     	|                           14.95     	|
|     2030    	|                           14.00     	|                             0.56     	|                             0.39     	|                           14.95     	|
|     2035    	|                           14.00     	|                             0.56     	|                             0.39     	|                           14.95     	|
|     2040    	|                           14.00     	|                             0.56     	|                             0.39     	|                           14.95     	|
|     2045    	|                           14.00     	|                             0.56     	|                             0.39     	|                           14.95     	|
|     2050    	|                           14.00     	|                             0.56     	|                             0.40     	|                           14.96     	|
|     2055    	|                           14.00     	|                             0.56     	|                             0.40     	|                           14.96     	|
|     2060    	|                           14.00     	|                             0.56     	|                             0.40     	|                           14.96     	|

## Model Methodology for Imposing Fuel Volume Targets
GCAM’s model solution operates by solving for prices that equilibrate supplies and demands in all markets. This approach differs
 in application from models that operate by optimizing a condition under fixed constraints. In GCAM a biofuel volume target is
 implemented as a market with a fixed volume floor, and the model solves for the amount of implied subsidy price required to
 lower the cost to bring the demand for the biofuel up to the target level. In GCAM 5.1 this subsidy on the biofuel is then
 passed downstream to lower the price paid by the final consumers of the fuel. In many applications, that is the desired effect.
 In GCAM-T, however, this was changed so that the subsidy is not passed downstream. Instead, the direct cost of the fuel and
 technologies are passed to final consumers.  In the case of a target that increases the amount of higher cost ethanol, this
 means a higher price for fuel paid by final consumers.
 
## References
Adler, P.R., Grosso, S.J.D., Parton, W.J., 2007. Life‐cycle assessment of net greenhouse‐gas flux for bioenergy cropping systems.
 Ecol. Appl. 17, 675–691.
 
Calvin, K., P. Patel, L. Clarke, G. Asrar, B. Bond-Lamberty, R. Y. Cui, A. Di Vittorio, K. Dorheim, J. Edmonds, C. Hartin, M. Hejazi, R. Horowitz, G. Iyer, P. Kyle, S. Kim, R. Link, H. McJeon, S. J. Smith, A. Snyder, S. Waldhoff and M. Wise (2019).
 "GCAM v5.1: representing the linkages between energy, water, land, climate, and economic systems." Geosci. Model Dev.
 12(2): 677-698.
 
Delzeit, R., F. Zabel, C. Meyer and T. Václavík (2017). "Addressing future trade-offs between biodiversity and cropland
 expansion to improve food security." Regional Environmental Change 17(5): 1429-1441.
 
Fine, Frédéric, Jean-Louis Lucas, Jean-Michel Chardigny, Barbara Redlingshöfer, and Michel Renard (2015). “Food losses and
 waste in the French oilcrops sector.”Oilseeds and Fats Crops and Lipids OCL 2015, 22(3) A302.
 
Hansen, M. C., P. V. Potapov, R. Moore, M. Hancher, S. A. Turubanova, A. Tyukavina, D. Thau, S. V. Stehman, S. J. Goetz, T. R.
 Loveland, A. Kommareddy, A. Egorov, L. Chini, C. O. Justice and J. R. G. Townshend (2013). "High-Resolution Global Maps of
 21st-Century Forest Cover Change." Science 342(6160): 850-853.
 
IEA (2011). Energy Balances of OECD Countries 1960-2010 and Energy Balances of Non-OECD Countries 1971-2010. I. E. Agency.
 Paris, France.
 
Langholtz, M., B. Stokes and L. Eaton (2016). 2016 Billion-Ton Report: Advancing Domestic Resources for a Thriving Bioeconomy,
 EERE Publication and Product Library.
 
Lotze-Campen, H., M. von Lampe, P. Kyle, S. Fujimori, P. Havlík, H. v. Meijl, T. Hasegawa, A. Popp, C. Schmitz, A. Tabeau, H. Valin, D. Willenbockel, M. Wise. 2013. Impacts of increased bioenergy demand on global food markets: an AgMIP economic
 model intercomparison. Agricultural Economics 45: 103-116.
 
Uria-Martinez, R., Leiby, P.N., Brown, M.L., 2017. BioTrans Model Documentation.

U.S. Department of Transportation, 2012. Commodity Flow Survey United States. U.S. Department of Commerce Economics and
 Statistics Administration.
 
USDOE (2007). Mining industry energy bandwidth study. Washington, D.C., U.S. Department of Energy.

Zabel, F., B. Putzenlechner and W. Mauser (2014). "Global Agricultural Land Resources – A High Resolution Suitability
 Evaluation and Its Perspectives until 2100 under Climate Change Conditions." PLOS ONE 9(9): e107522.
 


