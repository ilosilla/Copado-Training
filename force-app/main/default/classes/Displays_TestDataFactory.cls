@isTest
public class Displays_TestDataFactory {
    public static List<Displays_Marketing_Material__c> createDisplays(Integer numRecords, List<Map<String, Object>> fieldsToAdd){
        
        List<Displays_Marketing_Material__c> displaysList = new List<Displays_Marketing_Material__c>();
        
        for(Integer i=0; i<numRecords; i++){
            
            Displays_Marketing_Material__c display = new Displays_Marketing_Material__c(Name = 'TestDisplay' + i, Type__c = 'Kitchen');
            
            for(String fieldName: fieldsToAdd[i].keySet()){
                
                display.put(fieldName, fieldsToAdd[i].get(fieldName));
                
            }
            
            displaysList.add(display);
            
        }
        
        return displaysList;
        
    }
}