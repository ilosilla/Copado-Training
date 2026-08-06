/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Opportunities
* @description 	Class to handle all the notifications related to custom projects
*/
public class CustomProjectMailer implements Queueable {

    private String asyncAction;
    private String asyncId;
    private Boolean asyncMode = false;

    private Id[] mailAttachmentsIds = new List<Id>();
    private Id currentId = null;
    private Opportunity opportunity;
    private OppCustomProject__c customProject;
    private ContentVersion[] attachments;    
    private Map<String, String> projectStages;
    private Map<String, String> projectTypes;
    private String location;
    private String orgName;

    /**
     * Constructor for synchronpous mode
     */
    public CustomProjectMailer() {
        this.asyncMode = false;
    }

    /**
     * Constructor for asynchronous mode
     */
    public CustomProjectMailer(String id, String action) {
        this.asyncMode = true;
        this.asyncId = id;
        this.asyncAction = action;
    }

    /**
     * Array of IDs of Document, ContentVersion, or Attachment items to attach to the email.
     */
    public void setMailAttachments(Id[] ids) {
        this.mailAttachmentsIds = ids;
    } // setAttachmentIds

    /**
     * Clears the list of files to attach
     */
    public void clearMailAttachments() {
        this.mailAttachmentsIds.clear();
    } // setAttachmentIds


    /**
     * Method to send mails in asynchronous mode.
     * Example: ID jobID = System.enqueueJob(new AsyncExecutionExample());
     */
    public void execute(QueueableContext context) {
        if (asyncMode) {
            switch on this.asyncAction {
                when 'DRAWING'{
                    this.sendDrawingsMail(this.asyncId);
                }
                when 'QUOTE'{
                    this.sendQuoteMail(this.asyncId);
                }

            }
        }
    } // execute

    /**
     * Sends a reminder to the opportunity owner when the projects has no files attached (scheduled 15 minutes after creation)
     */
    public void sendAttachmentsMail(Id id) {
        this.readObjects(id);
        if (this.attachments.size() == 0) {
            Mail m = new Mail();
            m.setGeneric();
            m.setTo(new List<String>{this.getOpportunityOwnerEmail()}); 
            m.setSubject('Pending Custom Project\'s Attachment Reminder');
            
            String body = '<p>Dear &OWNER.FIRSTNAME,</p>' +
                + '<p>The custom project linked to your opportunity "&OPP.NAME" (see summary below) does not have any files attached and '
                + 'will be deleted from the CRM in the next 2 hours. The custom projects process requires a drawing or other supporting documents to be uploaded.</p>'
                + '<p><b>Please click <a href="$OPP.URL">here</a> and upload the required files in the attachments section of your custom project now.</b></p>'
                + '<p>Thank you,</p>'
                + '<p>CRM Team<br/>Porcelanosa USA</p>'
                + '<p>&SUMMARY';
            body = this.fillBody(body);
            body = MailUtils.addHTMLTags(body);
            m.setHtml(body);
            m.send();
        }
    } // sendAttachmentsMail

    /**
     * Sends a notification to the owner when the projects department uploads the shop drawings
     */
    public void sendDrawingsMail(Id id) {
        this.readObjects(id);
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(new List<String>{this.getOpportunityOwnerEmail()}); 
        m.setSubject('Shop Drawings Uploaded!');
        m.setAttachments(this.mailAttachmentsIds);
        
        String body = '<p>Dear &OWNER.FIRSTNAME,</p>' +
            + '<p>The Projects Team has uploaded the attached shop drawings to the custom project below.</p>'
            + '<p><b>Please contact the customer and remember to upload the signed drawings to the CRM once you have them.</b></p>'
            + '<p>Thank you,</p>'
            + '<p>CRM Team<br/>Porcelanosa USA</p>'
            + '<p>&SUMMARY</p>';
        body = this.fillBody(body);            
        m.setHtml(body);
        m.send();
    } // sendDrawingsMail

    /**
     * Sends a notification to the owner when the projects department uploads a new quote
     */
    public void sendQuoteMail(Id id) {
        this.readObjects(id);
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(new List<String>{this.getOpportunityOwnerEmail()}); 
        m.setSubject('Custom Project Quote Uploaded!');
        m.setAttachments(this.mailAttachmentsIds);
        
        String body = '<p>Dear &OWNER.FIRSTNAME,</p>' +
            + '<p>The Projects Team has uploaded a new quote to the custom project below.</p>'
            + '<p>CRM Team<br/>Porcelanosa USA</p>'
            + '<p>&SUMMARY</p>';
        body = this.fillBody(body);            
        m.setHtml(body);
        m.send();
    } // sendQuoteMail


    /**
     * Sends a notification to the owner adn to Projects USA when the project changes the stage
     */
    public void sendStageChangeMail(Id id, String oldStage) {
        this.readObjects(id);
        List<String> emails = this.getProjectsTeamEmails();
        emails.add(this.getOpportunityOwnerEmail());
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('Custom Project Stage Changed!');

        String newStageName = this.projectStages.get(this.customProject.Stage__c);
        String oldStageName = this.projectStages.get(oldStage);

        //List<String> emails = this.getProjectsTeamEmails();        
        //emails.add(opp.Owner.EMail);
        //emails = new List<String>{'rprades@porcelanosagrupo.com'};
        //m.setTo(new List<String>{'rprades@porcelanosagrupo.com'}); 
        
        String body = '<p>Stage changed in custom project linked to your opportunity "&OPP.NAME" (see details below):</p>'
            + '<table class="info-banner" style="width:600px"><tr><td><b>' + oldStageName + ' ==> ' + newStageName + '</b></td></tr></table>'
            + '<p><b>Please click <a href="&OPP.URL">here</a> to navigate to the opportunity.</b></p>'
            + '<p>Thank you,</p>'
            + '<p>CRM Team<br/>Porcelanosa USA</p>'
            + '&SUMMARY';

        body = this.fillBody(body);
        body = MailUtils.addHTMLTags(body);
        m.setHtml(body);
        m.send();
    } // sendStageChangeMail

    /**
     * Sends a notification to the projects department when a new cp is created (scheduled 30 minutes aftger creation)
     */
    public void sendNewProjectMail(Id id) {

        Logger.setScenario('CustomProjectMailer');
        Boolean debugFeature = SystemSettings.underDevelopment('USMAILS');
        if (debugFeature) {
            Logger.info('New custom project created');
        }        
        
        this.readObjects(id);
        
        List<String> emails = this.getProjectsTeamEmails();
        emails.add(this.getOpportunityOwnerEmail());
        if (debugFeature) {            
            emails.add('rprades@porcelanosagrupo.com');
            Logger.info('New custom project email sent to ' + emails.size());
        }        
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('New Custom Project created');
            
        String body = '';

        if (this.attachments.size() == 0) {
            body += '<table class="error-banner" style="width:600px"><tr><td><b>No Attachments</b><br/>This project has no attachments and will be deleted soon unless the user uploads at least one file!</td></tr></table>';
        }
        
        body += '<p>A new custom project has been created with the following details:</p><p>&SUMMARY</p>';
        body += '<p>CRM Team<br/>Porcelanosa USA</p>';                
        body = MailUtils.addHTMLTags(body);
        body = this.fillBody(body);
        m.setHtml(body);
        m.send();
        if (debugFeature) {            
            Logger.info('Email sent');
            Logger.saveLog();
        }        

    } // sendNewProjectMail

    /**
     * Sends a notification to the projects department when a new cp is created (scheduled 30 minutes aftger creation)
     */
    public void sendDeletionMail(Id id) {        
        this.getDeletionMail(id).send();
    } // sendDeletionMail

    /**
     * Returns the deletion's mail of a project
     */
    public Mail getDeletionMail(Id id) {
        this.readObjects(Id);
        List<String> emails = this.getProjectsTeamEmails();
        if (SystemUtils.getOnSandbox()) {
            emails.add(UserInfo.getUserEmail());
        } else {
            emails.add(this.getOpportunityOwnerEmail());
        }
        
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('Custom Project deleted!');
            
        String body = '';

        body += '<table class="error-banner" style="width:600px"><tr><td><b>Project Deleted!</b><br/>Your custom project bound to opportunity "&OPP.NAME" '
            + 'has been deleted because no files had been attached after '
            + SystemSettings.CPDeletionTime + ' hours.</td></tr></table>';
        
        body += '<p>CRM Team<br/>Porcelanosa USA</p>';                
        body += '<p>&SUMMARY</p>';
        body = this.fillBody(body);
        m.setHtml(body);
        return m;
    } // sendDeletionMail

    /**
     * Email owner and projects team when material released
     */
    public void sendMaterialMail(Id id) {

        this.readObjects(id);

        List<String> emails = this.getProjectsTeamEmails();
        emails.add(this.getOpportunityOwnerEmail());

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('Custom Project Material Released!');

        String body = '<p>Material for custom project "&OPP.NAME" (see details below) has been released.</p>'
            + '<p><b>Please click <a href="&OPP.URL">here</a> to navigate to the opportunity.</b></p>'
            + '<p>Thank you,</p>'
            + '<p>CRM Team<br/>Porcelanosa USA</p>'
            + '<p>&SUMMARY</p>';
            
        body = this.fillBody(body);
        m.setHtml(body);
        m.send();
    } // sendMaterialMail

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private String getOpportunityOwnerEmail() {
        String email = this.opportunity.Owner.Email;
        if (email == null) {
            email = 'rprades@porcelanosagrupo.com';
        }
        return email;
    }

    private String fillBody(String body) {
        String oppURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.opportunity.Id;
        String accountURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.opportunity.AccountId;
        String stageName = this.projectStages.get(customProject.Stage__c);
        String typeName = this.projectTypes.get(customProject.ProjectType__c);
        String firstName = this.opportunity.Owner.FirstName;
        if (firstName == null) {
            firstName = 'User';
        }

        body = body.replace('&SUMMARY', this.getProjectSummary());                
        body = body.replace('&OWNER.FIRSTNAME', firstName);
        body = body.replace('&OWNER.NAME', this.opportunity.Owner.Name);
        body = body.replace('&OWNER.EMAIL', this.opportunity.Owner.EMail);
        body = body.replace('&SALESORG', '[' + this.opportunity.Owner.Default_Sales_Organization__c + '] ' + this.orgName);
        body = body.replace('&ACCOUNT.NAME', this.opportunity.Account.Name);
        body = body.replace('&ACCOUNT.URL', accountURL);
        body = body.replace('&PROJECT.TYPE', typeName);
        body = body.replace('&PROJECT.STAGE', stageName);
        body = body.replace('&PROJECT.LOCATION', this.location);
        body = body.replace('&PROJECT.AMOUNT', String.valueOf(this.customProject.Amount__c));
        body = body.replace('&PROJECT.CURRENCY', this.customProject.CurrencyIsoCode);
        body = body.replace('&NFILES', String.valueOf(this.attachments.size()));    
        body = body.replace('&OPP.NAME', this.opportunity.Name);
        body = body.replace('&OPP.URL', oppURL);        

        body = MailUtils.addHTMLTags(body);
        return body;
    } // fillBody

    private String getProjectSummary() {
        String body = '<table style="border-collapse:collapse;width:600px">' +
        + '<tr><td class="row-header">Opportunity</td><td><a href="&OPP.URL">&OPP.NAME</a></td></tr>'
        + '<tr><td class="row-header">Owner</td><td><a href="mailto:&OWNER.EMAIL">&OWNER.NAME</a></td></tr>'
        + '<tr><td class="row-header">Owner\'s Organization</td><td>&SALESORG</td></tr>'
        + '<tr><td class="row-header">Account</td><td><a href="&ACCOUNT.URL">&ACCOUNT.NAME</a></td></tr>'
        + '<tr><td class="row-header">Project Type</td><td>&PROJECT.TYPE</td></tr>'
        + '<tr><td class="row-header">Project Address</td><td>&PROJECT.LOCATION</td></tr>'
        + '<tr><td class="row-header">Project Amount</td><td>&PROJECT.AMOUNT &PROJECT.CURRENCY</td></tr>'
        + '<tr><td class="row-header">Stage</td><td>&PROJECT.STAGE</td></tr>'
        + '<tr><td class="row-header">#Attachments</td><td>&NFILES</td></tr>'
        + '</table>';
        return body;
    } // getProjectSummary

    private List<String> getProjectsTeamEmails() {                
        List<User> staff = UserUtils.getProjectsStaff('US');
        List<String> emails = new List<String>();
        for (User u :staff) {
            emails.add(u.EMail);
        }
        return emails;
    } // getProjectsTeamEmails

    private void readObjects(Id id) {
        if (this.currentId == null || this.currentId != id) {
            this.customProject = [select Id, Opportunity__c, Stage__c, ProjectType__c, Amount__c, CurrencyIsoCode from OppCustomProject__c where Id = :id limit 1];
            this.opportunity = [select Id, name, AccountId, Account.Name, Owner.FirstName, Owner.Name, Owner.email, Owner.Default_Sales_Organization__c from Opportunity where id = :customProject.Opportunity__c];
            this.attachments = AttachmentUtils.getSObjectAttachments(id);
            this.location = InternationalAddress.fromOpportunity(this.opportunity.Id).formatHTML();
            this.orgName = OrganizationUtil.getSalesOrgName(this.opportunity.Owner.Default_Sales_Organization__c);            
            this.projectStages = ReflectionUtils.getPicklistValuesMap(OppCustomProject__c.Stage__c);    
            this.projectTypes = ReflectionUtils.getPicklistValuesMap(OppCustomProject__c.ProjectType__c);
            this.currentId = customProject.Id;  
            if (this.customProject.Amount__c == null) {
                this.customProject.Amount__c = 0;
            } 
        }
    } // readObjects
    
}