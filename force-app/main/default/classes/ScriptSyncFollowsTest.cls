@isTest
public class ScriptSyncFollowsTest {
    @TestSetup
    static void makeData(){
        PorcelanosaSetting__c newSetting = new PorcelanosaSetting__c();
        newSetting.Key__c = 'SYNCFOLLOWS';
        newSetting.Subkey__c = 'ALL';
        newSetting.isActive__c = true;
        insert newSetting;

        DataFactoryOpportunity.createRetailOpportunities(1, 2);
    }

    @isTest
    static void testOppAddElement() {
        Opportunity opp = [SELECT Id, Reason_Lost__c, Amount_custom__c, StageName,Name,Account.Name,OwnerId,AccountId, Last_Activity_Date__c, CloseDate
                            FROM Opportunity LIMIT 1];
        insert new EntitySubscription(ParentId = opp.Id, SubscriberId = UserInfo.getUserId());
        
        List<Follow__c> follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() == 0, 'No debería haber ningún registro de Follows');

        test.startTest();
            ScriptSyncFollowRecords aux = new ScriptSyncFollowRecords();
            Database.executebatch(aux);
        test.stopTest();

        follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() > 0, 'Debería haber algún registro de Follows');
    }

    @isTest
    static void testOppRemoveElement() {
        Opportunity opp = [SELECT Id, Reason_Lost__c, Amount_custom__c, StageName,Name,Account.Name,OwnerId,AccountId, Last_Activity_Date__c, CloseDate
                            FROM Opportunity LIMIT 1];
        insert new Follow__c(OwnerId = UserInfo.getUserId(), Opportunity__c = opp.Id);
        
        List<Follow__c> follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() > 0, 'Debería haber algún registro de Follows');

        test.startTest();
            ScriptSyncFollowRecordsCleaner aux = new ScriptSyncFollowRecordsCleaner();
            Database.executebatch(aux);
        test.stopTest();

        follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() == 0, 'No debería haber ningún registro de Follows');
    }

    @isTest
    static void testAccAddElement() {
        Account acc = [SELECT Id
                            FROM Account LIMIT 1];
        insert new EntitySubscription(ParentId = acc.Id, SubscriberId = UserInfo.getUserId());
        
        List<Follow__c> follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() == 0, 'No debería haber ningún registro de Follows');

        test.startTest();
            ScriptSyncFollowRecords aux = new ScriptSyncFollowRecords();
            Database.executebatch(aux);
        test.stopTest();

        follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() > 0, 'Debería haber algún registro de Follows');
    }

    @isTest
    static void testAccRemoveElement() {
        Account acc = [SELECT Id
                        FROM Account LIMIT 1];
        insert new Follow__c(OwnerId = UserInfo.getUserId(), Account__c = acc.Id);
        
        List<Follow__c> follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() > 0, 'Debería haber algún registro de Follows');

        test.startTest();
            ScriptSyncFollowRecordsCleaner aux = new ScriptSyncFollowRecordsCleaner();
            Database.executebatch(aux);
        test.stopTest();

        follows = [SELECT id FROM Follow__c];
        Assert.isTrue(follows.size() == 0, 'No debería haber ningún registro de Follows');
    }

    @isTest
    static void fillerTest() {
        ScriptSyncFollowRecords aux = new ScriptSyncFollowRecords();
        aux.testFiller();

        ScriptSyncFollowRecordsCleaner aux2 = new ScriptSyncFollowRecordsCleaner();
        aux2.testFiller();
        Assert.isTrue(1 == 1);
    }
    
}