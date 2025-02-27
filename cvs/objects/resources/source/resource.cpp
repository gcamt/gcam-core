/*
* LEGAL NOTICE
* This computer software was prepared by Battelle Memorial Institute,
* hereinafter the Contractor, under Contract No. DE-AC05-76RL0 1830
* with the Department of Energy (DOE). NEITHER THE GOVERNMENT NOR THE
* CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY
* LIABILITY FOR THE USE OF THIS SOFTWARE. This notice including this
* sentence must appear on any copies of this computer software.
* 
* EXPORT CONTROL
* User agrees that the Software will not be shipped, transferred or
* exported into any country or used in any manner prohibited by the
* United States Export Administration Act or any other applicable
* export laws, restrictions or regulations (collectively the "Export Laws").
* Export of the Software may require some form of license or other
* authority from the U.S. Government, and failure to obtain such
* export control license may result in criminal liability under
* U.S. laws. In addition, if the Software is identified as export controlled
* items under the Export Laws, User represents and warrants that User
* is not a citizen, or otherwise located within, an embargoed nation
* (including without limitation Iran, Syria, Sudan, Cuba, and North Korea)
*     and that User is not otherwise prohibited
* under the Export Laws from receiving the Software.
* 
* Copyright 2011 Battelle Memorial Institute.  All Rights Reserved.
* Distributed as open-source under the terms of the Educational Community 
* License version 2.0 (ECL 2.0). http://www.opensource.org/licenses/ecl2.php
* 
* For further details, see: http://www.globalchange.umd.edu/models/gcam/
*
*/


/*! 
* \file resource.cpp
* \ingroup Objects
* \brief Resource class source file.
* \author Sonny Kim
*/

#include "util/base/include/definitions.h"

#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include <cassert>
#include <xercesc/dom/DOMNode.hpp>
#include <xercesc/dom/DOMNodeList.hpp>
#include <xercesc/dom/DOMNamedNodeMap.hpp>

// class headers
#include "util/base/include/xml_helper.h"
#include "resources/include/resource.h"
#include "resources/include/subresource.h"
#include "containers/include/scenario.h"
#include "util/base/include/model_time.h"
#include "marketplace/include/marketplace.h"
#include "marketplace/include/imarket_type.h"
#include "resources/include/renewable_subresource.h"
#include "resources/include/smooth_renewable_subresource.h"
#include "util/base/include/ivisitor.h"
#include "containers/include/info_factory.h"
#include "containers/include/iinfo.h"
#include "emissions/include/ghg_factory.h"
#include "emissions/include/co2_emissions.h"
#include "technologies/include/ioutput.h"
#include "technologies/include/primary_output.h"
#include "technologies/include/generic_output.h"
#include "functions/include/iinput.h"
#include "sectors/include/sector_utils.h"

#include "util/base/include/initialize_tech_vector_helper.hpp"


using namespace std;
using namespace xercesc;

extern Scenario* scenario;

typedef vector<AGHG*>::const_iterator CGHGIterator;

//! Default constructor.
Resource::Resource():
mObjectMetaInfo(),
mResourcePrice( Value( 0.0 ) ),
mAvailable( Value( 0.0 ) ),
mAnnualProd( Value( 0.0 ) ),
mCumulProd( Value( 0.0 ) ),
mHack(false)
{
}

//! Destructor.
Resource::~Resource() {
    for ( vector<SubResource*>::iterator iter = mSubResource.begin(); iter != mSubResource.end(); iter++ ) {
        delete *iter;
    }
    for( CGHGIterator iter = mGHG.begin(); iter != mGHG.end(); ++iter ) {
        delete *iter;
    }
    for( vector<IOutput*>::const_iterator iter = mOutputs.begin(); iter != mOutputs.end(); ++iter ) {
        delete *iter;
    }
}

/*! \brief Get the XML node name for output to XML.
 *
 * This public function accesses the private constant string, XML_NAME.
 * This way the tag is always consistent for both read-in and output and can be easily changed.
 * This function may be virtual to be overridden by derived class pointers.
 * \author Josh Lurz, James Blackwood
 * \return The constant XML_NAME.
 */
const std::string& Resource::getXMLName() const {
    return getXMLNameStatic();
}

/*! \brief Get the XML node name in static form for comparison when parsing XML.
 *
 * This public function accesses the private constant string, XML_NAME.
 * This way the tag is always consistent for both read-in and output and can be easily changed.
 * The "==" operator that is used when parsing, required this second function to return static.
 * \note A function cannot be static and virtual.
 * \author Josh Lurz, James Blackwood
 * \return The constant XML_NAME as a static.
 */
const std::string& Resource::getXMLNameStatic() {
    const static string XML_NAME = "resource";
    return XML_NAME;
}

//! Set data members from XML input.
void Resource::XMLParse( const DOMNode* node ){
    const Modeltime* modeltime = scenario->getModeltime();
    string nodeName;
    DOMNodeList* nodeList = 0;
    DOMNode* curr = 0;

    // make sure we were passed a valid node.
    assert( node );

    // get the name attribute.
    mName = XMLHelper<string>::getAttr( node, "name" );

    // get all child nodes.
    nodeList = node->getChildNodes();

    // loop through the child nodes.
    for( int i = 0; i < static_cast<int>( nodeList->getLength() ); i++ ){
        curr = nodeList->item( i );
        nodeName = XMLHelper<string>::safeTranscode( curr->getNodeName() );

        if( nodeName == "#text" ) {
            continue;
        }
        else if( nodeName == "output-unit" ){
            mOutputUnit = XMLHelper<string>::getValue( curr );
        }
        else if( nodeName == "price-unit" ){
            mPriceUnit = XMLHelper<string>::getValue( curr );
        }
        else if( nodeName == "market" ){
            mMarket = XMLHelper<string>::getValue( curr ); // only one market element.
        }
        else if( nodeName == "price" ){
            XMLHelper<Value>::insertValueIntoVector( curr, mResourcePrice, modeltime );
        }
        else if( nodeName == "keyword" ){
            DOMNamedNodeMap* keywordAttributes = curr->getAttributes();
            for( unsigned int attrNum = 0; attrNum < keywordAttributes->getLength(); ++attrNum ) {
                DOMNode* attrTemp = keywordAttributes->item( attrNum );
                mKeywordMap[ XMLHelper<string>::safeTranscode( attrTemp->getNodeName() ) ] = 
                    XMLHelper<string>::safeTranscode( attrTemp->getNodeValue() );
            }
        }
        else if ( nodeName == object_meta_info_type::getXMLNameStatic() ){
            object_meta_info_type metaInfo;
            if ( metaInfo.XMLParse( curr ) ){
                // Add to collection
                mObjectMetaInfo.push_back( metaInfo );
            }
        }
        else if( GHGFactory::isGHGNode( nodeName ) ) {
            parseContainerNode( curr, mGHG, GHGFactory::create( nodeName ).release() );
        }
        else if( nodeName == SubDepletableResource::getXMLNameStatic() ){
            parseContainerNode( curr, mSubResource, new SubDepletableResource() );
        }
        else if( nodeName == SubRenewableResource::getXMLNameStatic() ) {
            parseContainerNode( curr, mSubResource, new SubRenewableResource() );
        }
        else if( nodeName == "hack" ) {
            mHack = XMLHelper<bool>::getValue( curr );
        }
        else if( XMLDerivedClassParse( nodeName, curr ) ){
            // no-op
        }
        else {
            ILogger& mainLog = ILogger::getLogger( "main_log" );
            mainLog.setLevel( ILogger::WARNING );
            mainLog << "Unrecognized text string: " << nodeName << " found while parsing Resource." << endl;
        }
    }
}

//! Write data members to data stream in XML format for debugging.
void Resource::toDebugXML( const int period, ostream& aOut, Tabs* aTabs ) const {

    XMLWriteOpeningTag( getXMLName(), aOut, aTabs, mName );

    // Write the xml for the class members.
    XMLWriteElement( mOutputUnit, "output-unit", aOut, aTabs );
    XMLWriteElement( mPriceUnit, "price-unit", aOut, aTabs );
    // Write out the market string.
    XMLWriteElement( mMarket, "market", aOut, aTabs );

    if ( mObjectMetaInfo.size() ) {
        for ( object_meta_info_vector_type::const_iterator metaInfoIterItem = mObjectMetaInfo.begin();
            metaInfoIterItem != mObjectMetaInfo.end(); 
            ++metaInfoIterItem ) {
                metaInfoIterItem->toDebugXML( period, aOut, aTabs );
            }
    }

    // Write out resource prices for debugging period.
    XMLWriteElement( mResourcePrice[ period ], "rscprc", aOut, aTabs );

    // Write out available resources for debugging period.
    XMLWriteElement( mAvailable[ period ], "available", aOut, aTabs );

    // Write out annualprod for debugging period.
    XMLWriteElement( mAnnualProd[ period ], "annualprod", aOut, aTabs );

    // Write out cumulative prod for debugging period.
    XMLWriteElement( mCumulProd[ period ], "cummprod", aOut, aTabs );

    // Write out the subresource objects.
    for( vector<SubResource*>::const_iterator i = mSubResource.begin(); i != mSubResource.end(); i++ ){
        ( *i )->toDebugXML( period, aOut, aTabs );
    }
    // Write out ghg object, vector is of number of gases
    for( CGHGIterator i = mGHG.begin(); i != mGHG.end(); i++ ) {
        ( *i )->toDebugXML( period, aOut, aTabs );
    }

    // finished writing xml for the class members.
    XMLWriteClosingTag( getXMLName(), aOut, aTabs );
}

bool Resource::XMLDerivedClassParse( const string& aNodeName, const DOMNode* aNode ) {
    // do nothing
    return false;
}

/*! \brief Complete the initialization
*
* This routine is only called once per model run
*
* \author Josh Lurz
* \warning markets are not necessarily set when completeInit is called
*/

void Resource::completeInit( const string& aRegionName, const IInfo* aRegionInfo ) {
    // default unit to EJ
    if ( mOutputUnit.empty() ) {
        mOutputUnit = "EJ"; 
    }
    // default unit to $/GJ
    if ( mPriceUnit.empty() ) {
        mPriceUnit = "1975$/GJ"; 
    }
    // Allocate the resource info.
    mResourceInfo.reset( InfoFactory::constructInfo( aRegionInfo, aRegionName + "-" + mName ) );
    // Set output and price unit of resource into the resource info.
    mResourceInfo->setString( "output-unit", mOutputUnit );
    mResourceInfo->setString( "price-unit", mPriceUnit );

    if ( mObjectMetaInfo.size() ) {
        // Put values in mSectorInfo
        for ( object_meta_info_vector_type::const_iterator metaInfoIterItem = mObjectMetaInfo.begin(); 
            metaInfoIterItem != mObjectMetaInfo.end();
            ++metaInfoIterItem ) {
                mResourceInfo->setDouble( (*metaInfoIterItem).getName(), (*metaInfoIterItem).getValue() );
            }
    }

    for( vector<SubResource*>::iterator subResIter = mSubResource.begin(); subResIter != mSubResource.end(); subResIter++ ) {
      //  ( *subResIter )->completeInit( mResourceInfo.get() );
        ( *subResIter )->completeInit(aRegionName, mName, mResourceInfo.get() );
    }

    // Set markets for this sector
    setMarket( aRegionName );

    // Create a single primary output for the resource output.
  //  mOutputs.insert( mOutputs.begin(), new PrimaryOutput( mName ) );
    mOutputs.insert( mOutputs.begin(), mHack ? new GenericOutput(mName) : new PrimaryOutput( mName ) );
    
    initTechVintageVector();
    
    for( unsigned int i = 0; i < mGHG.size(); i++ ) {
        mGHG[ i ]->completeInit( aRegionName, mName, mResourceInfo.get() );
    }
}

/*! \brief Perform any initializations needed for each period.
* \details Any initializations or calculations that only need to be done once per
*          period(instead of every iteration) should be placed in this function.
* \author Sonny Kim
* \param aRegionName Region name.
* \param aPeriod Model period
*/
void Resource::initCalc( const string& aRegionName, const int aPeriod ) {
    // call subResource initializations
    for ( unsigned int i = 0; i < mSubResource.size(); i++ ){
        mSubResource[i]->initCalc( aRegionName, mName, aPeriod );
    }

    // The GHG objects will need to check the following flags to properly
    // initialize and do error checking.
    mResourceInfo->setBoolean( "new-vintage-tech", true );
    mResourceInfo->setBoolean( "is-tech-operating", true );
    for( unsigned int i = 0; i < mGHG.size(); i++ ) {
        mGHG[ i ]->initCalc( aRegionName, mResourceInfo.get(), aPeriod );
    }
    
    for( unsigned int i = 0; i < mOutputs.size(); i++ ) {
        mOutputs[ i ]->initCalc( aRegionName, mName, aPeriod );
    }
    // setup supply curve boundaries here.
    double minprice = util::getLargeNumber();
    double maxprice = -util::getLargeNumber();
    for( unsigned int i = 0; i < mSubResource.size(); ++i ) {
        minprice = std::min( minprice, mSubResource[i]->getLowestPrice( aPeriod ) );
        maxprice = std::max( maxprice, mSubResource[i]->getHighestPrice( aPeriod ) );
    }
    SectorUtils::setSupplyBehaviorBounds( mName, aRegionName, minprice, maxprice, aPeriod );
}

/*! \brief Perform any calculations needed for each period after solution is
*          found.
* \details Any calculations that only need to be done once per period after
*          solution is found(instead of every iteration) should be placed in
*          this function.
* \author Sonny Kim
* \param aRegionName Region name.
* \param aPeriod Model period
*/
void Resource::postCalc( const string& aRegionName, const int aPeriod ) {
    // Call subResource post calculations
    for ( unsigned int i = 0; i < mSubResource.size(); i++ ) {
        mSubResource[i]->postCalc( aRegionName, mName, aPeriod);
    }
    // Reset initial resource prices to solved prices
    mResourcePrice[ aPeriod ] = scenario->getMarketplace()->getPrice( mName, aRegionName, aPeriod, true );
}

//! Create markets
void Resource::setMarket( const string& aRegionName ) {

    Marketplace* pMarketplace   = scenario->getMarketplace();
    const Modeltime* pModeltime = scenario->getModeltime();
    // name is resource name
    if ( pMarketplace->createMarket( aRegionName, mMarket, mName, IMarketType::NORMAL ) ) {
        // Set price and output units for period 0 market info
        IInfo* pMarketInfo = pMarketplace->getMarketInfo( mName, aRegionName, 0, true );
        pMarketInfo->setString( "price-unit", mPriceUnit );
        pMarketInfo->setString( "output-unit", mOutputUnit );

        pMarketplace->setPriceVector( mName, aRegionName, mResourcePrice );
        for( int period = 0; period < pModeltime->getmaxper(); ++period ){
        
            // TODO: Remove or improve this. Intermittent technologies need to know during initCalc 
            // which good has a variance. This will get set again later, which is bad.
            IInfo* marketInfo = pMarketplace->getMarketInfo( mName, aRegionName, period, true );
            marketInfo->setDouble( "resourceVariance", 0 );
            if( period >= 1 ){
                pMarketplace->setMarketToSolve( mName, aRegionName, period );
            }
  
            // Put region name in market info for error checking in renewable sub-resource
            marketInfo->setString( "Market-Region", mMarket );
      }
    }
    // Put values in market.
    if ( mObjectMetaInfo.size() ) {
        // Put values in market
        for ( int period = 0; period < pModeltime->getmaxper(); ++period ) {
            IInfo* pMarketInfo = pMarketplace->getMarketInfo( mName, aRegionName, period, true );
            if ( pMarketInfo ) {
                for ( object_meta_info_vector_type::const_iterator metaInfoIterItem = mObjectMetaInfo.begin();
                    metaInfoIterItem != mObjectMetaInfo.end(); 
                    ++metaInfoIterItem ) {
                        pMarketInfo->setDouble( (*metaInfoIterItem).getName(), (*metaInfoIterItem).getValue() );
                    }
            }
        }
    }
}

//! Return resource name.
const string& Resource::getName() const {
    return mName;
}

//! Calculate total resource supply for a period.
void Resource::calcSupply( const string& aRegionName, const GDP* aGDP, const int aPeriod ){
    // This code is moved down from Region
    Marketplace* marketplace = scenario->getMarketplace();

    double price = marketplace->getPrice( mName, aRegionName, aPeriod );
    double lastPeriodPrice;

    if ( aPeriod == 0 ) {
        lastPeriodPrice = price;
    }
    else {
        lastPeriodPrice = marketplace->getPrice( mName, aRegionName, aPeriod - 1 );
    }

    // Create a dummy input vector for use in GHG calls
    // The mOutputs vector does not contain a valid value at this point, however it is
    // not used in the getGHGValue call.
    vector<IInput*> inputs; // empty vector
    
    
    double totalGHGCost = 0;
    // totalGHGCost and carbontax must be in same unit as fuel price
    for( unsigned int i = 0; i < mGHG.size(); i++ ) {
        totalGHGCost += mGHG[ i ]->getGHGValue( aRegionName, inputs, mOutputs, 0 , aPeriod );
    }
    
    // Subtract ghg cost from price paid for resource
    price -= totalGHGCost;
    
    // calculate annual supply
    annualsupply( aRegionName, aPeriod, aGDP, price, lastPeriodPrice ); 

    // There is only one primary output at the first position.
    // Setting market supply of resource occurs in setPhysicalOutput().
    mOutputs[0]->setPhysicalOutput( aPeriod > 0 ? mAnnualProd[ aPeriod ] : 0.0, aRegionName, 0, aPeriod );

    for( unsigned int i = 0; i < mGHG.size(); ++i ) {
        // no inputs or capture components
        mGHG[i]->calcEmission( aRegionName, inputs, mOutputs, aGDP, 0, aPeriod );
    }
}

void Resource::cumulsupply( double aPrice, int aPeriod )
{   
    int i = 0;
    mCumulProd[ aPeriod ] = 0.0;

    mResourcePrice[ aPeriod ] = aPrice;
    // sum cumulative production of each subsector
    for ( i = 0; i < mSubResource.size(); i++ ) {
        mSubResource[ i ]->cumulsupply( aPrice, aPeriod );
        mCumulProd[ aPeriod ] += Value( mSubResource[ i ]->getCumulProd( aPeriod ) );
    }
}

//! Calculate annual production
void Resource::annualsupply( const string& aRegionName, int aPeriod, const GDP* aGdp, double aPrice, double aPrevPrice )
{   
    int i = 0;
    mAnnualProd[ aPeriod ] = 0.0;
    mAvailable[ aPeriod ] = 0.0;

    // calculate cumulative production
    cumulsupply( aPrice, aPeriod );

    // sum annual production of each subsector
    for ( i = 0; i < mSubResource.size(); i++) {
        mSubResource[i]->annualsupply( aPeriod, aGdp, aPrice, aPrevPrice );
        mAnnualProd[ aPeriod ] += Value( mSubResource[i]->getAnnualProd( aPeriod ) );
        mAvailable[ aPeriod ] += Value( mSubResource[i]->getAvailable( aPeriod ) );
    }
}


//! Return annual production of resources.
double Resource::getAnnualProd( const string& aRegionName, const int aPeriod ) const {
    return mAnnualProd[ aPeriod ];
}

//! Return price of resources.
double Resource::getPrice( const int aPeriod ) const {
    return mResourcePrice[ aPeriod ];
}

/*! \brief Update an output container for a Resource.
* \param aVisitor Output container to update.
* \param aPeriod Period to update.
*/
void Resource::accept( IVisitor* aVisitor, const int aPeriod ) const {
    aVisitor->startVisitResource( this, aPeriod );

    // Update the output container for the subresources.
    for( unsigned int i = 0; i < mSubResource.size(); ++i ){
        mSubResource[ i ]->accept( aVisitor, aPeriod );
    }

    for( unsigned int i = 0; i < mGHG.size(); ++i ) {
        mGHG[ i ]->accept( aVisitor, aPeriod );
    }

    aVisitor->endVisitResource( this, aPeriod );
}

// ************************************************************
// Definitions for the derived classes below.
// Since these are very small changes, keep in same file for simplicity
// ************************************************************

// *******************************************************************
// DepletableResource Class
// *******************************************************************
/*! \brief Get the XML node name for output to XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* This function may be virtual to be overridden by derived class pointers.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME.
*/
const std::string& DepletableResource::getXMLName() const {
    return getXMLNameStatic();
}

/*! \brief Get the XML node name in static form for comparison when parsing XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* The "==" operator that is used when parsing, required this second function to return static.
* \note A function cannot be static and virtual.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME as a static.
*/
const std::string& DepletableResource::getXMLNameStatic() {
    static const string XML_NAME = "depresource";
    return XML_NAME;
}

//! 
/*! In this case, this read-in just substantiates the appropriate type of subResource */
/*! \brief Performs XML read-in that is specific to this derived class
*
*  this case, this read-in just instantiates the appropriate type of subResource
*
* \author Steve Smith
* \param aNodeName Name of the current node.
* \param aNode Pointer to the current node in the XML input tree
* \return Whether an element was parsed.
* \todo In the input file, *SubResources should be read in as such, not silently converted here.
*/
bool DepletableResource::XMLDerivedClassParse( const string& aNodeName, const DOMNode* aNode ) {
    // TODO: Fix this.
    if( aNodeName == SubResource::getXMLNameStatic() || aNodeName == SubDepletableResource::getXMLNameStatic() ){
        parseContainerNode( aNode, mSubResource, new SubDepletableResource() );
        return true;
    }
    return false;
}

// *******************************************************************
// FixedResource Class
// *******************************************************************
/*! \brief Get the XML node name for output to XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* This function may be virtual to be overridden by derived class pointers.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME.
*/
const std::string& FixedResource::getXMLName() const {
    return getXMLNameStatic();
}

/*! \brief Get the XML node name in static form for comparison when parsing XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* The "==" operator that is used when parsing, required this second function to return static.
* \note A function cannot be static and virtual.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME as a static.
*/
const std::string& FixedResource::getXMLNameStatic() {
    static const string XML_NAME = "fixedresource";
    return XML_NAME;
}

//! 
/*! In this case, this read-in just substantiates the appropriate type of subResource */
/*! \brief Performs XML read-in that is specific to this derived class
*
*  this case, this read-in just instantiates the appropriate type of subResource
*
* \author Steve Smith
* \param node pointer to the current node in the XML input tree
* \param nodeName name of the current node 
* \return Whether an element was parsed.
*/
bool FixedResource::XMLDerivedClassParse( const string& aNodeName, const DOMNode* aNode ) {
    if( aNodeName == SubResource::getXMLNameStatic() || aNodeName == SubFixedResource::getXMLNameStatic() ){
        parseContainerNode( aNode, mSubResource, new SubFixedResource() );
        return true;
    }
    return false;
}
// *******************************************************************
// RenewableResource Class
// *******************************************************************

//! \brief set the size for the resourceVariance member
RenewableResource::RenewableResource()
{
}


/*! \brief Get the XML node name for output to XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* This function may be virtual to be overridden by derived class pointers.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME.
*/
const std::string& RenewableResource::getXMLName() const {
    return getXMLNameStatic();
}

/*! \brief Get the XML node name in static form for comparison when parsing XML.
*
* This public function accesses the private constant string, XML_NAME.
* This way the tag is always consistent for both read-in and output and can be easily changed.
* The "==" operator that is used when parsing, required this second function to return static.
* \note A function cannot be static and virtual.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME as a static.
*/
const std::string& RenewableResource::getXMLNameStatic() {
    static const string XML_NAME = "renewresource";
    return XML_NAME;
}

//! 
/*! In this case, this read-in just substantiates the appropriate type of subResource */
/*! \brief Performs XML read-in that is specific to this derived class
*
*  this case, this read-in just instantiates the appropriate type of subResource
*
* \author Steve Smith
* \param node pointer to the current node in the XML input tree
* \param nodeName name of the current node 
* \return Whether an element was parsed.
*/
bool RenewableResource::XMLDerivedClassParse( const string& nodeName, const DOMNode* node )
{
    if( nodeName == SubResource::getXMLNameStatic() ||
        nodeName == SubRenewableResource::getXMLNameStatic() ) {
            parseContainerNode( node, mSubResource, new SubRenewableResource() );
            return true;
        }
    else if ( nodeName == SmoothRenewableSubresource::getXMLNameStatic() ) {
        parseContainerNode( node, mSubResource, new SmoothRenewableSubresource() );
        return true;
    }
    return false;
}

/*! \brief Complete the initialization
*
* This routine is only called once per model run.
*
* \author Sonny Kim
* \warning markets are not necessarily set when completeInit is called
*/

void RenewableResource::completeInit( const string& aRegionName, const IInfo* aRegionInfo ) {

    // Complete resource initialization.
    // Base class completeInit must be called first to create the market.
    Resource::completeInit( aRegionName, aRegionInfo );

    Marketplace* pMarketplace = scenario->getMarketplace();
    const Modeltime* pModeltime = scenario->getModeltime();
    // Initialize resource variance and capacitity factors in this market's info
    /*!
     * \warning This strategy of calculating resource variance and capacity factor
     *          is inadequate due to sequence issues.  If these values are not 
     *          constant i.e. multiple subresources it will cause trouble when solving
     *          and trying to reproduce a solution.  For such a case a trial value
     *          should be utilized to directly handle the sequence issue.
     */
    double resourceVariance = mSubResource[ 0 ]->getVariance();
    double resourceCapacityFactor = mSubResource[ 0 ]->getAverageCapacityFactor();
    
    ILogger& mainLog = ILogger::getLogger( "main_log" );
    mainLog.setLevel( ILogger::WARNING );
    for( int subResource = 1; subResource < mSubResource.size(); ++subResource ) {
        if( mSubResource[ subResource ]->getVariance() != resourceVariance ) {
            mainLog << "Non-constant resource variance in " << mName << ", region: "
                << aRegionName << " may cause trouble finding a solution." << endl;
        }
        if( mSubResource[ subResource ]->getAverageCapacityFactor() != resourceCapacityFactor ) {
            mainLog << "Non-constant resource capacity factor in " << mName << ", region: "
                << aRegionName << " may cause trouble finding a solution." << endl;
        }
    }
    
    for( int period = 0; period < pModeltime->getmaxper(); ++period ){
        IInfo* marketInfo = pMarketplace->getMarketInfo( mName, aRegionName, period, true );
        marketInfo->setDouble( "resourceVariance", resourceVariance );
        marketInfo->setDouble( "resourceCapacityFactor", resourceCapacityFactor );
    }
}    

//! Calculate annual production
/*! \brief Adds to the base Resource::annualsupply by computing a weighted-average
*  variance of the resource based on the variance of the subresources.
*
* \author Steve Smith.  Mod for intermittent by Marshall Wise
*/
void RenewableResource::annualsupply( const string& aRegionName, int aPeriod, const GDP* aGdp, double aPrice, double aPrevPrice )
{

    // calculate cumulative production
    cumulsupply( aPrice, aPeriod );

    // clear out sums for this iteration
    mAnnualProd[ aPeriod ]=0.0;
    mAvailable[ aPeriod ]=0.0;
    mResourceVariance[ aPeriod ]=0.0;
    mResourceCapacityFactor[ aPeriod ] = 0.0;
    
    // If annual production is extremely small or zero, these will not be calculated properly.
    // In this case, set production to some minimum number.
    const double MIN_RESOURCE_PROD = util::getVerySmallNumber();
    double adjustedProduction = 0;
    
    // sum annual production of each subsector
    for (int i=0;i<mSubResource.size();i++) {
        mSubResource[i]->annualsupply( aPeriod, aGdp, aPrice, aPrevPrice );
        mAnnualProd[ aPeriod ] += Value( mSubResource[i]->getAnnualProd( aPeriod ) );
        double adjustedSubResourceProd = max( mSubResource[i]->getAnnualProd( aPeriod ), MIN_RESOURCE_PROD );
        adjustedProduction += adjustedSubResourceProd;
        mAvailable[ aPeriod ] += Value( mSubResource[i]->getAvailable( aPeriod ) );
        
        // and compute weighted average variance
        mResourceVariance[ aPeriod ] += adjustedSubResourceProd * mSubResource[i]->getVariance();
        // and compute weighted average capacity factor
        mResourceCapacityFactor[ aPeriod ] += adjustedSubResourceProd * mSubResource[i]->getAverageCapacityFactor();
    }

    // TODO: This is currently wrong because the resource calculation is done last
    // so if there were multiple subresources with different variances this would
    // calculate a stale value and result in solution problems. It would also
    // be wrong in that case for global markets.

    // This may be a global market and the resource may only exist to add the
    // region into the market. In this case the resource will not have any
    // subresources, and should not adjust the market info values.
    if( !mSubResource.empty() ){
        if ( adjustedProduction >= MIN_RESOURCE_PROD ) {
            mResourceVariance[ aPeriod ] /= adjustedProduction;
            mResourceCapacityFactor[ aPeriod ] /= adjustedProduction;
        }

        // add variance to marketinfo
        IInfo* marketInfo = scenario->getMarketplace()->getMarketInfo( mName, aRegionName, aPeriod, true );
        marketInfo->setDouble( "resourceVariance", mResourceVariance[ aPeriod ] );

        // add capacity factor to marketinfo
        marketInfo->setDouble( "resourceCapacityFactor", mResourceCapacityFactor[ aPeriod ] );
    }
}

/*!
 * \brief Initialize any TechVintageVector in any object that may be contained
 *        in this class.
 * \details Resource does not have vintaging so the vectors will be sized for
 *          the entire model time.
 */
void Resource::initTechVintageVector() {
    const Modeltime* modeltime = scenario->getModeltime();
    objects::InitializeTechVectorHelper helper( 0, modeltime->getmaxper() );
    helper.initializeTechVintageVector( this );
}
