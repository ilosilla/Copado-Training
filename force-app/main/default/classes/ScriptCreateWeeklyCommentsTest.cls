@isTest
public class ScriptCreateWeeklyCommentsTest {

    @isTest
    static void testRunJobOnLastThursday() {
        User u = DatafactoryUser.createUKUser();
        u.Alias = 'ssega';
        update u;

        Account acc = DatafactoryAccount.createAccounts(1)[0];

        // Crear una oportunidad vinculada
        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=System.today().addDays(30),
            OwnerId=u.Id,
            LeadSource='Porsamarket',
            AccountId=acc.Id
        );
        insert opp;

        // Crear Follow__c relacionado con la Account
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Account' LIMIT 1];
        Follow__c fol = new Follow__c(
            Account__c=acc.Id,
            OwnerId=u.Id,
            RecordTypeId=rt.Id
        );
        insert fol;

         // Crear Follow__c relacionado con la Account
         rt = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Opportunity' LIMIT 1];
         fol = new Follow__c(
             Account__c=acc.Id,
             OwnerId=u.Id,
             RecordTypeId=rt.Id
         );
         insert fol;

        Test.startTest();
        ScriptCreateWeeklyComments.runJob();
        Test.stopTest();

        List<AccountAdditionalInfo__c> accInfos = [SELECT Id, InfoType__c FROM AccountAdditionalInfo__c];
        List<OpportunityAdditionalInfo__c> oppInfos = [SELECT Id, InfoType__c FROM OpportunityAdditionalInfo__c];

        System.assert(accInfos.size() > 0, 'Debe haberse creado al menos un registro AccountAdditionalInfo__c');
        System.assert(oppInfos.size() > 0, 'Debe haberse creado al menos un registro OpportunityAdditionalInfo__c');
        System.assertEquals('WEEKLYCOMMENT', accInfos[0].InfoType__c);
        System.assertEquals('WEEKLYCOMMENT', oppInfos[0].InfoType__c);
    }

    @isTest
    static void testExecuteMethod() {
        Test.startTest();
        ScriptCreateWeeklyComments job = new ScriptCreateWeeklyComments();
        String jobId = System.schedule('Test Job', '0 0 23 ? * THU *', job);
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}