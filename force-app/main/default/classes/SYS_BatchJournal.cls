/**
 * @author         Ramón Prades
 * @date           October 2025
 * @layer          System Utilities
 * @description    
 *                 Utility class that manages execution records for background
 *                 batch jobs. It creates entries in the SYS_BatchJournal__c
 *                 object to keep a concise, system-level history of when each
 *                 batch job was executed, its result, and any related notes.
 *
 *                 The main goal is not detailed logging, but rather a
 *                 lightweight operational record that can be easily reviewed
 *                 or used for daily monitoring reports (for example, sending
 *                 an email summary of all jobs executed in the last 24 hours).
 * 
 */
public with sharing class SYS_BatchJournal {

    public SYS_BatchJournal__c journal { get; private set; }

    public SYS_BatchJournal(Object instance) {
        this.journal = new SYS_BatchJournal__c();
        this.journal.TriggeredBy__c = UserInfo.getUserId();
        try {
            this.journal.JobName__c = String.valueOf(instance).split(':')[0];
        } catch(Exception ex) {
            this.journal.JobName__c = 'Unknown';
        }
    }

    public void start() {
        this.journal.StartTime__c = System.now();
    }

    public void end(Boolean success, String notes) {
        this.journal.EndTime__c = System.now();
        this.journal.Status__c = (success ? 'Success' : 'Failed');
        this.journal.Notes__c = notes;
        insert this.journal;
    }
}