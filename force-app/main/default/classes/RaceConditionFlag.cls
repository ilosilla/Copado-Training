/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          ARCHITECURE
 * @description    This class ensures the locking of critical resources to prevent race conditions.
 *                 To support async calls, the job is done by the static methoids, althoughh instance methods are also provided
 *                 for conveninence.

*/
public class RaceConditionFlag {

    private String queueName = '';
    private String pin = '';

    public RaceConditionFlag(String queueName) {
        this.queueName = queueName;
    }

    public Boolean lock() {
        this.pin = RaceConditionFlag.lock(this.queueName);
        return (this.pin!= null);
    }

    public String getPIN() {
        return this.pin;
    }

    public void unlock() {
        RaceConditionFlag.unlock(this.queueName, this.pin);
        this.pin = null;
    }

    /**
     * Lock the resouurce
     */
    public static String lock(String queueName) {
        String pin = null;
        RaceConditionFlag__c raceFlag =  RaceConditionFlag.getRaceConditionFlag(queueName);
        RaceConditionFlag.releaseOldLock(raceFlag);
        if (!raceFlag.Locked__c) {
            pin = RaceCOnditionFlag.generateRandomPIN();
            raceFlag.Locked__c = true;
            raceFlag.LockedTime__c = DateTime.now();
            raceFlag.PIN__c = pin;
            upsert raceFlag;
        }
        return pin;
    }

    /**
     * Unlock the resource from async methods
     */
    public static void unlock(String queueName, String pin) {        
        RaceConditionFlag__c race = RaceConditionFlag.getRaceConditionFlag(queueName);
        if (race.Locked__c) {
            if (pin == race.PIN__c) {
                race.Locked__c = false;
                race.LockedTime__c = null;            
                race.PIN__c = '';
                update race;   
            } else {
                throw new ContextException('Wrong PIN');
            }
        }
    }

    private static void releaseOldLock(RaceConditionFlag__c raceFlag) {
        if (raceFlag.Locked__c && raceFlag.LockedTime__c != null) {
            Long ellapsed = DateTime.now().getTime() - raceFlag.LockedTime__c.getTime();
            // If the lock is older than 10 minutes, force the unlock
            if (ellapsed > 10 * 60 * 1000) {
                raceFlag.Locked__c = false;
                raceFlag.LockedTime__c = null;
                raceFlag.PIN__c =  null;
            }
        }
    }

    private static RaceConditionFlag__c getRaceConditionFlag(String queueName) {        
        RaceConditionFlag__c[] flags = [select Id, Locked__c, LockedTime__c, PIN__c from RaceConditionFlag__c where ResourceName__c = :queueName];
        if (flags.size() == 0) {
            RaceConditionFlag__c newRace = new RaceConditionFlag__c();
            newRace.Name = queueName;
            newRace.ResourceName__c = queueName;
            newRace.Locked__c = false;
            newRace.PIN__c = '';
            return newRace;
        } else {
            return flags[0];
        }        
    }

    private static String generateRandomPIN() {
        Integer random = Integer.valueof((Math.random() * 1000000));
        return String.valueOf(random);
    }
}