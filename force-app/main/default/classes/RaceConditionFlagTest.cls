@isTest public with sharing class RaceConditionFlagTest {

    @isTest private static void testStaticMethods() {
        String queueName = 'TEST-QUEUE';

        // Test Locking
        String pin1  = RaceConditionFlag.lock(queueName);
        Assert.isNotNull(pin1, 'Lock should be true');

        // Test the resource is locked
        String pin2 = RaceConditionFlag.lock(queueName);
        Assert.isNull(pin2, 'The queue should bee locked by another instance');

        // Release the resource
        RaceConditionFlag.unlock(queueName, pin1);

        // And retry locking from the second instance
        pin2 = RaceConditionFlag.lock(queueName);
        Assert.isNotNull(pin2, 'The queue should have been locked this time');

        // Instance 1 now can't unlock the queue
        Boolean hasException = false;
        try {
            RaceConditionFlag.unlock(queueName, pin1);
        } catch(ContextException csx) {
            Assert.IsNotNull(csx);
            hasException = true;
        }
        Assert.isTrue(hasException, 'Unlocking with PIN1 should have given an exception');

        // Simulate it is an older lock to test the release of old locks
        RaceConditionFlag__c flag = [select Id, LockedTime__c from RaceConditionFlag__c where ResourceName__c = :queueName limit 1];
        flag.LockedTime__c = flag.LockedTime__c.addHours(-1);
        update flag;

        // Retry
        pin1 = RaceConditionFlag.lock(queueName);
        Assert.isNotNull(pin1, 'The old lock should have been released');
    }

    @isTest private static void testInstanceMethods() {
        String queueName = 'TEST-QUEUE';
        RaceCOnditionFlag flag = new RaceConditionFlag(queueName);
        Boolean isLocked = flag.lock();
        Assert.isTrue(isLocked, 'Resource should have been locked');
        Assert.isNotNull(flag.getPIN(), 'PIN should not be null');
        flag.unlock();
        RaceConditionFlag__c dbFlag = [select Id, Locked__c from RaceConditionFlag__c where ResourceName__c = :queueName limit 1];
        Assert.isFalse(dbFlag.Locked__c, 'The queue should be unlocked');
    }


}