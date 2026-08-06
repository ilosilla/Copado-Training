@isTest
public with sharing class ScriptSendAccountsToSAPFusionTest {
    @isTest
    public static void testPart1() {
        List<Account> accountsList = DataFactoryAccount.createPersonAccounts(4);
        User usr = DataFactoryUser.createUKUser();
        usr.Execution_context__c = 'GB';
        update usr;

        for (Account acc : accountsList) {
            acc.OwnerId = usr.Id;
        }
        update accountsList;

        List<Sales_Relationship__c> salesRelsList = [SELECT id FROM Sales_Relationship__c];
        System.assert(salesRelsList.size() == 0, 'Sales Relations have been created');
        
        Test.starttest();
        Date startDate = date.today().addDays(-6);
        Date endDate = date.today().addDays(+1);
        Database.executeBatch(new ScriptSendAccountsToSAPFusionPart1(startDate,endDate,false));
        Test.stoptest();
        
        salesRelsList = [SELECT id FROM Sales_Relationship__c];
        System.assert(salesRelsList.size() > 0, 'There are no Sales Relations created');
    }

    @isTest
    public static void testPart2() {
        User usr = DataFactoryUser.createUKUser();
        usr.Execution_context__c = 'GB';
        update usr;

        System.runAs(usr){
            List<Account> accountsList = DataFactoryAccount.createPersonAccounts(4);
        }

        List<Sales_Relationship__c> salesRelsList = [SELECT id FROM Sales_Relationship__c];
        System.assert(salesRelsList.size() > 0, 'Sales Relations have not been created');
        
        Test.starttest();
            Database.executeBatch(new ScriptSendAccountsToSAPFusionPart2(false),5);
        Test.stoptest();
        
        salesRelsList = [SELECT id FROM Sales_Relationship__c];
        System.assert(salesRelsList.size() > 0, 'There are no Sales Relations created');
    }
}