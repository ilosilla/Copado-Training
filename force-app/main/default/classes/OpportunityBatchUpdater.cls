/**
* @author 		Ramón Prades
* @date 		July 2022
* @group 		Opportunities
* @description 	Batchable class to update a large number of opportunities.
*               It is meant to be used by overwriting "execute" when needed.
*               Current function is to write the info type value in Opportunity 
*               (to start using the infotype object).
*/
global class OpportunityBatchUpdater implements Database.Batchable<SObject> {

    global String infoType; // PROJECT, KITCHEN or FACADE

    global OpportunityBatchUpdater(String infoType) {
        this.infoType = infoType;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<Id> oppIds = new List<Id>();
        if (infoType == 'PROJECT') {
            for (OppCustomProject__c cp : [Select Id, Opportunity__c from OppCustomProject__c]) {
                oppIds.add(cp.Opportunity__c);
            }
        } else if (infoType == 'KITCHEN') {
            for (OppKitchen__c cp : [Select Id, Opportunity__c from OppKitchen__c]) {
                oppIds.add(cp.Opportunity__c);
            }
        } else if (infoType == 'FACADE') {
            for (OppFacade__c cp : [Select Id, Opportunity__c from OppFacade__c]) {
                oppIds.add(cp.Opportunity__c);
            }
        }

        String query = 'select Id, InfoType__c from Opportunity where Id in :oppIds';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {
        for(Opportunity opp : opportunities) {        
            // Update the Account Name 
            opp.InfoType__c = this.infoType;
        }
        try {
            update opportunities;         
        } catch(Exception e) {
            System.debug(e);
        } 
    }   
     
    global void finish(Database.BatchableContext BC) {
    }
}