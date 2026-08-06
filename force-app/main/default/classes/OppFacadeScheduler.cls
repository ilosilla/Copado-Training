/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Opportunities
* @description 	Scheduler for OppFacade jobs
*/
public class OppFacadeScheduler implements Schedulable {

    private List<Id> ids;
    private String action;

    public static void scheduleNewFacade(List<Id> ids) {
        if (SystemSettings.CPNotificationsEnabled) {
            OppFacadeScheduler agent = new OppFacadeScheduler();
            agent.setIds(ids);
            agent.setAction('NEW');
            String sch = ScheduleUtils.runTodayAfter(0, 30);
            String jobID = system.schedule('New project email ' + ids[0], sch, agent);    
        }        
    } // sendNewFacadeMail

    public static void scheduleDeletion(List<Id> ids)  {
        if (SystemSettings.CPDeletionTime > 0) {
            String sch = ScheduleUtils.runTodayAfter(SystemSettings.CPDeletionTime, 0);
            OppFacadeScheduler agent = new OppFacadeScheduler();
            agent.setIds(ids);
            agent.setAction('DELETE');
            String jobID = system.schedule('Delete Facade ' + ids[0], sch, agent);    
        }        
    } // scheduleDeletion

    public static void scheduleReminder(List<Id> ids)  {
        if (SystemSettings.CPDeletionTime > 0) {
            String sch = ScheduleUtils.runTodayAfter(0, 15);
            OppFacadeScheduler agent = new OppFacadeScheduler();
            agent.setIds(ids);
            agent.setAction('REMINDER');
            String jobID = system.schedule('Facade Deletion ' + ids[0], sch, agent);    
        }        
    } // scheduleDeletion

    /**
     * Constructor
     */
    public OppFacadeScheduler() {
        this.ids = new List<Id>();
        this.action = '';
    } // constructor

    public void setIds(List<Id> ids) {
        this.ids = ids;
    } // setIds

    public void setAction(String action) {
        this.action = action;
    } // setAction

    public void execute(SchedulableContext sc) {
        if (this.action == 'DELETE') {
            this.deleteFacades();
        } else if (this.action == 'NEW') {
            this.emailNewFacade();
        } else if (this.action == 'REMINDER') {
            this.emailAttachmentReminder();
        }
    } // execute

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void deleteFacades() {
        for (Id id : this.ids) {
            OppFacadeService.deleteFacade(id);
        }
    } // deleteFacades

    private void emailNewFacade() {
        for (Id id : this.ids) {
            OppFacadeMailer mailer = new OppFacadeMailer(id);
            mailer.sendNewFacadeMail();
        }
    } // emailNewFacade

    private void emailAttachmentReminder() {
        for (Id id : this.ids) {
            OppFacadeMailer mailer = new OppFacadeMailer(id);
            mailer.sendAttachmentsEmail();
        }
    } // emailNewFacade


} // class