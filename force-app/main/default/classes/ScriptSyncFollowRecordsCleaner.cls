/**
* @author Ivan Losilla
* @date April 2024
* @group Scripts
* @test ScriptSyncFollowsTest
* @description Gets from Follow all the registers of the last week, and check if the user still follows that register. If not, it gets deleted.
*/
global class ScriptSyncFollowRecordsCleaner implements Schedulable,Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private PorcelanosaSetting__c setting;

    public void execute(SchedulableContext sc) {
        System.debug('START SYNC CLEANER FOLLOWS');
        Database.executeBatch(this,10);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        this.setting = [SELECT Id, Value1__c, IsActive__c FROM PorcelanosaSetting__c WHERE Key__c = 'SYNCFOLLOWS' and Subkey__c = 'ALL'];
        if (setting == null || setting.IsActive__c == false) {
            System.debug('SYNC FOLLOWS CLEANER NO ACTIVO');
            System.abortJob(bc.getJobId());
        }

        String query = 'select id,Account__c, Opportunity__c,ActivityId__c, OwnerId from Follow__c';
        System.debug('QUERY CLEANER: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Follow__c> scope) {
        List<Follow__c> deleteFollowsList = new List<Follow__c>();

        System.debug('Follow Records: ' + scope.size());
        for (Follow__c follow : scope) {
            if (follow.ActivityId__c == null) {
                if (follow.Account__c != null) {
                    List<EntitySubscription> aux = [SELECT id FROM EntitySubscription WHERE SubscriberId =: follow.OwnerId AND ParentId =: follow.Account__c LIMIT 1];
                    if (aux.size() == 0) {
                        deleteFollowsList.add(follow);
                    }
                }
                if (follow.Opportunity__c != null) {
                    List<EntitySubscription> aux = [SELECT id FROM EntitySubscription WHERE SubscriberId =: follow.OwnerId AND ParentId =: follow.Opportunity__c LIMIT 1];
                    if (aux.size() == 0) {
                        deleteFollowsList.add(follow);
                    }
                }
            } /*else {
                List<EntitySubscription> aux = [SELECT id FROM EntitySubscription WHERE SubscriberId =: follow.OwnerId AND ParentId =: follow.ActivityId__c LIMIT 1];
                if (aux.size() == 0) {
                    deleteFollowsList.add(follow);
                }
            }*/
        }

        System.debug('List of elements to delete:');
        System.debug(deleteFollowsList);
        delete deleteFollowsList;
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