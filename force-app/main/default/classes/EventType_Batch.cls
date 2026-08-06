global class EventType_Batch implements Database.Batchable<sObject>, Database.Stateful {
	global Boolean status = true;
	global List<Id> eventsNotUpdated = new List<Id>();
    global List<String> eventsErrors = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator(
            'SELECT Id, Type FROM Event'
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Event> scope) {
        
        for(Event e : scope){
            e.EventType__c = e.Type;
        }
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        dml.DuplicateRuleHeader.AllowSave = true;
        List<Database.SaveResult> srList = Database.Update(scope, dml);
        
        for (Integer i=0; i<scope.size(); i++) {
            
            if (!srList[i].isSuccess()){
                
                eventsNotUpdated.add(scope[i].Id);
                
                System.debug('There was an error trying to update the following Account: ' + scope[i].Id);
                
                String error = '';
                for(Database.Error err : srList[i].getErrors()) {
                    error += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                }
                System.debug('The following error has occurred. ' + error);      
                
                eventsErrors.add(error);
                
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
        
        String plainTextBody = 'Events with Errors: ' + eventsNotUpdated.size() +  ' \n';
        
        if(!status){
            for(Integer i=0; i<eventsNotUpdated.size(); i++){
                plainTextBody += eventsNotUpdated[i] + ' -- ' + eventsErrors[i] + '\n';
            }
        }
        
        mail.setPlainTextBody(plainTextBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
    }
}