/**
* @author Juan Manuel Martinez - Modificado para test deployment Ramón
*/

@isTest private class Argumentario_ControllerTest {
    
    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers(); 
        
        // Create common test opportunities and accounts
        Account acc = Account_TestDataFactory.createCustomer();
        acc.ShippingStreet = 'Test Shipping Street';
        insert acc;
        //Order ord = new Order(AccountId = acc.Id, Status = 'Draft', EffectiveDate = Date.today());
        //Insert ord;
        
        // User testUser = User_TestDataFactory.createUsers(1, new List<String> {'en_US'})[0];
        // insert testUser;
        
        Opportunity opp = Opportunity_TestDataFactory.createEcommerce(acc);
        //opp.Order__c = ord.Id;
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        // System.runAs(testUser){
            insert opp;
        // }
        Test.stopTest();
    }
    
    // This is a test method for getOpportunity
    @isTest static void test_getOpportunity(){
        Opportunity expectedResponse = [SELECT ID, Account.Name, Account.PersonEmail, Order__c, Close_Mode__c, StageName FROM Opportunity WHERE 
                                        Account.LastName = 'TestAcctCustomer1' LIMIT 1];
        Opportunity actualResponse = Argumentario_Controller.getOpportunity(expectedResponse.Id);
        
        //System.assertEquals(System.hashCode(expectedResponse), System.hashCode(actualResponse));
        System.assertEquals(expectedResponse.Id, actualResponse.Id);
        System.assertEquals(expectedResponse.Account.Name, actualResponse.Account.Name);
        System.assertEquals(expectedResponse.Account.PersonEmail, actualResponse.Account.PersonEmail);
        System.assertEquals(expectedResponse.Order__c, actualResponse.Order__c);
        System.assertEquals(expectedResponse.Close_Mode__c, actualResponse.Close_Mode__c);
        System.assertEquals(expectedResponse.StageName, actualResponse.StageName);
        
    }
    
    // This is a test method for saveOpportunity
    @isTest static void test_saveOpportunity(){
        Opportunity opp = [SELECT ID, Name, Account.LastName, AccountId, Close_Mode__c, StageName, Start_Project_Date__c, RecordType.Name
                           FROM Opportunity WHERE Account.LastName = 'TestAcctCustomer1'];
        System.debug('Record Type: ' + opp.RecordType.Name);
        Map<String, Object> opportunityMap = new Map<String, Object>();
        
        opportunityMap.put('Name', 'updatedOppName');
        opportunityMap.put('Close_Mode__c', 'More samples');
        opportunityMap.put('StageName', 'Pending');
        //opportunityMap.put('Start_Project_Date__c', Date.today().addDays(1));
        
        Map<String, Object> accountMap = new Map<String, Object>();
        accountMap.put('LastName', 'updatedLastName');
        
        String jsonStringOpp = JSON.serialize(opportunityMap);
        String jsonStringAccount = JSON.serialize(accountMap);
        
        System.debug('jsonStringOpp: ' + jsonStringOpp);
        System.debug('jsonStringAccount: ' + jsonStringAccount);
        
        Argumentario_Controller.saveOpportunity(opp.id, jsonStringOpp, jsonStringAccount);
        
        Opportunity actualResult = [SELECT Name, Account.LastName, Close_Mode__c, StageName, Start_Project_Date__c, RecordType.Name 
                                        FROM Opportunity WHERE Id =: opp.Id];
        
        System.debug('Record Type: ' + actualResult.RecordType.Name);
        
        System.assertEquals(opportunityMap.get('Name'), actualResult.Name);
        System.assertEquals(opportunityMap.get('Close_Mode__c'), actualResult.Close_Mode__c);
        System.assertEquals(opportunityMap.get('StageName'), actualResult.StageName);
        //System.assertEquals(actualResult.Start_Project_Date__c, opportunityMap.get('Start_Project_Date__c'));
        //System.assertEquals(accountMap.get('LastName'), actualResult.Account.LastName);
    }
}