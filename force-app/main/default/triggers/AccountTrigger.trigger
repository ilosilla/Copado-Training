trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete) {
    TriggerDispatcher.run(new AccountTriggerHandler());
}