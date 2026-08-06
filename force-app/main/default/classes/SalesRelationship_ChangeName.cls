global class SalesRelationship_ChangeName implements Database.Batchable<sObject>, Database.Stateful{
	global Boolean status = true;
    global Set<Id> salesRelNotUpdated = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String s = 'Error';
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT CreatedBy.CountryCode, Account_Org__r.Name, Sales_Org__c, Distribution_Channel__c FROM Sales_Relationship__c WHERE Sap_Status__c !=: s'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Sales_Relationship__c> scope) {
        
        for(Sales_Relationship__c salesRel : scope){
            if(salesRel.CreatedBy.CountryCode != null){
                List<String> nameParts = getSalesRelName(salesRel, salesRel.CreatedBy.CountryCode);
                salesRel.Name = nameParts[0] + salesRel.Account_Org__r.Name + ' ' + nameParts[1];
                 
            } else {
                salesRelNotUpdated.add(salesRel.Id);
            }
            
        }
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList = Database.update(scope, dml);
        
        for (Integer i=0; i<scope.size(); i++) {
            
            Database.SaveResult sr = srList[i];
            Sales_Relationship__c salesRel = scope[i];
            
            if (!sr.isSuccess()) {
                
                salesRelNotUpdated.add(salesRel.Id);
                
                System.debug('There was an error trying to update the following Sales Relationship: ' + salesRel.Id);
                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
                
                status = false;
                
            }
            
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
        // execute any post-processing operations
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        
        //Send an email to the User after your batch completes
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'ivan.losilla@porcelanosagrupo.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch Apex Job is done with ID: ' + bc.getJobId());
        
        String plainTextBody = 'Sales Relationship with Errors: \n';
        
        if(!status){
            for(Id idItem: salesRelNotUpdated){
                plainTextBody += idItem + '\n';            
            }
        }
        
        mail.setPlainTextBody(plainTextBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    }
    
    public List<String> getSalesRelName(Sales_Relationship__c newSalesRel, String countryCode){
        String codes = '[' + countryCode + '-' + newSalesRel.Sales_Org__c + '-' + newSalesRel.Distribution_Channel__c + '] ';
        List<Schema.PicklistEntry> salesOrgPicklist = Sales_Relationship__c.Sales_Org__c.getDescribe().getPicklistValues();
        String salesOrgLabel = '';
        
        for(Schema.PicklistEntry pkl : salesOrgPicklist){
            if(pkl.getValue() == newSalesRel.Sales_Org__c){
                salesOrgLabel = pkl.getLabel();
                break;
            }
        }
        
        return new List<String>{codes, salesOrgLabel};
    }
    
}