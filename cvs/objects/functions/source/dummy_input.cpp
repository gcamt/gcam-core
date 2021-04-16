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
 * All rights to use the Software are granted on condition that such
 * rights are forfeited if User fails to comply with the terms of
 * this Agreement.
 * 
 * User agrees to identify, defend and hold harmless BATTELLE,
 * its officers, agents and employees from all liability involving
 * the violation of such Export Laws, either directly or indirectly,
 * by User.
 */

/*! 
 * \file energy_input.cpp
 * \ingroup Objects
 * \brief The EnergyInput class source file.
 * \author Josh Lurz
 */

#include "util/base/include/definitions.h"
#include <xercesc/dom/DOMNode.hpp>

#include "functions/include/dummy_input.h"
#include "containers/include/scenario.h"
#include "util/base/include/xml_helper.h"
#include "functions/include/function_utils.h"

using namespace std;
using namespace xercesc;

extern Scenario* scenario;

// static initialize.
const string DummyInput::XML_REPORTING_NAME = "input-dummy";

/*! \brief Get the XML node name in static form for comparison when parsing XML.
*
* This public function accesses the private constant string, XML_NAME. This way
* the tag is always consistent for both read-in and output and can be easily
* changed. The "==" operator that is used when parsing, required this second
* function to return static.
* \note A function cannot be static and virtual.
* \author Josh Lurz, James Blackwood
* \return The constant XML_NAME as a static.
*/
const string& DummyInput::getXMLNameStatic() {
    const static string XML_NAME = "dummy-input";
    return XML_NAME;
}

/*! \brief Get the XML name for reporting to XML file.
*
* This public function accesses the private constant string, XML_NAME. This way
* the tag is always consistent for reporting outputs and can be easily
* changed.
* \author Sonny Kim
* \return The constant XML_NAME.
*/
const string& DummyInput::getXMLReportingName() const{
    return XML_REPORTING_NAME;
}

//! Constructor
DummyInput::DummyInput()
: mPhysicalDemand( scenario->getModeltime()->getmaxper() )
{
}

/*!
 * \brief Destructor.
 * \note An explicit constructor must be defined to avoid the compiler inlining
 *       it in the header file before the header file for the type contained in
 *       the auto_ptr is included.
 */
DummyInput::~DummyInput() {
}

/*!
 * \brief Copy constructor.
 * \note This class requires a copy constructor because it has dynamically
 *          allocated memory.
 * \param aOther Energy input from which to copy.
 */
DummyInput::DummyInput( const DummyInput& aOther ){
    mName = aOther.mName;

    // Resize vectors to the correct size.
    mPhysicalDemand.resize( scenario->getModeltime()->getmaxper() );
}

DummyInput* DummyInput::clone() const {
    return new DummyInput( *this );
}

bool DummyInput::isSameType( const string& aType ) const {
    return aType == getXMLNameStatic();
}

void DummyInput::XMLParse( const xercesc::DOMNode* node ) {
    // TODO: Replace this with the restructured XMLParse.
    // Make sure we were passed a valid node.
    assert( node );

    // get the name attribute.
    mName = XMLHelper<string>::getAttr( node, "name" );
}

void DummyInput::toInputXML( ostream& aOut,
                               Tabs* aTabs ) const
{
    XMLWriteOpeningTag( getXMLNameStatic(), aOut, aTabs, mName );
    XMLWriteClosingTag( getXMLNameStatic(), aOut, aTabs );
}

void DummyInput::toDebugXML( const int aPeriod,
                               ostream& aOut,
                               Tabs* aTabs ) const
{
    XMLWriteOpeningTag ( getXMLNameStatic(), aOut, aTabs, mName );
    XMLWriteElement( mCO2Coefficient.isInited() ? mCO2Coefficient.get() : -1,
                     "cached-co2-coef", aOut, aTabs );
    XMLWriteClosingTag( getXMLNameStatic(), aOut, aTabs );
}

void DummyInput::completeInit( const string& aRegionName,
                                const string& aSectorName,
                                const string& aSubsectorName,
                                const string& aTechName,
                                const IInfo* aTechInfo )
{
}

void DummyInput::initCalc( const string& aRegionName,
                            const string& aSectorName,
                            const bool aIsNewInvestmentPeriod,
                            const bool aIsTrade,
							const IInfo* aTechInfo,
                            const int aPeriod )
{
    // Initialize the coefficient from the marketplace.
    mCO2Coefficient = FunctionUtils::getCO2Coef( aRegionName, mName, aPeriod );
}

void DummyInput::copyParam( const IInput* aInput,
                             const int aPeriod )
{
}

double DummyInput::getCO2EmissionsCoefficient( const string& aGHGName,
                                             const int aPeriod ) const
{
    // Check that the CO2 coefficient is initialized.
    assert( mCO2Coefficient.isInited() );
    return mCO2Coefficient;
}

double DummyInput::getPhysicalDemand( const int aPeriod ) const {
    assert( mPhysicalDemand[ aPeriod ].isInited() );
    return mPhysicalDemand[ aPeriod ];
}

double DummyInput::getCarbonContent( const int aPeriod ) const {
    return 0.0;
}

void DummyInput::setPhysicalDemand( double aPhysicalDemand,
                                     const string& aRegionName,
                                     const int aPeriod )
{
    mPhysicalDemand[ aPeriod ].set( aPhysicalDemand );
}

double DummyInput::getCoefficient( const int aPeriod ) const {
    return 1.0; 
}

void DummyInput::setCoefficient( const double aCoefficient,
                                  const int aPeriod )
{
}

double DummyInput::getPrice( const string& aRegionName,
                              const int aPeriod ) const
{
    return 0;
}

void DummyInput::setPrice( const string& aRegionName,
                            const double aPrice,
                            const int aPeriod )
{
    // Not hooking this up yet, it could work.
}

double DummyInput::getCalibrationQuantity( const int aPeriod ) const
{
    return -1;
}

bool DummyInput::hasTypeFlag( const int aTypeFlag ) const {
    return ( ( aTypeFlag & ~IInput::ENERGY ) == 0 );
}

double DummyInput::getIncomeElasticity(const int aPeriod) const {
    return 0;
}

double DummyInput::getPriceElasticity(const int aPeriod) const {
    return 0;
}

double DummyInput::getTechChange( const int aPeriod ) const
{
    return 0;
}

void DummyInput::doInterpolations( const int aYear, const int aPreviousYear,
                                    const int aNextYear, const IInput* aPreviousInput,
                                    const IInput* aNextInput )
{
}

