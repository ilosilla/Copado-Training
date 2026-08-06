/**
* @author 		Ramón Prades
* @date 		July 2022
* @group 		Opportunities   
* @description 	First version of a domain class to start adding content here instead of to the trigger
*/
public without sharing class OpportunitiesDomain extends zflib_DomainClass {

    public static final String INFO_LOST_STAGE = 'LOST';
    public static final String PROJECT_DEPOSIT_STAGE = 'DEPOSIT';

    public OpportunitiesDomain(List<Opportunity> opportunities) {
        super(opportunities);
    }

    /**
     * Applies automatic actions depending on the opportunity stage
     */
    public void runStageActions(Map<Id, Opportunity> existingRecords) {
        this.ExistingRecords = existingRecords;
        this.setInfoObjectStage();
    } 

    /**
     * Same with no pre-existing records
     */
    public void runStageActions() {
        this.runStageActions(new Map<Id, Opportunity>());
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /*
     * Change the info object stage when opportunity stage changes
     */
    private void setInfoObjectStage() {
        List<String> wonStages = OpportunityCOmmons.getClosedWonStages();
        List<String> lostStages = OpportunityCOmmons.getClosedLostStages();

        List<SObject> infoObjects = new List<SObject>();
        for (Opportunity opp: (List<Opportunity>) this.Records) {
            Boolean selected = false;            
            Opportunity oldOpp = (Opportunity) this.ExistingRecords.get(opp.Id);
            selected = (oldOpp == null || oldOpp.StageName != opp.stageName);
            selected = (selected && String.IsNotBlank(opp.infoType__c));
            if (!selected) {
                continue;
            }
            if (wonStages.contains(opp.StageName) && opp.infoType__c == OpportunitiesInfoCommons.PROJECT_TYPE) {
                Sobject infoObject = this.getInfoObject(opp.Id, opp.InfoType__c);
                ((OppCustomProject__c) infoObject).Stage__c = PROJECT_DEPOSIT_STAGE;
                infoObjects.add(infoObject);                
            } else if (lostStages.contains(opp.StageName)) {

                SObject infoObject2 = this.getInfoObject(opp.Id, opp.InfoType__c);
                infoObjects.add(infoObject2);
            }
        }
        update infoObjects;
    }

    private SObject getInfoObject(Id oppId, String objectType) {
        SObject infoObject = null;
        try {
            if (objectType == OpportunitiesInfoCommons.PROJECT_TYPE) {
                infoObject = [select Id, Opportunity__c from OppCustomProject__c where Opportunity__c = :oppId limit 1];
                ((OppCustomProject__c)infoObject).Stage__c = INFO_LOST_STAGE;
            } else if (objectType == OpportunitiesInfoCommons.FACADE_TYPE) {
                infoObject = [select Id, Opportunity__c from OppFacade__c where Opportunity__c = :oppId limit 1];
                ((Oppfacade__c)infoObject).Stage__c = INFO_LOST_STAGE;

            } else if (objectType == OpportunitiesInfoCommons.KITCHEN_TYPE) {             
                infoObject = [select Id, Opportunity__c from OppKitchen__c where Opportunity__c = :oppId limit 1];
                ((OppKitchen__c)infoObject).Stage__c = INFO_LOST_STAGE;
            }
        } catch (Exception ex) {}
        return infoObject;
    }

    /**
     * @description Set the default currency, depending on the country of the Opportunity
     */
    public static void setOpportunityCurrency(List<Opportunity> newOpportunities) {
        for (Opportunity opp : newOpportunities) {
            switch on opp.CountryCode__c {
                when 'US' {
                    opp.Currency__c = 'USD';
                }
                when 'CA' {
                    opp.Currency__c = 'CAD';
                }
                when 'GB' {
                    opp.Currency__c = 'GBP';
                }
                when 'CH' {
                    opp.Currency__c = 'CHF';
                }
                when 'SE' {
                    opp.Currency__c = 'SEK';
                }
                when 'IL' {
                    opp.Currency__c = 'ILS';
                }
                when 'AU' {
                    opp.Currency__c = 'AUD';
                }
                when 'CL' {
                    opp.Currency__c = 'CLP';
                }
                when 'DK' {
                    opp.Currency__c = 'DKK';
                }
                when 'RD' {
                    opp.Currency__c = 'DOP';
                }
                when else {
                    opp.Currency__c = 'EUR';
                }
            }
        }
    }

    /**
     * @description Changes the stage of the Opp depending on the values on some fields
     * TODO Cambiarlo a formato FFLIB Cuando el Domain se esté usando para el Trigger, ya que debería de usar "this.Records" 
     */
    public static void setOpportunityStage(List<Opportunity> newOpportunities) {
        setOpportunityStage(newOpportunities, new Map<Id, Opportunity>());
    }

    public static void setOpportunityStage(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        Id RecordTypeTradeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_trade').getRecordTypeId();
        
        for (Opportunity opp : newOpportunities) {
            
            // LOST : when a reason lost has been set
            if (String.isNotBlank(opp.Reason_Lost__c) && opp.LastOrderDateTime__c == null) {
                opp.StageName = INFO_LOST_STAGE;
            }
            /* Balma al final no quiere ponerlo hasta que los productos de SAP puedan pasar a SF
             if there is one or more product items, changes the stage to SPECIFICATION, if on QUALIFICATION*/
            if (opp.RecordTypeId == RecordTypeTradeId && opp.numberOfProducts__c >= 1 && opp.stageName.toUpperCase() == 'QUALIFICATION') {
                opp.stageName = 'ESPECIFICACIÓN';
            }
            // If all products are removed and the stage is SPECIFICATION, it changes to QUALIFICATION
            if (opp.RecordTypeId == RecordTypeTradeId &&
                opp.stageName.toUpperCase() == 'ESPECIFICACIÓN' &&
                oldOpportunities.size() > 0 &&
                opp.numberOfProducts__c == 0 &&
                oldOpportunities.get(opp.Id).numberOfProducts__c != opp.numberOfProducts__c) {
                opp.stageName = 'QUALIFICATION';
            }
        }
    }

    /**
     * @description Set the default currency, depending on the country of the Opportunity
     */
    public static void setOpportunitySalesProgram(Set<Id> oppids) {
        try {
            Map<String, Opportunity> mapOpps= new Map<String, Opportunity>();
            Set<String> oppIdsTandem = new Set<String>();

            List<Opportunity> opps = new OpportunitiesSelector().selectById(oppids);

            List<OpportunityContactRole> allContactRolesFullData = [SELECT id, opportunityId, Account__c, Contact.Account.Id, Opportunity.Account.Id, Contact.Account.Account_Classification__c, Contact.Account.TypeCustomer__c FROM OpportunityContactRole WHERE opportunityId IN : oppids];

            System.debug('ENTER OPP SALES PROGRAM');
            for (OpportunityContactRole contactRole : allContactRolesFullData) {
                if (contactRole.Contact.Account.Id != contactRole.Opportunity.Account.Id ) {
                    // TANDEM PROGRAM - Si el cliente de un contact tiene como TypeCustomer TANDEM, la oportunidad es Tándem
                    System.debug('Type Customer: ' + contactRole.Contact.Account.TypeCustomer__c);
                    if (contactRole.Contact.Account.TypeCustomer__c == 'TANDEM') {
                        oppIdsTandem.add(contactRole.opportunityId);
                    }
                }
            }

            for (Opportunity opp : opps) {
                opp.SalesProgram__c = null;
                 // TANDEM PROGRAM
                if (oppIdsTandem.contains(opp.Id)) {
                    opp.SalesProgram__c = 'TANDEM';
                }
                mapOpps.put(opp.Id, opp);
            }

            update mapOpps.values();
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }
}