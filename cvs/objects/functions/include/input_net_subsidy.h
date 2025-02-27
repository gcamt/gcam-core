#ifndef _INPUT_NET_SUBSIDY_H_
#define _INPUT_NET_SUBSIDY_H_
#if defined(_MSC_VER)
#pragma once
#endif

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
 * \file input_net_subsidy.h
 * \ingroup Objects
 * \brief InputNetSubsidy class header file.
 * \author Sonny Kim
 */

#include <string>
#include <memory>
#include <xercesc/dom/DOMNode.hpp>

#include "functions/include/minicam_input.h"
#include "util/base/include/value.h"
#include "util/base/include/time_vector.h"

class Tabs;

/*! 
 * \ingroup Objects
 * \brief Defines a net sector subsidy input to a MiniCAM production function.
 * \details Tax inputs to production functions represent fuel taxes and can be
 *          used to constrain fuel output. The value of an input tax is either
 *          read in or calculated to meet the constraint.
 *
 *          <b>XML specification for InputTax</b>
 *          - XML name: \c input-tax
 *          - Contained by: Technology
 *          - Parsing inherited from class: MiniCAMInput
 *          - Attributes:
 *              - \c name MiniCAMInput::mName
 *          - Elements:
 *              - \c isShareBased Boolean indicating that a constraint is based on 
 *                             share of sector output.
 *              - \c mSectorName String indicating which sector the share based 
 *                             constraint applies to (e.g., a share constraint of 0.15
 *                             and sector name of electricity indicates that whatever 
 *                             fuel is being constrained must account for at least
 *                             15% of electricity output)
 *
 * \author Sonny Kim
 */
class InputNetSubsidy: public MiniCAMInput
{
    friend class InputFactory;
public:

    InputNetSubsidy();

    virtual ~InputNetSubsidy();

    virtual InputNetSubsidy* clone() const;

    static const std::string& getXMLNameStatic();

    virtual const std::string& getXMLReportingName() const;

    virtual void XMLParse( const xercesc::DOMNode* aNode );

    virtual bool isSameType( const std::string& aType ) const;

    virtual void toInputXML( std::ostream& aOut,
                             Tabs* aTabs ) const;

    virtual void toDebugXML( const int aPeriod,
                             std::ostream& aOut,
                             Tabs* aTabs ) const;

    virtual void copyParam( const IInput* aInput,
                            const int aPeriod );

    virtual void completeInit( const std::string& aRegionName,
                               const std::string& aSectorName,
                               const std::string& aSubsectorName,
                               const std::string& aTechName,
                               const IInfo* aTechInfo );

    virtual void initCalc( const std::string& aRegionName,
                           const std::string& aSectorName,
                           const bool aIsNewInvestmentPeriod,
                           const bool aIsTrade,
                           const IInfo* aTechInfo,
                           const int aPeriod );

    virtual double getCO2EmissionsCoefficient( const std::string& aGHGName,
                                             const int aPeriod ) const;
    
    virtual double getPhysicalDemand( const int aPeriod ) const;
    
    virtual double getCarbonContent( const int aPeriod ) const;
    
    virtual double getPrice( const std::string& aRegionName,
                             const int aPeriod ) const;

    virtual void setPrice( const std::string& aRegionName,
                           const double aPrice,
                           const int aPeriod );

    virtual void setPhysicalDemand( const double aPhysicalDemand,
                                    const std::string& aRegionName,
                                    const int aPeriod );

    virtual double getCoefficient( const int aPeriod ) const;

    virtual void setCoefficient( const double aCoefficient,
                                 const int aPeriod );

    virtual double getCalibrationQuantity( const int aPeriod ) const;

    virtual bool hasTypeFlag( const int aTypeFlag ) const;
    
    virtual double getIncomeElasticity( const int aPeriod ) const;

    virtual double getPriceElasticity( const int aPeriod ) const;

    virtual double getTechChange( const int aPeriod ) const;

    virtual void copyParamsInto( InputNetSubsidy& aInput,
                                 const int aPeriod ) const;

protected:
    InputNetSubsidy( const InputNetSubsidy& aOther );
    
    // Define data such that introspection utilities can process the data from this
    // subclass together with the data members of the parent classes.
    DEFINE_DATA_WITH_PARENT(
        MiniCAMInput,
        
        //! Physical Demand.
        DEFINE_VARIABLE( ARRAY | STATE, "physical-demand", mPhysicalDemand, objects::PeriodVector<Value> ),
        
        //! Current coefficient after adjustments have been made by the technology's
        //! capture component.
        DEFINE_VARIABLE( ARRAY, "current-coef", mAdjustedCoefficients, objects::PeriodVector<Value> )
    )

    //! Stash the current sector name for use in setPhysicalDemand
    std::string mSectorName;
private:
    const static std::string XML_REPORTING_NAME; //!< tag name for reporting xml db
};

#endif // _INPUT_NET_SUBSIDY_H_
