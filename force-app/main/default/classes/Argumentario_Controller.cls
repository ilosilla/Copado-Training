public class Argumentario_Controller {
    
    @AuraEnabled
    public static Opportunity getOpportunity(String recordId){
        
        return [SELECT Account.Name, Account.PersonEmail, Account.ShippingAddress, Order__c, Close_Mode__c, StageName
                FROM Opportunity
                WHERE Id = :recordId];
        
    }
    
    @AuraEnabled
    public static void saveOpportunity(String recordId, String jsonObject, String jsonAccount){

        Opportunity opp = [SELECT Account.Name, Account.PersonEmail, Order__c, AccountId
                		   FROM Opportunity
                		   WHERE Id = :recordId];
        Account acc = [SELECT Professional__c FROM Account WHERE ID =: opp.AccountId];
        
        Map<String, Object> request = (Map<String, Object>) JSON.deserializeUntyped(jsonObject);
        Map<String, Object> requestAccount = (Map<String, Object>) JSON.deserializeUntyped(jsonAccount);
        
        for(String key: request.keySet()){
            system.debug('Opportunity field: '+ key +' - ' + request.get(key));
            switch on key{
                when 'Start_Project_Date__c', 'End_Project_Date__c' {
                    Date d = Date.valueOf((string) request.get(key));
                    opp.put(key, datetime.newInstance(d.year(), d.month(),d.day()));
                    
                }
                when else {
            		opp.put(key, request.get(key));
                }
            }
        }
        
        for(String key: requestAccount.keySet()){
            system.debug('Account field: '+ key +' - ' + requestAccount.get(key));
            acc.put(key, requestAccount.get(key));
        }
       
        if(!requestAccount.isEmpty()){
        	update acc;    
        }
        if(!request.isEmpty()){
        	update opp;
        }
        
    }

}