/**
* @author Ivan Losilla
* @date September 2022
* @group Scripts
* @description Sends to SAP all Opportunities between two dates of the Accounts with SAPID. Send the Opps to SAP 
* as a new ones, or updates the info if the Opp is already on SAP
* if isTest is true, shows only the info about the Opps that are going to be sent to SAP, but doesn't send anything to SAP.
*/
global class ScriptSendOppsToSAP implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private Boolean isTest = true;
    private Date startDate;
    private Date endDate;
    private Set<String> contextsWithSAP = new Set<String>();
    
    global ScriptSendOppsToSAP(Date startDateParam, date endDateParam, Boolean isTestParam) {
        isTest = isTestParam;
        startDate = startDateParam;
        endDate = endDateParam;

        if (contextsWithSAP.size() == 0) {
            List<Execution_Context__mdt> contextsWithSAPList = [SELECT DeveloperName,ExtendedOpps__c,Has_SAP__c,Id,MasterLabel,OwnerAssignation__c,PriceRequest__c FROM Execution_Context__mdt WHERE Has_SAP__c = true];
            for (Execution_Context__mdt execution : contextsWithSAPList) {
                contextsWithSAP.add(execution.DeveloperName);
            }
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, createddate FROM Opportunity WHERE createddate >= :startDate and createddate <= :endDate and Account.Owner.Execution_Context__c in :contextsWithSAP and Account.sap_id__c <> null';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        System.debug('Opportunities: ' + scope.size());
        Set<Id> oppsIdsSet = new Set<Id>();
        for (Opportunity opp : scope) {
            System.debug(opp);
            oppsIdsSet.add(opp.Id);
        }

        if (isTest == false) {
            System.debug('Sending to SAP');
            SAPSyncOpportunity.syncNow(oppsIdsSet);
        }
        System.debug('Finished');
    }
    
    global void finish(Database.BatchableContext bc){
    }
}