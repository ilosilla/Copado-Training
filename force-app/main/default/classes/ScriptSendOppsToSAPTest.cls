@isTest
public with sharing class ScriptSendOppsToSAPTest {
    
    @isTest
    public static void testScript() {
        User usr = DataFactoryUser.createUKUser();
        usr.Execution_context__c = 'GB';
        update usr;

        List<Account> acc = DataFactoryAccount.createPersonAccounts(1);
        acc[0].sap_id__c = '0001111111';
        acc[0].OwnerId = usr.Id; 
        update acc[0];

        List<Opportunity> opps = new List<Opportunity>();
        System.runAs(usr) {
            opps = DataFactoryOpportunity.createRetailOpportunities(new List<Account>{acc[0]}, 1);
        }

        Test.startTest();
            Date startDate = date.today().addDays(-6);
            Date endDate = date.today().addDays(+1);
            Database.executeBatch(new ScriptSendOppsToSAP(startDate,endDate,false));
        Test.stopTest();

        System.assert(opps.size() > 0, 'There are no Opportunities to update');
    }
}