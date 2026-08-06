global class SalesRelationship_Fix implements Database.Batchable<sObject>, Database.Stateful{
    
    global Boolean status = true;
    global Set<Id> salesRelNotDeleted = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Account_Org__c, Sales_Org__c, Distribution_Channel__c, Custom_Id__c, CreatedDate' +
            ' FROM Sales_Relationship__c'
        );
        
    }
    
    global void execute(Database.BatchableContext bc, List<Sales_Relationship__c> scope) {
        
        // Fill Custom_Id__c field
        for(Sales_Relationship__c salesRelationship: scope){
            
            salesRelationship.Custom_Id__c = salesRelationship.Account_Org__c + '-' + salesRelationship.Sales_Org__c + '-' + salesRelationship.Distribution_Channel__c;        
        
        }
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList = Database.update(scope, dml);
        
        for (Integer i=0; i<scope.size(); i++) {
            
            Database.SaveResult sr = srList[i];
            Sales_Relationship__c salesRel = scope[i];
            
            if (!sr.isSuccess()) {
                
                System.debug('There was an error trying to update the following Sales Relationship: ' + salesRel.Id);
                
                // Update failed due to duplicate detected
                for(Database.Error duplicateError : sr.getErrors()){
                    
                    Datacloud.DuplicateResult duplicateResult = ((Database.DuplicateError)duplicateError).getDuplicateResult();                
                    System.debug('Duplicate records have been detected by ' + duplicateResult.getDuplicateRule());
                    System.debug(duplicateResult.getErrorMessage());
                    
                }
                
                status = false;
                
            }
            
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
        // execute any post-processing operations
        
        if(status){
            
            List<Sales_Relationship__c> scope = [SELECT Id, Custom_Id__c, CreatedDate FROM Sales_Relationship__c];        
            Set<Id> salesRelSetToDelete = new Set<Id>();
            
            for(Integer i=0; i<scope.size(); i++){
                
                for(Integer j=0; j<scope.size(); j++){
                    
                    if(scope[i].Custom_Id__c == scope[j].Custom_Id__c && i != j ){
                        
                        if(scope[i].CreatedDate < scope[j].CreatedDate){
                            
                            salesRelSetToDelete.add(scope[j].Id);
                            
                            
                        } else {
                            
                            salesRelSetToDelete.add(scope[i].Id);
                            
                        }
                        
                    }
                    
                }
                
            }
            
            List<Sales_Relationship__c> salesRelListToDelete = [SELECT Id FROM Sales_Relationship__c WHERE Id IN :salesRelSetToDelete];
            List<Database.DeleteResult> drList = Database.delete(salesRelListToDelete);
            
            for(Database.DeleteResult dr : drList) {
                
                if (dr.isSuccess()) {
                    
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted account with ID: ' + dr.getId());
                    
                } else {
                    
                    System.debug('There was an error trying to delete the following Sales Relationship: ' + dr.getId());
                    salesRelNotDeleted.add(dr.getId());
                    
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                                                
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        
                    }
                    
                }
                
            }
            
            /*for(Integer i=0; i<salesRelListToDelete.size(); i++){

				Database.DeleteResult dr = drList[i];
				Sales_Relationship__c salesRel = salesRelListToDelete[i];

				if (!dr.isSuccess()) {

					System.debug('There was an error trying to delete the following Sales Relationship: ' + salesRel.Id);

					for(Database.Error err : dr.getErrors()) {
						System.debug('The following error has occurred.');                    
						System.debug(err.getStatusCode() + ': ' + err.getMessage());
						System.debug('Sales Relationship fields that affected this error: ' + err.getFields());
					}

				}

			}*/
            
        }
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        
        //Send an email to the User after your batch completes
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'julian.besso@neoris.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch Apex Job is done');       
        
        String plainTextBody = 'Sales Relationship with Errors: \n';
        
        for(Id idItem: salesRelNotDeleted){            
			plainTextBody += idItem + '\n';            
        }
        
        mail.setPlainTextBody(plainTextBody);        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    } 

}