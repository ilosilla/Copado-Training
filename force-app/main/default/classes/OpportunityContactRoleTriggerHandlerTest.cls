@isTest 
public class OpportunityContactRoleTriggerHandlerTest {
    
    @testSetup static void setup(){
        TestUtils.enableTriggers();
        List<Account> listAccs = new List<Account>();
        Account accCustomer = Account_TestDataFactory.createCustomer();
        listAccs.add(accCustomer);
        Account accBussiness = Account_TestDataFactory.createBusinessAccount();
        listAccs.add(accBussiness);
        Insert listAccs;

        List<Contact> contList = Contact_TestDataFactory.createContacts(1, new List<Map<String, Object>>{
            new Map<String, Object>{'AccountId' => listAccs[1].Id}
        });
        Insert contList;
         
        Map<String, Object> fieldsToAdd = new Map<String, Object>();
        fieldsToAdd.put('Sales_Org__c', OrganizationCommons.ORG_AZURCERAMIQUE);
        fieldsToAdd.put('Dist_Channel__c', '10');
        fieldsToAdd.put('AccountId', accCustomer.Id);
        
        Opportunity opp1 = Opportunity_TestDataFactory.createOpportunities(1, fieldsToAdd)[0];
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        insert opp1;
        Test.stopTest();

    }

    @isTest public static void updateActivity(){
        Opportunity opp = [SELECT Id, AccountId, Last_Activity_Date__c FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id, Last_Activity_Date__c, PersonContactId FROM Account WHERE Id =: opp.AccountId];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
        
        opp.Last_Activity_Date__c.addDays(-8);
        acc.Last_Activity_Date__c.addDays(-8);
        DateTime beforeDate = acc.Last_Activity_Date__c;
        update opp;
        update acc;
        
        Test.startTest();
        OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = cont.Id);
        insert oppActor1;
        oppActor1.IsPrimary = true;
        update oppActor1;
        Test.stopTest();
        
        opp = [SELECT Id, AccountId, Last_Activity_Date__c FROM Opportunity WHERE Id =: opp.Id];
        acc = [SELECT Id, Last_Activity_Date__c, PersonContactId FROM Account WHERE Id =: acc.Id];
        System.assert(opp.Last_Activity_Date__c != beforeDate, 'No ha cambiado el Last Activity de la Opp');
        System.assert(acc.Last_Activity_Date__c != beforeDate, 'No ha cambiado el Last Activity del Account');
        System.assert(acc.Last_Activity_Date__c.date() == opp.Last_Activity_Date__c.date(), 'No son iguales el Last Activity del Opp y del Account');
    }
    
    @isTest public static void insertActor(){
        
        // Test 1: Success after Insert.
        Opportunity opp1 = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account privateAccount = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true];
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
            
            // Actor con la misma cuenta que la opportunity
            OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = privateAccount.PersonContactId);
            // Actor con distinta cuenta que la opportunity
            OpportunityContactRole oppActor2 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = cont.Id);
            
            Database.SaveResult result_test_1;
            Database.SaveResult result_test_2;
            Database.SaveResult result_test_3;
            Database.SaveResult result_test_4;
            
            Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
            Test.startTest();
            	// Chechea que los inserts y updates se hayan hecho correctamente.
            	result_test_1 = Database.insert(oppActor1, false);
            	result_test_2 = Database.insert(oppActor2, false);
            	System.assert( result_test_1.isSuccess(), 'No se ha podido insertar el Actor 1' );
            	System.assert( result_test_2.isSuccess(), 'No se ha podido insertar el Actor 2' );
            	
            	result_test_3 = Database.update(oppActor1, false);
            	result_test_4 = Database.update(oppActor2, false);
            	System.assert( result_test_3.isSuccess(), 'No se ha podido actualizar el Actor 1' );
            	System.assert( result_test_4.isSuccess(), 'No se ha podido actualizar el Actor 2' );
            Test.stopTest();
            
            // Query para poder ver el cambio del valor de SAP_Status__c
            // Los actores con misma cuenta que la opportunity deberian ser dos. Uno automatico generado en el after insert de opportunity y el otro "oppActor1"
            oppActor2 =  [SELECT SAPStatus__c FROM OpportunityContactRole WHERE OpportunityId =: opp1.Id AND ContactId =: cont.Id];
            
            System.assertEquals('Success', oppActor2.SAPStatus__c);
    }

    @isTest public static void deleteActor(){
        
        // Test 1: Success after Insert.
        Opportunity opp1 = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account privateAccount = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true];
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
        
        Test.startTest();
        // Actor con la misma cuenta que la opportunity
        OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = privateAccount.PersonContactId);
        insert oppActor1;

        delete oppActor1;
        Test.stopTest();

        List<OpportunityContactRole> aux = [SELECT Id FROM OpportunityContactRole];
        System.assert(aux.size() == 0, 'No se ha eliminado el Opp Contact Role');
    }
}