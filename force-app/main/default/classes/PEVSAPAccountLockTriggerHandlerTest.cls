@isTest public with sharing class PEVSAPAccountLockTriggerHandlerTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(10);
    } 

    @IsTest
    static void testPEVSAPAccountLockTriggerHandler() {
        SAP_Account_Lock__e[] events = new List<SAP_Account_Lock__e>();
        for (Account acc : [SELECT Id, SAP_Id__c FROM Account]) {
            SAP_Account_Lock__e ev = new SAP_Account_Lock__e();
            ev.AccountId__c = acc.Id;
            ev.SAPId__c = acc.SAP_Id__c;
            ev.IsLocked__c = true;
            events.add(ev);
        }

        // FOrce an error
        Integer i = events.size() - 1;
        events[i].AccountId__c = '123456789012345678';

        Test.startTest();
        EventBus.publish(events);
        Test.stopTest();
        
        Account testAccount = [select Id, Is_Locked__c from Account limit 1 ];
        Assert.isTrue(testAccount.Is_Locked__c,'Account should be locked');
    }

}