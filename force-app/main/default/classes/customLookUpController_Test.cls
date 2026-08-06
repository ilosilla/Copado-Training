@isTest
public class customLookUpController_Test {
    
    @testSetup
    static void setup(){
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        insert Contact_TestDataFactory.createContacts(5, new List<Map<String, Object>>{
            new Map<String, Object>{'FirstName' => 'Bill', 'LastName' => 'Gates'},
            new Map<String, Object>{'FirstName' => 'Bill', 'LastName' => 'Murray'},
            new Map<String, Object>{'FirstName' => 'Jeff', 'LastName' => 'Bezos'},
            new Map<String, Object>{'FirstName' => 'Martin', 'LastName' => 'Galperin'},
            new Map<String, Object>{'FirstName' => 'Marc', 'LastName' => 'Benioff'}
        });
        
    }
    
    @isTest
    static void fetchLookUpValues_Test(){
        
        String searchKeyWord = 'Bill'; 
        String objectApiName = 'Contact';
        
        List<Contact> contactList = customLookUpController.fetchLookUpValues(searchKeyWord, objectApiName);
        
        System.assertEquals(2, contactList.size());
        
    }
    
    @isTest
    static void fetchLookUpValuesById_Test(){
        
        String firstName = 'Martin';
        String objectApiName = 'Contact';
        
        List<Contact> contactList = [SELECT Id
                                     FROM Contact
                                     WHERE FirstName =: firstName LIMIT 1];
        
        String recordId = contactList[0].Id;
        
        contactList.clear();
        contactList = customLookUpController.fetchLookUpValuesById(recordId, objectApiName);
        
        System.assertEquals(1, contactList.size());
            
    }

}