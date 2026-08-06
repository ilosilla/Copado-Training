@isTest
public class SalesRelationship_ChangeName_Test {
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
            
            salesRelListToInsert.add(Sales_RelationShip_TestDataFactory.createSalesRelationship(accListToInsert[j]));
            
        }
        
        insert salesRelListToInsert;
        
        for(Integer j=0; j<salesRelListToInsert.size(); j++){
            salesRelListToInsert[j].Name = '';
            
        }
        
        Update salesRelListToInsert;
        
        Test.startTest();
        
        SalesRelationship_ChangeName obj = new SalesRelationship_ChangeName();
        DataBase.executeBatch(obj);
        
        Test.stopTest();
		
        List<Sales_Relationship__c> salesRelList = [SELECT Name, Account_Org__r.Name FROM Sales_Relationship__c];
        
        for(Integer k=0; k<salesRelList.size(); k++){
            System.assert(salesRelList[k].Name != null);
            // System.assert(salesRelList[k].Name.contains(salesRelList[k].Account_Org__r.Name));
            System.debug('salesRelList[k].Name: ' + salesRelList[k].Name);
        }
		        
    }
}