/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Opportunities
* @description 	Opportunity Custom Project utils
*/
public with sharing class CustomProjectUtils {

    /**
     * Reads the documents attached to a custom project
     */
    public static ContentDocument[] readAttachments(String projectId) {
        List<ContentDocumentLink> links = [select contentDocumentId from ContentDocumentLink where LinkedEntityId  = :projectId];
        List<Id> ids = new List<Id>();
        for (ContentDocumentLink link :links) {
            ids.add(link.contentDocumentId);
        }
        return [select Id, Title, Description, CreatedDate, FileExtension, OwnerId, Owner.Name from ContentDocument where id in :ids order by createdDate];
    } // readAttachments

    /**
     * Schedules the deletion of the project of no files attached
     */
    public static void scheduleDeletion(List<Id> ids) {
        if (SystemSettings.CPDeletionTime > 0) {
            CustomProjectAgent agent = new CustomProjectAgent();
            agent.setProjectIds(ids);
            agent.setAction('DELETE');
            String sch = ScheduleUtils.runTodayAfter(SystemSettings.CPDeletionTime, 0);
            String jobID = system.schedule('Project Deletion ' + ids[0], sch, agent);    
        }        
    } // scheduleDeletion

    /**
     * Schedules the no-attachment notifier after the trigger has been created
     */
    public static void scheduleNoFilesEmail(List<Id> ids) {
        if (SystemSettings.CPNotificationsEnabled) {
            CustomProjectAgent agent = new CustomProjectAgent();
            agent.setProjectIds(ids);
            agent.setAction('ATTACHMENTS');
            String sch = ScheduleUtils.runTodayAfter(0, 15);
            String jobID = system.schedule('Attachments Reminder ' + ids[0], sch, agent);    
        }        
    }

    /**
     * Schedules the notification of new custom project
     */
    public static void scheduleNewProjectEmail(List<Id> ids) {
        if (SystemSettings.CPNotificationsEnabled) {
            CustomProjectAgent agent = new CustomProjectAgent();
            agent.setProjectIds(ids);
            agent.setAction('NEW-PROJECT');
            String sch = ScheduleUtils.runTodayAfter(0, 30);
            String jobID = system.schedule('New project email ' + ids[0], sch, agent);    
        }        
    }

} // class