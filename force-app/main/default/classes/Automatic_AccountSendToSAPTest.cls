@isTest
public class Automatic_AccountSendToSAPTest {
    
    @testSetup 
    static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        //Insert User_TestDataFactory.createUsers(1, new List<String>{'en_US'})[0];
        
        CollaborationGroup collabGroup = new CollaborationGroup(CollaborationType = 'Private', Name = 'test group name');
        Insert collabGroup;
                
        // Setup primer test
        // Account con Sales Rel
        Account acc = Account_TestDataFactory.createRetailer(); acc.Name = 'TestSales_RelationShip';
    	Account acc2 = Account_TestDataFactory.createRetailer(); acc2.Name = 'Test_Sales_Rel_WithError';
        
        System.debug('save Accounts: ' + Account_TestDataFactory.insertAccounts(new List<Account>{acc, acc2}));
        
        Sales_Relationship__c salesRelWithError = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc2);
        //salesRelWithError.Name = 'Test_Sales_Rel_WithError';
        salesRelWithError.Relationship__c = 'Z1';
        
        Insert new List<Sales_Relationship__c>{salesRelWithError, Sales_RelationShip_TestDataFactory.createSalesRelationship(acc)};
            
            List<Account> accListToInsert =  new List<Account>();
        List<Sales_Relationship__c> salesRelListToInsert =  new List<Sales_Relationship__c>();
        // Setup Segundo
        Integer chunckSize = 2;
        for(Integer i = 0; i<chunckSize; i++){
            Account accCust = Account_TestDataFactory.createRetailer();
            accCust.Name = i > (chunckSize / 2) ? 'Sales Rel Bulk' : 'Sales Rel Bulk Error';
            accListToInsert.add(accCust);
        }
            
        Account_TestDataFactory.insertAccounts(accListToInsert);
        
        for(Integer j = 0; j< accListToInsert.size()/2; j++){
            Sales_Relationship__c newSalesRel = Sales_RelationShip_TestDataFactory.createSalesRelationship(accListToInsert[j]);
            //newSalesRel.Name = 'Sales Rel Bulk';
            salesRelListToInsert.add(newSalesRel);
        }
        
        for(Integer j = accListToInsert.size()/2; j< accListToInsert.size(); j++){
            Sales_Relationship__c newSalesRel = Sales_RelationShip_TestDataFactory.createSalesRelationship(accListToInsert[j]);
            //newSalesRel.Name = 'Sales Rel Bulk Error';
            newSalesRel.Relationship__c = 'Z1';
            salesRelListToInsert.add(newSalesRel);
        }
        
        Insert salesRelListToInsert;
    }
    
    @isTest 
    public static void test_SendToSAP(){
    	Sales_Relationship__c salesRelSuccess = [SELECT Id FROM Sales_Relationship__c WHERE Account_Org__r.Name = 'TestSales_RelationShip'];
        Sales_Relationship__c salesRelWithError = [SELECT Id, Relationship__c FROM Sales_Relationship__c WHERE Account_Org__r.Name = 'Test_Sales_Rel_WithError'];
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        	Automatic_AccountSendToSAP.SendToSAP_Future(new List<Id>{salesRelSuccess.Id, salesRelWithError.Id});
        	//System.assertEquals(1, Limits.getEmailInvocations() );
        Test.stopTest();
        
        salesRelSuccess = [SELECT Sap_Status__c, Error_Message__c, Account_Org__c FROM Sales_Relationship__c WHERE Account_Org__r.Name = 'TestSales_RelationShip'];
        salesRelWithError = [SELECT Sap_Status__c, Error_Message__c, Account_Org__c FROM Sales_Relationship__c WHERE Account_Org__r.Name = 'Test_Sales_Rel_WithError'];
        
        System.debug('salesRelSuccess: ' + salesRelSuccess);
        System.debug('salesRelWithError: ' + salesRelWithError);
        
        Account acc1 = [SELECT Sap_Id__c FROM Account WHERE Id =: salesRelSuccess.Account_Org__c];
        Account acc2 = [SELECT Sap_Id__c FROM Account WHERE Id =: salesRelWithError.Account_Org__c];
        
        System.debug('acc1: ' + acc1);
        System.debug('acc2: ' + acc2);
        
        System.assertEquals('Success', salesRelSuccess.Sap_Status__c);
        System.assertEquals('Error', salesRelWithError.Sap_Status__c);
        System.assert(salesRelWithError.Error_Message__c.contains('Relationship es un campo requerido'));
               
    }
    
    @isTest 
    public static void test_ManageSendToSAP(){
        List<Sales_Relationship__c> salesRelList = [SELECT Id FROM Sales_Relationship__c WHERE Account_Org__r.Name Like 'Sales Rel Bulk%'];
        List<Id> salesRelIDs = new List<Id>();
        
        System.debug('Test SIZE: ' + salesRelList.size());
        
        for(Sales_Relationship__c salesRel : salesRelList){
            salesRelIDs.add(salesRel.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        	Automatic_AccountSendToSAP.ManageSendToSap(salesRelIDs);
        	//System.assertEquals(salesRelList.size()/2, Limits.getEmailInvocations() );
        Test.stopTest();
        
        Integer successCount = [SElECT Count() FROM Sales_Relationship__c 
                                                    WHERE Sap_Status__c = 'Success' AND Account_Org__r.Sap_ID__c != null];
        
        Integer errorCount = [SElECT Count() FROM Sales_Relationship__c 
                                                    WHERE Sap_Status__c = 'Error' AND Account_Org__r.Sap_ID__c = null];
        
        System.debug('successCount: ' + successCount);
        System.debug('errorCount: ' + errorCount);
        
        System.assertEquals(salesRelList.size()/2, successCount);
        System.assertEquals(salesRelList.size()/2, errorCount);
        
    }
}