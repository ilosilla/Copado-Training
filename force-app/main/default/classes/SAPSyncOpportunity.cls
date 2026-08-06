/**
* @author           Ramón Prades
* @date             September 2020
* @group            SAP
* @description      Sends opportunity details to SAP
*/
public class SAPSyncOpportunity {
    
    /**
    * @description Syncs an opportunity with SAP
    * @param OpportunityId
    */
    public static void sync(Id opportunityId) {
        SAPSyncOpportunity.syncFuture(opportunityId);
    }
    
    /**
    * @description Send data to sap in async mode
    * @param OpportunityId
    */
    @future(callout=true)
    private static void syncFuture(Id id){
        List<Opportunity> opps = [SELECT Id, Name, AccountId, Sales_Org__c, SalesProgram__c, Dist_Channel__c, StageName, IsGeneric__c, CloseDate,
                                    (SELECT Id, ContactId,Account__c, OpportunityId, Role FROM OpportunityContactRoles)
                                    FROM Opportunity
                                    WHERE Id = :id];

        if (opps.size() > 0) {
            SAPSyncOpportunity.sendData(opps[0]);
        }
    } // syncFuture

    /**
    * @description Send data to sap in sync mode
    * @param OpportunityId
    */
    public static void syncNow(Set<Id> ids){
        List<Opportunity> oppsList = [SELECT Id, Name, AccountId, SalesProgram__c, Sales_Org__c, Dist_Channel__c, StageName, IsGeneric__c, CloseDate,
                                    (SELECT Id, ContactId,Account__c, OpportunityId, Role FROM OpportunityContactRoles)
                                    FROM Opportunity
                                    WHERE Id IN :ids ];

        if (oppsList.size() > 0) {
            for (Opportunity opp : oppsList) {
                SAPSyncOpportunity.sendData(opp);
            }
        }
    } // syncNow

    /**
    * @description Sends the request to SAP
    * @param Opportunity
    */
    private static void sendData(Opportunity opp) {
        String json = SAPSyncOpportunity.buildJSON(opp);
        SAPWS_Utility.SapResponse response = SAPConnector.connect(null, SAPConnector.OPPORTUNITIES_SERVICE, 'PUT', json);
        //Ignore the error
    } // sendData
    
    /**
    * @description Builds the JSON for the request
    * @param Opportunity
    * @return Serialized JSON
    */
    private static String buildJSON(Opportunity opp) {
       
        Map<String, Object> fields = new Map<String, Object>();        
        fields.put('Name', opp.Name);
        fields.put('Id', opp.Id);
        fields.put('IsClosed', false);
        fields.put('AccountId', opp.AccountId);
        fields.put('SalesOrg', opp.Sales_Org__c);
        fields.put('Channel', opp.Dist_Channel__c);
        fields.put('StageName', opp.StageName);
        fields.put('IsGeneric__c', opp.IsGeneric__c);
        fields.put('CloseDate', opp.CloseDate);
        fields.put('SalesProgram', opp.SalesProgram__c);
        
        Map<String, Object> wrapper = new Map<String, Object>();
        wrapper.put('opportunity', fields); // opp
        wrapper.put('opportunityActorsList', opp.OpportunityContactRoles);
        wrapper.put('language', UserInfo.getLanguage());
        System.debug('JSON OPP TO SAP');
        System.debug(JSON.serialize(wrapper));
        return JSON.serialize(wrapper);
    } // buildJSON
    
} // class