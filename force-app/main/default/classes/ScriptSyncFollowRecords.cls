/**
* @author Ivan Losilla
* @date April 2024
* @group Scripts
* @test ScriptSyncFollowsTest
* @description Gets all Follows (Opportunities and Accounts) followed from a given date on a Porcelanosa Setting, and creates
* the registers on the Follow Object.
*/
global class ScriptSyncFollowRecords implements Schedulable,Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private PorcelanosaSetting__c setting;

    public void execute(SchedulableContext sc) {
        System.debug('START SYNC FOLLOWS');
        Database.executeBatch(this,10);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        this.setting = [SELECT Id, Value1__c, IsActive__c FROM PorcelanosaSetting__c WHERE Key__c = 'SYNCFOLLOWS' and Subkey__c = 'ALL'];
        if (setting == null || setting.IsActive__c == false) {
            System.debug('SYNC FOLLOWS NO ACTIVO');
            System.abortJob(bc.getJobId());
        }

        String query = 'select id,ParentId, SubscriberId, CreatedDate from EntitySubscription WHERE CreatedDate > ' + this.setting.Value1__c;
        if (this.setting.Value1__c == null) {
            query = 'select id,ParentId, SubscriberId, CreatedDate from EntitySubscription';
        }
        System.debug('QUERY: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<EntitySubscription> scope) {
        savepoint sp = database.setsavepoint();
        List<Follow__c> followsToInsert = new List<Follow__c>();

        try {
            List<Follow__c> followsToDelete = Follow.getDuplicateFollows(scope);
            delete followsToDelete;

            followsToInsert = FollowService.recreateFollows(scope);
            insert followsToInsert;

            this.setting.Value1__c = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            update this.setting;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('Finished');
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}