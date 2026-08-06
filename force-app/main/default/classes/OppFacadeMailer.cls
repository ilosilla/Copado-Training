/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Opportunities
* @description 	Sens opp. facade mails
*/
public with sharing class OppFacadeMailer {

    OppFacade__c facade;
    String installationDate;
    ContentVersion[] files;

    public OppFacadeMailer(Id id) {
        this.facade = OppFacadeSelector.selectByIdWithLabels(id);
        this.files = AttachmentUtils.getSObjectAttachments(this.facade.Id);
        if (this.facade.Amount__c == null) {
            this.facade.Amount__c = 0;
        }
    } // constructor

    /**
     * Sends a notification to the facade manager when a new facade is created
     */
    public void sendNewFacadeMail() {        
        List<String> emails = new List<String>();
        String firstName = '';
        String cc = '';
        if (SystemUtils.getOnSandbox()) {
            emails.add(UserInfo.getUserEmail());
            firstName = UserInfo.getFirstName();
        } else {
            String managerMail = this.facade.Manager__r.EMail;
            emails.add(this.facade.Manager__r.EMail);
            firstName = this.facade.Manager__r.firstName;
            cc = Systemsettings.USFacadeManagerMail;
            if (String.IsBlank(cc) || (cc==managerMail)) {
                cc = '';
            }
        }

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails);
        if (String.isNotBlank(cc)) {
            m.setCc(new List<String>{cc});
        } 
        m.setSubject('New facade opportunity created');
        
        String body = '';
        body += '<p>Dear ' + firstName + '</p>';
        body += '<p>A new facade has been created with the following details:</p>';
        body += this.buildFacadeTable();
        body += '<p>CRM Team<br/>Porcelanosa USA</p>';                
        body = MailUtils.addHTMLTags(body);
        m.setHtml(body);
        m.send();
    } // sendNewProjectMail    

    /**
     * Sends a notification to the owner and to the manager
     */
    public void sendDeletedFacadeMail() {

        List<String> emails = new List<String>();
        String firstName = '';
        if (SystemUtils.getOnSandbox()) {
            emails.add(UserInfo.getUserEmail());            
            firstName = UserInfo.getFirstName();
        } else {
            emails.add(this.facade.Manager__r.EMail);
            emails.add(this.facade.Opportunity__r.Owner.Email);
            firstName = this.facade.Manager__r.firstName;
        }

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('Facade opportunity deleted');
        
        String body = '';
        body += '<p>Dear ' + firstName + '</p>';
        body += '<p>Your facade project below has been deleted because no files have been attached after ' + SystemSettings.CPDeletionTime + ' hours.<p>';
        body += '<p>CRM Team<br/>Porcelanosa USA</p>';                
        body = MailUtils.addHTMLTags(body);
        body += this.buildFacadeTable();

        m.setHtml(body);
        m.send();
    } // sendNewProjectMail  
    
    /**
     * Sends a reminder to the owner  
     */
    public void sendAttachmentsEmail() {

        if (this.files.size() == 0) {
            List<String> emails = new List<String>();
            String firstName = '';
            if (SystemUtils.getOnSandbox()) {
                emails.add(UserInfo.getUserEmail());
                firstName = UserInfo.getFirstName();
            } else {
                emails.add(this.facade.Opportunity__r.Owner.EMail);
                firstName = this.facade.Opportunity__r.Owner.firstName;
            }

            Mail m = new Mail();
            m.setGeneric();
            m.setTo(emails); 
            m.setSubject('Facade attachments reminder');

            String body = '<p>Dear ' + firstName + '</p>'
                + '<p>The facade project below does not have any files attached and '
                + 'will be deleted from the CRM in the next ' + SystemSettings.CPDeletionTime + ' hours. The facade process requires a drawing or other supporting documents to be uploaded.</p>'
                + '<p><b>Please upload the required files in the attachments section of your facade project now.</b></p>'
                + '<p>Thank you,</p>'
                + '<p>CRM Team<br/>Porcelanosa USA</p>';
            
            body += this.buildFacadeTable();
            body = MailUtils.addHTMLTags(body);
            m.setHtml(body);
            m.send();    
        }
    } // sendAttachmentsEmail

    /**
     * Sends a notification to the facade manager when the drawings are uploaded
     */
    public void sendDrawingsMail(List<String> contentIds) {
        Mail m = new Mail();
        m.setGeneric();
        List<String> emails = new List<String>();
        String firstName = '';
        if (SystemUtils.getOnSandbox()) {
            emails.add(UserInfo.getUserEmail());
            firstName = UserInfo.getFirstName();
        } else {
            emails.add(this.facade.Opportunity__r.Owner.EMail);
            firstName = this.facade.Opportunity__r.Owner.firstName;
        }
        m.setTo(emails); 
        m.setSubject('Shop Drawings Uploaded!');
        m.setAttachments(contentIds);                
        String body = '<p>Dear ' + firstName + '</p>'
            + '<p>The drawings have been uploaded to the facade project below.</p>'
            + '<p>Thank you,</p>'
            + '<p>CRM Team<br/>Porcelanosa USA</p>'
            + '<p>&SUMMARY</p>';
        body += this.buildFacadeTable();
        body = MailUtils.addHTMLTags(body);
        m.setHtml(body);
        m.send();
    } // sendDrawingsMail


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/    
    
    private String buildFacadeTable() {
        String tab = '<table style="border-collapse:collapse;width:800px">'
            + '<tr><th colspan="4" class="col-header">Facade Details</th></tr>'
            + '<tr><td class="row-header">Account</td><td colspan="3"><a href="&ACC.URL&">&ACC.NAME&</a></td></tr>'
            + '<tr>'            
            + '<td class="row-header">Opportunity</td><td><a href="&OPP.URL&">&OPP.NAME&</a></td>'
            + '<td class="row-header">Owner</td><td><a href="mailto:&OWNER.EMAIL&">&OWNER.NAME&</a></td>'
            + '</tr>'
            + '<tr>'            
            + '<td class="row-header">Sales Stage</td><td>&STAGE&</td>'
            + '<td class="row-header">Facade Manager</td><td><A HREF="MAILTO:&MANAGER.EMAIL&">&MANAGER.NAME&</a></td>'
            + '</tr>'
            + '<tr>'            
            + '<td class="row-header">Design Phase</td><td>&PHASE&</td>'
            + '<td class="row-header">Amount</td><td>&AMOUNT& &CURRENCY&</td>'
            + '</tr>'

            + '<tr><th colspan="4" class="col-header">Product Information</th></tr>'

            + '<tr>'            
            + '<td class="row-header">Cladding Material</td><td>&CLADDING&</td>'
            + '<td class="row-header">Material Received</td><td>&RECEIVED&</td>'
            + '</tr>'

            + '<tr>'            
            + '<td class="row-header">Cost Estimate Method</td><td>&COSTMETHOD&</td>'
            + '<td class="row-header">Signed Quote</td><td>&SIGNED&</td>'
            + '</tr>'

            + '<tr><th colspan="4" class="col-header">Project Notes</th></tr>'
            + '<tr><td colspan="4">&NOTES&</td></tr>'
            + '<td class="row-header">Attachments</td><td colspan="3">&NFILES&</td>'

            + '</table>';

        String accountURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + this.facade.Opportunity__r.Account.Id + '/view';
        String opportunityURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + this.facade.Opportunity__r.Id + '/view';

        tab = tab.replace('&ACC.NAME&', this.facade.Opportunity__r.Account.Name);
        tab = tab.replace('&ACC.URL&', accountURL);
        tab = tab.replace('&OPP.NAME&', this.facade.Opportunity__r.Name);
        tab = tab.replace('&OPP.URL&', opportunityURL);
        tab = tab.replace('&OWNER.EMAIL&', this.facade.Opportunity__r.Owner.EMail);
        tab = tab.replace('&OWNER.NAME&', this.facade.Opportunity__r.Owner.Name);
        tab = tab.replace('&STAGE&', this.facade.Stage__c);
        tab = tab.replace('&PHASE&', this.facade.DesignPhase__c);
        tab = tab.replace('&MANAGER.NAME&', this.checkNull(this.facade.Manager__r.Name));
        tab = tab.replace('&MANAGER.EMAIL&', this.checkNull(this.facade.Manager__r.EMail));
        tab = tab.replace('&AMOUNT&', String.valueOf(this.facade.Amount__c));
        tab = tab.replace('&CURRENCY&', this.facade.CurrencyIsoCode);
        tab = tab.replace('&CLADDING&', this.facade.CladdingMaterial__c);
        tab = tab.replace('&COSTMETHOD&', this.facade.CostEstimateMethod__c);
        tab = tab.replace('&RECEIVED&', this.booleanToString(this.facade.MaterialReceived__c));
        tab = tab.replace('&SIGNED&', this.booleanToString(this.facade.SignedQuote__c));
        tab = tab.replace('&NOTES&', this.checkNull(this.facade.ProjectNotes__c));
        tab = tab.replace('&NFILES&', this.booleanToString(this.files.size()>0));

        return tab;
    } // buildFacadeTable

    private String checkNull(String arg) {
        if (arg == null) {
            return '';
        } else {
            return arg;
        }
    }

    private String booleanToString(Boolean bool) {
        if (bool) {
            return 'Yes';
        } else {
            return 'No';
        }
    } // booleanToString

} // class