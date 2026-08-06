global class ContactNumber_Batch implements Database.Batchable<sObject>, Database.Stateful {
	global Boolean status = true;
	global List<Id> accsNotUpdated = new List<Id>();
    global List<String> accsErrors = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id FROM Account WHERE IsPersonAccount = false'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        
        Set<Id> IdSet = new Set<Id>();
        for(Account acc : scope){
            IdSet.add(acc.Id);
        }
        
        List<AggregateResult> aggResults = [SELECT Count(Id) c, AccountId accId FROM Contact WHERE AccountId IN: IdSet GROUP BY AccountId];
        
        for(Account acc : scope){
            Boolean found = false;
            
            for(AggregateResult aggR : aggResults){
                Id accId = (ID) aggR.get('accId');
                
                if(acc.Id == accId){
                    acc.Number_Of_Contacts__c = (Double) aggR.get('c');
                    found = true;
                    break;
                }
            }
            
            if(!found){
                acc.Number_Of_Contacts__c = 0;
            }
            
        }
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList = Database.Update(scope, dml);
        
        for (Integer i=0; i<scope.size(); i++) {
            
            if (!srList[i].isSuccess()) {
                
                accsNotUpdated.add(scope[i].Id);
                
                System.debug('There was an error trying to update the following Account: ' + scope[i].Id);
                
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                }
                System.debug('The following error has occurred. ' + error);      
                
                accsErrors.add(error);
                
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
        
        String plainTextBody = 'Accounts with Errors: ' + accsNotUpdated.size() +  ' \n';
        
        if(!status){
            for(Integer i=0; i<accsNotUpdated.size(); i++){
                plainTextBody += accsNotUpdated[i] + ' -- ' + accsErrors[i] + '\n';
            }
        }
        
        mail.setPlainTextBody(plainTextBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    }
}