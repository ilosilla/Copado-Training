trigger PENewTaskTrigger on PENewTask__e (after insert) {
    Set<Id> idsUpdateLastActivity = new Set<Id>();
    for (PENewTask__e pe : Trigger.New) {
        idsUpdateLastActivity.add(pe.ObjectId__c);
    }

    ActivityDateService.updateFromTasks(idsUpdateLastActivity);
}