@isTest
public class DisplaysMarketingMaterialsDomainTest {
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(3);
    }

    @isTest
    public static void checkAccountActivity(){
        Account acc = [SELECT Id, Last_Activity_Date__c FROM Account LIMIT 1];
        acc.Last_Activity_Date__c = acc.Last_Activity_Date__c.addDays(-8);
        DateTime beforeDate = acc.Last_Activity_Date__c;
        update acc;
        acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: acc.Id];
        
        Test.startTest();
        Displays_Marketing_Material__c display = new Displays_Marketing_Material__c(Account__c = acc.Id, Type__c = 'Settings');
        insert display;
        Test.stopTest();
        
        new DisplaysMarketingMaterialsDomain(new List<Displays_Marketing_Material__c>{display});
        
        acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: acc.Id];
        System.assert(acc.Last_Activity_Date__c != beforeDate);
    }
    
}