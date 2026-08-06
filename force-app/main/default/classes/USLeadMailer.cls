/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Leads
* @description 	Class to manage all emails sent when US leads are created or changed
*               Tests to deploy this class: MaterialBankProjectTest, LeadNewTriggerHandlerTest, RESTUSLeadsTest
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public  class USLeadMailer {

    private Lead lead;
    private String subject;
    private Boolean isEurope = false;
    private String signature;
    private String mbName;

    /**
     * Class constructor
     */
    public USLeadMailer(Id leadID) {      
        this.setUSVariables();  
        this.lead = this.readLead(leadID);
    }

    public void setEurope(Boolean value) {
        this.isEurope = value;
        if (this.isEurope) {
            this.setEUVariables();
        } else {    
            this.setUSVariables();
        }
    }    
    
    public void setSubject(String subjectParam) {
        subject = subjectParam;
    }

    /**
     * Sends an email to the owner when a new lead is created and assigned to the user
     */
    public void emailLeadOwner() {
        String subject = 'You have a new lead!'; // default Subject
        Mail mail = new Mail();
        mail.setGeneric();
        if (SystemUtils.getOnSandbox()) {
            mail.setTo((Id) UserInfo.getUserId());        
        } else {
            mail.setTo(this.lead.OwnerId);
            Boolean debugFeature = SystemSettings.underDevelopment('USLEADS');
            if (debugFeature) {
                mail.setCC(new List<String>{'rprades@porcelanosagrupo.com'});
            }        
        }

        if (String.isNotBlank(this.subject)) {
           subject = this.subject;
        }
        mail.setSubject(subject);
        
        String mailBody = getLeadBody();
        String body = '<p>Dear ' + this.lead.owner.FirstName + ',</p>' +
        + '<p>A lead has contacted us from one of our Web sites. Please review the details below and follow the link to go to the CRM.</p>'
        + mailBody +
        + '<p>Thank you,</p>'
        + '<p>CRM Team<br/>';
        body += this.signature + '</p>';
        
        body = MailUtils.addHTMLTags(body);
        mail.setHtml(body);
        mail.send();
    }

    /**
     * Sends an email to the owner when a new MATERIAL BANK lead is created and assigned to the user
     */
    public void newMaterialBankLead() {
        Mail mail = new Mail();
        mail.setGeneric();
        if (SystemUtils.getOnSandbox()) {
            mail.setTo((Id) UserInfo.getUserId());
        } else {
            mail.setTo(this.lead.OwnerId);
        }
        mail.setSubject('You have a new ' + this.mbName + ' samples lead!');
        
        String mailBody = getLeadBody();
        String body = '<p>Dear ' + this.lead.owner.FirstName + ',</p>' +
        + '<p>A lead has requested samples through MATERIAL BANK website. Please review the details below and follow the link to go to the CRM.</p>'
        + mailBody +
        + '<p>Thank you,</p>'
        + '<p>CRM Team<br/>' + this.signature + '</p>';

        body = MailUtils.addHTMLTags(body);
        mail.setHtml(body);
        mail.send();
    } // newMaterialBankLead

    /**
     * Sends an email to the MB administrators (public group USMBManagers)
     * after processing a MB file
     */
    public static void summaryMaterialBank(Boolean isEurope, String fileName, List<Id> leadIds, List<MaterialBankProject.MaterialBankIssue> issues) {

        String signature = 'Porcelanosa (USA)';
        String materialBank = 'MATERIAL BANK (US)';

        if (isEurope) {
            signature = 'Procelanosa (EUROPE)';
            materialBank = 'MATERIAL BANK (EUROPE)';
        }

        // HTML templates
        String table = '<table style="width:900px"><tr><th class="col-header">Project</th><th class="col-header">Customer</th>'
                       + '<th class="col-header">Account/Contact</th><th class="col-header">Representative</th><th class="col-header">Owner</th><th  class="col-header">#Products</th></tr>';
        String template = '<tr><td class="row-header"><a href="&URL&">&PRNAME&</a></td><td>&CUSTOMER&</td><td>&ACCOUNT&</td><td>&REPRESENTATIVE&</td><td>&OWNER&</td><td>&PRODUCTS&</td></tr>';

        Logger.setScenario('USLeadMailer');
        Map<Id, Integer> productCount = new Map<Id, Integer>();
        AggregateResult[] aggr = [select Lead__c, count(Id) productCount from ProductListItem__c where Lead__c in :leadIds group by Lead__c];
        for(AggregateResult a : aggr) {
            productCount.put((String) a.get('Lead__c'), (Integer) a.get('productCount'));

        }
        
        List<Lead> leads = [select Id, owner.Name, Opportunity_Name__c, firstName, lastName, Title, Company, Postcode__c, City__c, State__c,
                                AccountId__r.Name, ContactId__r.Name, Representative__r.Name, CountryCode__c 
            from Lead where id in :leadIds order by owner.Name];        
        for (Lead lead : leads) {
            String url =  URL.getOrgDomainUrl().toExternalForm() + '/' + lead.Id;
            String region = lead.State__c;
            if (isEurope) {
                region = lead.CountryCode__c;
            }
            String customer = '<b>' + lead.firstName + ' ' + lead.lastname + '</b><br/>'
                            + lead.Title + ' (' + lead.Company + ')' + '<br/>'
                            + lead.Postcode__c + ' ' + lead.City__c + ' (' + region + ')';
            String row = template.replace('&PRNAME&', lead.Opportunity_Name__c);
            row = row.replace('&URL&', url);
            row = row.replace('&CUSTOMER&', customer);
            if (lead.owner != null || lead.owner.Name != null) {
                row = row.replace('&OWNER&', lead.owner.Name);
            } else {
                row = row.replace('&OWNER&', 'Owner not identified'); // Happens when testing
            }
            String accountString = USLeadMailer.unNullify(lead.AccountId__r.Name) + '<br/>' + USLeadMailer.unNullify(lead.contactId__r.Name);
            row = row.Replace('&ACCOUNT&', accountString);
            row = row.Replace('&REPRESENTATIVE&', unNullify(lead.Representative__r.Name));
            row = row.replace('&PRODUCTS&', String.valueOf(productCount.get(lead.Id)));
            table += row;
        }
        table += '</table>';

        Mail mail = new Mail();
        mail.setGeneric();
        mail.setTo(USLeadMailer.getMBSummaryRecipients(isEurope));
        
        String body = '';
        if  (leads.size() > 0) {
            mail.setSubject('New ' + materialBank + ' projects loaded!');        
            body = '<p>A new batch with ' + leads.size() + ' leads from ' + materialBank + ' has been loaded and assigned to a sales person.</p>'
                 + table +
                 + '<p>Thank you,</p>'
                 + '<p>CRM Team<br/>' + signature + '</p>';
        } else {
            mail.setSubject('New ' + materialBank + ' projects loaded!');        
            body = 'A new ' + materialBank + ' process has been launched but no new leads have been created.';
        }
        body += '<p><i>File name: ' + fileName + '</i></p>';

        String issuesBody = '<p>The following projects have not been loaded.</p>';
        issuesBody += '<table style="width:700px"><tr><th class="col-header">Status</th><th class="col-header">Project</th><th class="col-header">Customer</th>'
                    + '<th  class="col-header">Comments</th></tr>';
        String issueTemplate = '<tr><td class="row-header">&STATUS&</td><td class="row-header">&PROJECT&</td><td>&CUSTOMER&</td><td>&COMMENTS&</td></tr>';
        for (MaterialBankProject.MaterialBankIssue issue : issues) {
            String row = issueTemplate.replace('&PROJECT&', issue.projectName);
            row = row.replace('&CUSTOMER&', issue.customerName);
            row = row.replace('&COMMENTS&', issue.comments);
            if (issue.isError) {
                row = row.replace('&STATUS&', 'ERROR');
            } else {
                row = row.replace('&STATUS&', 'WARNING');
            }
            issuesBody += row;
        }
        issuesBody += '</table>';
        if (issues.size() > 0) {
            body += issuesBody;
        }
        body = MailUtils.addHTMLTags(body);
        mail.setHtml(body);
        mail.send();
    } // summaryMaterialBank

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void setUSVariables() {
        this.signature = 'Porcelanosa USA';
        this.mbName = 'MATERIAL BANK (USA)';
    }

    private void setEUVariables() {
        this.signature = 'Porcelanosa (EU)';
        this.mbName = 'MATERIAL BANK (EU)';
    }


    private static String unNullify(String str) {
        if (String.isEmpty(str)||String.IsBlank(str)) {
            return '';
        } else {
            return str;
        }
    } //unNullify

    /*
     * Gets the list of people that will receive the MB summary elamil
     */
    private static List<String> getMBSummaryRecipients(Boolean isEurope) {
        List<String> emails = new List<String>();
        List<Id> managers;
        if (isEurope) {
            managers = USLeadMailer.getPublicGroupMembers('EUMBManagers');
        } else {
            managers = USLeadMailer.getPublicGroupMembers('USMBManagers');
        }
        User[] users = [select Id, Email from User where Id in :managers];
        for (User u : users) {
            emails.add(u.EMail);
        } 
        if (emails.size() == 0) {
            if (SystemUtils.getOnSandbox()) {
                emails.add(UserInfo.getUserEmail());
            } else {
                emails.add('rprades@porcelanosagrupo.com');
            }
        }
        return emails;
    } // getMBSummaryRecipients
    
    private String getLeadBody() {
        String url =  URL.getOrgDomainUrl().toExternalForm() + '/' + this.lead.Id;

        String region = this.lead.State__c;
        if (this.isEurope) {
            region = this.lead.CountryCode__c;
        }

        String description = '';
        if (String.isNotEmpty(this.lead.Description)) {
            description = this.lead.Description.replace('\n', '<br/>');
        }
        Map<String, String> m = new Map<String, String>();
        m.put('Lead Name', '<a href="' + url + '">' + this.lead.Opportunity_Name__c + '</a>');
        m.put('Name', this.lead.FirstName + ' ' + this.lead.LastName);
        m.put('Title', this.lead.Title);
        m.put('Company', this.lead.Company);
        m.put('Phone', this.lead.MobilePhone);
        m.put('EMail', this.lead.Email);
        m.put('Status', this.lead.Status);
        m.put('Source', this.lead.LeadSource);
        m.put('Owner', this.lead.owner.Name);
        m.put('Type', this.lead.LeadType__c);
        m.put('Subtype', this.lead.LeadSubtype__c);
        m.put('Location', this.lead.Postcode__c + ' ' + this.lead.City__c + ' (' + region + ')');
        m.put('Description', description);
        String table = MailUtils.mapToTable(m, 'width:700px;');

        List<ProductListItem__c> items = [select ProductCode__c, Name, Name__c, Quantity__c, Unit__c, Shipped__c from ProductListItem__c 
                                                where Lead__c = :this.lead.id order by Name];
        
        String productsTable = '<table style="width:700px"><tr><th class="row-header" colspan="3">SAMPLES REQUESTED</th></tr><tbody>';
        String rowTemplate = '<tr><td>&CODE&</td><td>&NAME&</td><td>&QUANTITY&</td><td>&SHIPPED&</td></tr>';
        for (ProductListItem__c item : items) {
            String row = rowTemplate.replace('&CODE&', item.ProductCode__c);
            row = row.replace('&NAME&', item.Name__c);
            row = row.replace('&QUANTITY&', item.Quantity__c + ' ' + item.Unit__c);
            row = row.replace('&SHIPPED&', TypeConversionCommons.booleanToLabel(item.Shipped__c));
            productsTable += row;
        }
        productsTable += '</tbody></table>';
        if (items.size() > 0) {
            table += productsTable;
        }
        
        return table;
    } // getLeadBody


    private Lead readLead(String leadId) {
        return [select 
                Id, Opportunity_Name__c, Title, Name, Salutation, FirstName, LastName, MobilePhone, Email, Operation_Type__c, 
                CountryCode__c, Address__c, Postcode__c, State__c, City__c, Description, 
                IsConverted, AccountId__c, ContactId__c, Source__c, Company, Profile__c, CreatedDate, LeadSource, toLabel(Status),
                LeadType__c, leadSubtype__c, Close_Date__c, CurrencyIsoCode, OwnerId, owner.name, owner.email, owner.firstName
            from Lead where Id = :leadId limit 1];            
    } // readLead

    private static List<Id> getPublicGroupMembers(String groupName) {
        Id[] ids = new List<Id>();
        Group[] groups = [select Id, DeveloperName from Group where DeveloperName = :groupName];
        if (groups.size() > 0) {
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :groups[0].Id]) {
                ids.add(member.UserOrGroupId);
            }
        }
        return ids;
    }




}