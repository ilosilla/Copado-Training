/**
* @author Ivan Losilla
* @date September 2022
* @group Scripts
* @description Creates default Sales Rel on the Accounts not sent to SAP between 2 dates
*/
global class ScriptSendAccountsToSAPFusionPart1 implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private Boolean isTest = true;
    private Date startDate;
    private Date endDate;
    private Set<String> contextsWithSAP = new Set<String>();
    private Map<Id,User> ownerUsersMap = new Map<Id,User>();
    private List<Sales_Relationship__c> salesRels = new List<Sales_Relationship__c>();
    private List<String> errorMessages = new List<String>();
    private List<String> successMessages = new List<String>();
    private Integer recordsProcessed = 0;
    private Integer recordsInserted = 0;
    
    global ScriptSendAccountsToSAPFusionPart1(Date startDateParam, date endDateParam, Boolean isTestParam) {
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
        Id tradeRecTypeId = RecordTypeLibrary.Account_TradeCustomer;
        String query = 'SELECT Id,OwnerId FROM Account WHERE createddate >= :startDate and createddate <= :endDate and RecordTypeId <> :tradeRecTypeId and Owner.Execution_Context__c in :contextsWithSAP and sap_id__c = null and Owner.Profile.Name <> \'System Administrator\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        getOwners(scope);
        createDefaultSalesRels(scope);
        
        if (isTest == false) {
            List<Id> salesRelIds = new List<Id>();
            List<Database.UpsertResult> srList = Database.Upsert(this.salesRels, false);
            for (Integer i=0; i<this.salesRels.size(); i++) {
                recordsProcessed += 1;
                if (!srList[i].isSuccess()) {
                    System.debug('There was an error trying to inserting the Sales Rel: ' + this.salesRels[i]);
                    String error = '';
                    for(Database.Error err : srList[i].getErrors()) {
                        error += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    }
                    errorMessages.add(this.salesRels[i].Id + ' : ' + error);
                    System.debug('The following error has occurred. ' + error);      
                } else {
                    successMessages.add('Success : ' + this.salesRels[i].Id);
                    salesRelIds.add(this.salesRels[i].Id);
                    recordsInserted += 1;
                }
            }
        }
        System.debug('Finished');
    }
    
    global void finish(Database.BatchableContext bc){
        this.logSync();
    }

    private void createDefaultSalesRels(List<Account> accs) {
        Set<Id> accsIds = new Set<Id>();
        List<Sales_Relationship__c> salesRelNew = new List<Sales_Relationship__c>();

        for (Account acc : accs) {
            accsIds.add(acc.Id);
        }

        List<Sales_Relationship__c> existingSalesRels = [SELECT Id, Account_Org__c FROM Sales_Relationship__c WHERE Account_Org__c IN : accsIds];
        accsIds = new Set<Id>();
        for (Sales_Relationship__c existingsalesrel : existingSalesRels) {
            accsIds.add(existingsalesrel.Account_Org__c);
        }

        for (Account acc : accs) {
            if (ownerUsersMap.containsKey(acc.OwnerId) && accsIds.contains(acc.Id) == false) {
                Sales_Relationship__c newSalesRel = SalesRelationshipUtils.createDefaultSalesRelations(acc, this.ownerUsersMap.get(acc.OwnerId), 'New Account');
                newSalesRel.sap_status__c = 'Error';
                salesRelNew.add(newSalesRel);
            }
        }
        this.salesRels = salesRelNew;

        System.debug('Sales Relationships: ' + this.salesRels.size());
        for (Sales_Relationship__c salesRel : this.salesRels) {
            System.debug(salesRel);
        }
    }

    private void getOwners(List<Account> accs) {
        Set<Id> accsIdsSet = new Set<Id>();
        for (Account acc : accs) {
            accsIdsSet.add(acc.Id);
        }

        Set<Id> usersId = new Set<Id>();

        for (Account acc : accs) {
            System.debug('Account: ' + acc);
            usersId.add(acc.OwnerId);
        }

        for (User usr : new UsersSelector().selectById(usersId)) {
            this.ownerUsersMap.put(usr.Id, usr);
        }
    }

    private void logSync() {
        String newLine = '\n';
        String text = 'Script default Sales Relations' + newLine;
        text += 'Success: ' + this.recordsInserted + newLine;
        text += 'Processed: ' + this.recordsProcessed + newLine;
        text += 'Succes Messages ********* ' + newLine;
        for (String successMessage : this.successMessages) {
            text += successMessage + newLine;
        }
        text += 'Error Messages ********* ' + newLine;
        for (String errorMessage : this.errorMessages) {
            text += errorMessage + newLine;
        }
        text = text.replaceAll(newLine, '<br/>');
        Mail m = new Mail();
        m.setTo(new List<String>{'ivan.losilla@porcelanosagrupo.com'});
        m.setSubject('Salesforce Script: Default Sales Relations ');
        m.setHtml(text);
        m.send();
    }
}