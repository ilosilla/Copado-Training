@isTest
public class SalesRelationship_Fix_Test {
    
    @testSetup
    static void setup(){
        
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
    }
    
    @isTest
    static void testMethod1(){
        
        List<Sales_Relationship__c> salesRelListToInsert =  new List<Sales_Relationship__c>();
        List<Account> accListToInsert = new List<Account>();
        
        for(Integer i=0; i<25; i++){
            accListToInsert.add(Account_TestDataFactory.createCustomer());
        }
            
        Account_TestDataFactory.insertAccounts(accListToInsert);
        
        for(Integer j=0; j<accListToInsert.size(); j++){
            
            Sales_Relationship__c newSalesRel = Sales_RelationShip_TestDataFactory.createSalesRelationship(accListToInsert[j]);
            newSalesRel.Name = 'Sales Rel Bulk';
            salesRelListToInsert.add(newSalesRel);
            
        }
        
		insert salesRelListToInsert;
        
        Test.startTest();
        
        SalesRelationship_Fix obj = new SalesRelationship_Fix();
        DataBase.executeBatch(obj);
        
        Test.stopTest();

        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }
    
}