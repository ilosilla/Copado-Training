@isTest
public class ContactNumber_Batch_Test {

    @testSetup
    static void setup(){
        
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_DeactivatedTriggers();
        
        List<Account> accountList =  new List<Account>();
        
        for(Integer i=0; i<20; i++){
            Account newAccount = Account_TestDataFactory.createFabricator();
            newAccount.Name = i < 10 ? 'Acc With Contact' : 'Acc No Contact';
            accountList.add(newAccount);
            
        }
            
            Account_TestDataFactory.insertAccounts(accountList);
        
        for(Account acc : accountList){
            acc.Number_Of_Contacts__c = null;
        }
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        
        List<Database.SaveResult> srList = Database.Update(accountList, dml);
        
        List<Contact> contactList = new List<Contact>();
        
        for(Integer j=0; j<accountList.size()/2; j++){
            Map<String, Object> newMap = new Map<String, Object>{'AccountId' => accountList[j].Id};
                contactList.addAll(Contact_TestDataFactory.createContacts(1, new List<Map<String, Object>>{newMap}));
        }
            
        Insert contactList;
        
    }
    
    @isTest
    public static void test(){
        
        //System.assertEquals(10, [SELECT Count() FROM Account WHERE Number_Of_Contacts__c = 0] );
        //System.assertEquals(10, [SELECT Count() FROM Account WHERE Number_Of_Contacts__c = 1] );
        
        Test.startTest();
        
        ContactNumber_Batch obj = new ContactNumber_Batch();
        DataBase.executeBatch(obj);
        
        Test.stopTest();
        
        System.assertEquals(10, [SELECT Count() FROM Account WHERE Number_Of_Contacts__c = 0] );
        System.assertEquals(10, [SELECT Count() FROM Account WHERE Number_Of_Contacts__c = 1] );
    }
    
}