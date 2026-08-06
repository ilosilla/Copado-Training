@isTest
public class OpportunityDefaultValuesController_Test {
    @testSetup static void setup(){
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        System.debug([SELECT Id, Name FROM Profile]);
        Id retailId = [SELECT Id FROM Profile WHERE Name='Standard Retail'].Id;
        Id tradeId = [SELECT Id FROM Profile WHERE Name='Standard Trade'].Id;
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'LocaleSidKey' => 'en_GB'};
            
            List<User> userList = User_TestDataFactory.createUsers(2, fieldsToAdd);
        userList[0].ProfileId = retailId;
        userList[1].ProfileId = tradeId;
        
        Insert userList;
    }
    
    
    @isTest
    public static void test_getDefaultRecordType(){
        User retailUser = [SELECT Name, Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name = 'Standard Retail'];
        User tradeUser = [SELECT Name, Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name = 'Standard Trade'];
        
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>([SELECT Id, DeveloperName FROM RecordType]);
        
        System.runAs(retailUser){
            System.assertEquals('Project_retail', recordTypeMap.get(OpportunityDefaultValues_Controller.getDefaultRecordType()).DeveloperName );
            
        }
        
        System.runAs(tradeUser){
            System.assertEquals('Project_trade', recordTypeMap.get(OpportunityDefaultValues_Controller.getDefaultRecordType()).DeveloperName );
            
        }
        
    }
}