/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Opportunities
* @description 	Agent to perform different tasks on custom projects like notifying changes.
                Implementes Schedulable so it can be scheduled to run at certain times
*/
global class CustomProjectAgent implements Schedulable{ 

    private List<Id> ids;
    private String action;
    private CustomProjectMailer mailer;
    
    /**
     * Constructor
     * "action" can be pone of the following:
     * - ATTACHMENTS: Alerts the project owner if no file has been attached
     */
    global CustomProjectAgent() {
        this.ids = new List<Id>();
        this.action = '';
    } // constructor

    global void setAction(String action) {
        this.action = action;
    }

    global void setProjectIds(List<Id> ids) {
        this.ids = ids;
    }

    global void execute(SchedulableContext sc) {
        this.executeAction();
    } // execute

    global void executeAction() {
        this.mailer = new CustomProjectMailer();
        for (Id id :this.ids) {
            switch on this.action {
                when 'ATTACHMENTS' {
                    this.mailer.sendAttachmentsMail(id);
                }              
                when 'NEW-PROJECT' {
                    this.mailer.sendNewProjectMail(id);
                }
                when 'DELETE' {
                    Mail mail = this.mailer.getDeletionMail(id);            
                    if (this.deleteProject(id)) {
                        mail.send();
                    }
                }
            }
        }
    }


    /**
     * Deletes the opportunity of a project if no attachments have been added
     */
    global Boolean deleteProject(Id id) {
        Boolean success = false;
        OppCustomProject__c cp = [select Id, Opportunity__c from OppCustomProject__c where id = :id limit 1];
        ContentVersion[] attachments = AttachmentUtils.getSObjectAttachments(id);        
        if (attachments.size() == 0) {
            Opportunity opp = [select Id from Opportunity where Id = :cp.Opportunity__c limit 1];
            delete opp;   
            success = true;
        } 
        return success;
    } // 



    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
} // class