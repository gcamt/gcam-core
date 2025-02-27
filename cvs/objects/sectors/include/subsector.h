#ifndef _SUBSECTOR_H_
#define _SUBSECTOR_H_
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
* \file subsector.h
* \ingroup Objects
* \brief The Subsector class header file.
* \author Sonny Kim
*/

#include <string>
#include <vector>
#include <map>
#include <list>
#include <xercesc/dom/DOMNode.hpp>
#include <boost/core/noncopyable.hpp>

#include "investment/include/iinvestable.h"
#include "util/base/include/inamed.h"
#include "util/base/include/value.h"
#include "util/base/include/time_vector.h"
#include "util/base/include/data_definition_util.h"

// Forward declarations
class ITechnologyContainer;
class GDP;
class IInfo;
class BaseTechnology;
class NationalAccount;
class Demographic;
class MoreSectorInfo;
class IExpectedProfitRateCalculator;
class TechnologyType;
class IDistributor;
class Tabs;
class ILandAllocator;
class Demographics;
class InterpolationRule;
class IDiscreteChoice;

// Need to forward declare the subclasses as well.
class TranSubsector;
class AgSupplySubsector;
class SubsectorAddTechCosts;

/*! 
* \ingroup Objects
* \brief A class which defines a single Subsector of the model.
* \details The subsector contains a group of technology objects, which produce
*          and consume commodities in the marketplace. Each Subsector has
*          attributes such as share, share weight and a logit exponential.
* \author Sonny Kim, Steve Smith, Josh Lurz
*/

class Subsector: public INamed,
                 public IInvestable,
                 private boost::noncopyable
{
    friend class XMLDBOutputter;
    // needs to be friend so that it can set the doCalibration flag
    friend class InvestableCounterVisitor;
    // needs to be friend so that it can set a new share weight directly into
    // shrwts, note that if there was a setShare weight method this would not
    // be necessary
    friend class SetShareWeightVisitor;
    friend class CalibrateShareWeightVisitor;
private:
    void clear();
    void clearInterpolationRules();
    //! A flag for convenience to know whether this Subsector created a market
    //! for calibration (SGM)
    bool doCalibration;
protected:
    
    DEFINE_DATA(
        /* Declare all subclasses of Subsector to allow automatic traversal of the
         * hierarchy under introspection.
         */
        DEFINE_SUBCLASS_FAMILY( Subsector, TranSubsector, AgSupplySubsector, SubsectorAddTechCosts ),

        //! subsector name
        DEFINE_VARIABLE( SIMPLE, "name", mName, std::string ),

        //! region name
        DEFINE_VARIABLE( SIMPLE, "region-name", mRegionName, std::string ),

        //! sector name
        DEFINE_VARIABLE( SIMPLE, "sector-name", mSectorName, std::string ),

        //! Subsector logit share weights
        DEFINE_VARIABLE( ARRAY | STATE, "share-weight", mShareWeights, objects::PeriodVector<Value> ),

        //! The original subsector logit share weights that were parsed
        DEFINE_VARIABLE( ARRAY, "parsed-share-weight", mParsedShareWeights, objects::PeriodVector<Value> ),
                    
        //! Fuel preference elasticity
        DEFINE_VARIABLE( ARRAY, "fuelprefElasticity", mFuelPrefElasticity, objects::PeriodVector<double> ),
        
        //! Vector of technology containers by name
        DEFINE_VARIABLE( CONTAINER, "technology", mTechContainers, std::vector<ITechnologyContainer*> ),

        //! Interpolation rules for subsector share weight values.
        DEFINE_VARIABLE( CONTAINER, "interpolation-rule", mShareWeightInterpRules, std::vector<InterpolationRule*> ),

        //! Discrete choice model used for allocating technology shares
        DEFINE_VARIABLE( CONTAINER, "discreate-choice-function", mDiscreteChoiceModel, IDiscreteChoice* )
    )
    
    // Some typedefs for technology interators
    typedef std::vector<ITechnologyContainer*>::iterator TechIterator;
    typedef std::vector<ITechnologyContainer*>::const_iterator CTechIterator;
    // Some typedefs to make using interpolation rules more readable.
    typedef std::vector<InterpolationRule*>::const_iterator CInterpRuleIterator;
    
    std::auto_ptr<IInfo> mSubsectorInfo; //!< The subsector's information store.

    std::vector<double> mInvestments; //!< Investment by period.
    std::vector<double> mFixedInvestments; //!< Input fixed subsector level investment by period.
    std::vector<BaseTechnology*> baseTechs; // for the time being
    std::map<std::string, TechnologyType*> mTechTypes; //!< Mapping from technology name to group of technology vintages.

    virtual void interpolateShareWeights( const int aPeriod );
    std::map<std::string,int> baseTechNameMap; //!< Map of base technology name to integer position in vector. 
    typedef std::vector<BaseTechnology*>::const_iterator CBaseTechIterator;
    typedef std::vector<BaseTechnology*>::iterator BaseTechIterator;

    virtual bool getCalibrationStatus( const int aPeriod ) const;

    virtual bool XMLDerivedClassParse( const std::string& nodeName, const xercesc::DOMNode* curr );
    virtual const std::string& getXMLName() const;
    virtual void toDebugXMLDerived( const int period, std::ostream& out, Tabs* tabs ) const {};
    void parseBaseTechHelper( const xercesc::DOMNode* curr, BaseTechnology* aNewTech );
    
    virtual const std::vector<double> calcTechShares ( const GDP* gdp, const int period ) const;

public:
    Subsector( const std::string& regionName, const std::string& sectorName );
    virtual ~Subsector();
    const std::string& getName() const;

    void XMLParse( const xercesc::DOMNode* aNode );

    virtual void completeInit( const IInfo* aSectorInfo,
                               ILandAllocator* aLandAllocator );
    
    virtual void initCalc( NationalAccount* aNationalAccount,
                           const Demographic* aDemographics,
                           const MoreSectorInfo* aMoreSectorInfo,
                           const int aPeriod );

    void toDebugXML( const int period, std::ostream& out, Tabs* tabs ) const;
    static const std::string& getXMLNameStatic();
    virtual double getPrice( const GDP* aGDP, const int aPeriod ) const;
    //maw march 2017
    virtual double getPureTechnologyPrice( const GDP* aGDP, const int aPeriod ) const;

    bool allOutputFixed( const int period ) const;
    bool containsOnlyFixedOutputTechnologies( const int period ) const;
    virtual double getAverageFuelPrice( const GDP* aGDP, const int aPeriod ) const;

    virtual void calcCost( const int aPeriod );

    virtual double calcShare( const IDiscreteChoice* aChoiceFn, const GDP* aGDP, const int aPeriod) const;
    virtual double getShareWeight( const int period ) const;

    virtual void setOutput( const double aVariableDemand,
                            const double aFixedOutputScaleFactor,
                            const GDP* aGDP,
                            const int aPeriod );

    bool isAllCalibrated( const int aPeriod, double aCalAccuracy, const bool aPrintWarnings ) const;
    double getFixedOutput( const int Period, const double aMarginalRevenue ) const;

    virtual double getTotalCalOutputs( const int period ) const;

    void emission( const int period );

    double getInput( const int period ) const;
    virtual double getOutput( const int period ) const;

    virtual double getEnergyInput( const int aPeriod ) const;

    double getAnnualInvestment( const int aPeriod ) const;

    double distributeInvestment( const IDistributor* aDistributor,
                                 NationalAccount& aNationalAccount,
                                 const IExpectedProfitRateCalculator* aExpProfitRateCalc,
                                 const std::string& aRegionName,
                                 const std::string& aSectorName,
                                 const double aNewInvestment,
                                 const int aPeriod );
    
    double getExpectedProfitRate( const NationalAccount& aNationalAccount,
                                  const std::string& aRegionName,
                                  const std::string& aSectorName,
                                  const IExpectedProfitRateCalculator* aExpProfitRateCalc,
                                  const double aInvestmentLogitExp,
                                  const bool aIsShareCalc,
                                  const bool aIsDistributing,
                                  const int aPeriod ) const;
    
    double getCapitalOutputRatio( const IDistributor* aDistributor,
                                  const IExpectedProfitRateCalculator* aExpProfitRateCalc,
                                  const NationalAccount& aNationalAccount,
                                  const std::string& aRegionName,
                                  const std::string& aSectorName, 
                                  const int aPeriod ) const;

    void operate( NationalAccount& aNationalAccount, const Demographic* aDemographic,
                  const MoreSectorInfo* aMoreSectorInfo, const bool isNewVintageMode, const int aPeriod );
    
    void updateMarketplace( const int period );
    void postCalc( const int aPeriod );
    virtual void accept( IVisitor* aVisitor, const int aPeriod ) const;
    double getFixedInvestment( const int aPeriod ) const;
    bool hasCalibrationMarket() const;
};
#endif // _SUBSECTOR_H_
