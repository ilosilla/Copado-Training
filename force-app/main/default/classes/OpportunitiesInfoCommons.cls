/**
* @author 		Ramón Prades
* @date 		July 2022
* @group 		Opportunities
* @description 	Common functions for opportunity additional info objects (projects, facades and kitchens=)
*/
public without sharing class OpportunitiesInfoCommons {
    
    public final static String PROJECT_TYPE = 'PROJECT';
    public final static String FACADE_TYPE = 'FACADE';
    public final static String KITCHEN_TYPE = 'KITCHEN';
    
    public static void setOpportunityType(List<Id> oppIds, String infoType) {
        Opportunity[] oppsToUpdate = new List<Opportunity>();
        Opportunity[] opps = [select Id, InfoType__c from Opportunity where Id in :oppIds];        
        for (Opportunity opp :opps) {
            if (opp.InfoType__c != infoType) {
                opp.InfoType__c = infoType;
                oppsToUpdate.add(opp);
            }
        }
        if (oppsToUpdate.size() > 0) {
            update opps;
        }
    }      
} // class