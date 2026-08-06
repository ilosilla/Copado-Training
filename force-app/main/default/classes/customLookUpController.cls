public class customLookUpController {
    
    @AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String objectApiName){
        
        String searchKey = searchKeyWord + '%';        
        List<sObject> returnList = new List<sObject>();
      
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'SELECT Id, Name FROM ' + objectApiName + ' WHERE Name LIKE: searchKey ORDER BY CreatedDate DESC LIMIT 10';
        system.debug(sQuery);
        List<sObject> lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        
        system.debug(returnList);
        
        return returnList;
        
    }
    
    @AuraEnabled
    public static List<sObject> fetchLookUpValuesById(String recordId, String objectApiName){
               
        List<sObject> returnList = new List<sObject>();
      
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'SELECT Id, Name FROM ' + objectApiName + ' WHERE Id =\'' +  recordId + '\'';
        system.debug(sQuery);
        List<sObject> lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        
        system.debug(returnList);
        
        return returnList;
        
    }
    
}