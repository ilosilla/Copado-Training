global class OpportunityReport implements Database.Batchable<sObject>, Database.Stateful{
    
    Map<String, Set<String>> postCodeMap = new Map<String, Set<String>>();
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT OwnerId, Postcode__c FROM Opportunity WHERE OwnerId != NULL AND Postcode__c != NULL' +
                       (Test.isRunningTest() ? ' LIMIT 200' : '');
        
        return Database.getQueryLocator(query);
        
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        
        System.debug(scope.size() + ' records found');
        
        for(Opportunity opp1: scope){
            
            String oppPostCode = opp1.Postcode__c;
            
            if(postCodeMap.keySet().contains(oppPostCode)){
                
                Set<String> ownerSet = postCodeMap.get(oppPostCode);
                
                if(!ownerSet.contains(opp1.OwnerId)){
                    ownerSet.add(opp1.OwnerId);                    
                }
                
            }
            
            else{
                
                postCodeMap.put(oppPostCode, new Set<String>{opp1.OwnerId});
                
            }
            
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        
        // execute any post-processing operations
        for(String postCode: postCodeMap.keySet()){
            
            System.debug('Postcode__c: ' + postCode);
            System.debug(postCodeMap.get(postCode).size() + 'records with different OwnerId');
            
        }
        
    } 
    
}