@isTest
public class ContactsDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        
        List<Account> accountList =  new List<Account>{
            Account_TestDataFactory.createFabricator(), Account_TestDataFactory.createFabricator(), 
                Account_TestDataFactory.createBusinessAccount(), Account_TestDataFactory.createCustomer()};
        
        accountList[0].Name = 'Account WithOut Contacts';
        accountList[1].Name = 'Account With Contacts';
        accountList[2].Name = 'Dif Account With Contacts';
        
        Account_TestDataFactory.insertAccounts(accountList);
    }
    
    @isTest
    public static void contactCount(){
        Account acc = [SELECT Id, Number_Of_Contacts__c FROM Account WHERE Name = 'Account With Contacts' LIMIT 1];
        
        test.startTest();
        DataFactoryContact.createContacts(acc.Id, 9);
        test.stopTest();
        
        Account accWithContacts = [SELECT Id, Number_Of_Contacts__c FROM Account WHERE Name = 'Account With Contacts'];
        Account accWithOutContacts = [SELECT Id, Number_Of_Contacts__c FROM Account WHERE Name = 'Account WithOut Contacts'];
        System.assertEquals(9, accWithContacts.Number_Of_Contacts__c, 'Contacts not counted OK');
        System.assertEquals(0, accWithOutContacts.Number_Of_Contacts__c, 'Contacts not counted OK');
    }
    
    @isTest
    public static void lastContactDate(){
        Account acc = [SELECT Id, LastContactDateTime__c, Number_Of_Contacts__c,isPersonAccount FROM Account WHERE Name = 'Account WithOut Contacts'];
        Account acc2 = [SELECT Id, LastContactDateTime__c, Number_Of_Contacts__c, isPersonAccount FROM Account WHERE Name = 'Account With Contacts'];
        System.assert(acc.LastContactDateTime__c == null, 'No debe de tener fecha en Last Contact');
        
        Test.startTest();
        DataFactoryContact.createContacts(acc.Id, 2);
        List<Contact> contacts = [SELECT Id,AccountId,Ispersonaccount FROM Contact where isPersonAccount = false LIMIT 1];
        contacts[0].AccountId = acc2.Id;
        update contacts[0];
        Test.stopTest();
        
        new ContactsDomain(contacts);
        
        acc = [SELECT Id, LastContactDateTime__c,Last_Activity_Date__c, Number_Of_Contacts__c FROM Account WHERE Name = 'Account WithOut Contacts'];
        System.assert(acc.LastContactDateTime__c != null, 'No se ha actualizado Last Contact Date');
        System.assert(acc.LastContactDateTime__c.date() == acc.Last_Activity_Date__c.date(), 'Las fechas no son iguales');
        
        acc2 = [SELECT Id, LastContactDateTime__c,Last_Activity_Date__c, Number_Of_Contacts__c, isPersonAccount FROM Account WHERE Name = 'Account With Contacts'];
        System.assert(acc2.LastContactDateTime__c != null, 'No se ha actualizado Last Contact Date');
        System.assert(acc2.LastContactDateTime__c.date() == acc2.Last_Activity_Date__c.date(), 'Las fechas no son iguales');
    }
}