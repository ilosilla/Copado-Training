/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Opportunities
* @description 	Sens opp. kitchen related mails
*/
public class OppKitchenMailer {

    public Boolean isDeleted = false;

    OppKitchen__c kitchen;
    String installationDate;    

    public OppKitchenMailer(Id id) {
        try {
            this.readKitchen(id);
            this.isDeleted = false;
        } catch(ObjectNotFoundException es) {
            this.isDeleted = true;
        }
    } // constructor

    /**
     * Sends a notification to the owner
     */
    public void sendNewKitchenMail() {

        if (this.isDeleted) {
            return;
        }

        List<String> emails = new List<String>();
        if (SystemUtils.getOnSandbox()) {
            emails.add(UserInfo.getUserEmail());
        } else {
            if (this.kitchen.KitchenDesigner__c != null) {
                emails.add(this.kitchen.KitchenDesigner__r.EMail);
            } else {
                emails.add(this.kitchen.KitchenManager__r.EMail);
            }
        }
        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails); 
        m.setSubject('New kitchen opportunity created');
        
        String body = '';
        body += '<p>Dear ' + this.kitchen.Opportunity__r.Owner.firstName;
        body += '<p>A new kitchen has been created with the following details:</p>';
        body += this.buildKitchenTable();
        body += '<p>CRM Team<br/>Porcelanosa USA</p>';                
        body = MailUtils.addHTMLTags(body);
        m.setHtml(body);
        m.send();
    } // sendNewProjectMail    

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/    
    
    private String buildKitchenTable() {
        String tab = '<table style="border-collapse:collapse;width:800px">'
            + '<tr><th colspan="4" class="col-header">Kitchen Details</th></tr>'
            + '<tr><td class="row-header">Account</td><td colspan="3"><a href="&ACC.URL&">&ACC.NAME&</a></td></tr>'
            + '<tr>'            
            + '<td class="row-header">Opportunity</td><td><a href="&OPP.URL&">&OPP.NAME&</a></td>'
            + '<td class="row-header">Owner</td><td><a href="mailto:&OWNER.EMAIL&">&OWNER.NAME&</a></td>'
            + '</tr>'
            + '<tr>'            
            + '<td class="row-header">Kitchen Stage</td><td>&STAGE&</td>'
            + '<td class="row-header">Kitchen Manager</td><td><A HREF="MAILTO:&KMANAGER.EMAIL&">&KMANAGER.NAME&</a></td>'
            + '</tr>'
            + '<tr>'            
            + '<td class="row-header">Amount</td><td>&AMOUNT& &CURRENCY&</td>'
            + '<td class="row-header">Kitchen Designer</td><td><A HREF="MAILTO:&KDESIGNER.EMAIL&">&KDESIGNER.NAME&</a></td>'
            + '</tr>'

            + '<tr><th colspan="4" class="col-header">Product Information</th></tr>'

            + '<tr>'            
            + '<td class="row-header">Product Type</td><td>&PRODUCTTYPE&</td>'
            + '<td class="row-header">Group</td><td>&GROUP&</td>'
            + '</tr>'

            + '<tr>'            
            + '<td class="row-header">Product Line</td><td>&PRODUCTLINE&</td>'
            + '<td class="row-header">Installation?</td><td>&INSTALLATION&</td>'
            + '</tr>'

            + '<tr>'            
            + '<td class="row-header"></td><td></td>'
            + '<td class="row-header">Estimated Install.</td><td>&ESTIMATEDINSTALL&</a></td>'
            + '</tr>'

            + '<tr><th colspan="4" class="col-header">Financial Information</th></tr>'

            + '<tr>'            
            + '<td class="row-header">Customer\'s Budget</td><td>&BUDGET& &CURRENCY&</td>'
            + '<td class="row-header">SAP Deposit</td><td>&SAPDEPOSIT&</td>'
            + '</tr>'

            + '<tr>'            
            + '<td class="row-header">Pricing Condition</td><td>&PRICINGCOND&</td>'
            + '<td class="row-header">Retainer Fee</td><td>&RETAINER&  &CURRENCY&</td>'
            + '</tr>'

            + '<tr><th colspan="4" class="col-header">Project Notes</th></tr>'
            + '<tr><td colspan="4">&NOTES&</td></tr>'

            + '</table>';

        String accountURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + this.kitchen.Opportunity__r.Account.Id + '/view';
        String opportunityURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + this.kitchen.Opportunity__r.Id + '/view';

        tab = tab.replace('&ACC.NAME&', this.kitchen.Opportunity__r.Account.Name);
        tab = tab.replace('&ACC.URL&', accountURL);
        tab = tab.replace('&OPP.NAME&', this.kitchen.Opportunity__r.Name);
        tab = tab.replace('&OPP.URL&', opportunityURL);
        tab = tab.replace('&OWNER.EMAIL&', this.kitchen.Opportunity__r.Owner.EMail);
        tab = tab.replace('&OWNER.NAME&', this.kitchen.Opportunity__r.Owner.Name);
        tab = tab.replace('&STAGE&', this.kitchen.Stage__c);
        tab = tab.replace('&KMANAGER.NAME&', this.checkNull(this.kitchen.KitchenManager__r.Name));
        tab = tab.replace('&KMANAGER.EMAIL&', this.checkNull(this.kitchen.KitchenManager__r.EMail));
        tab = tab.replace('&KDESIGNER.NAME&', this.checkNull(this.kitchen.kitchenDesigner__r.Name));
        tab = tab.replace('&KDESIGNER.EMAIL&', this.checkNull(this.kitchen.kitchenDesigner__r.EMail));
        tab = tab.replace('&AMOUNT&', String.valueOf(this.kitchen.Amount__c));
        tab = tab.replace('&CURRENCY&', this.kitchen.CurrencyIsoCode);
        tab = tab.replace('&PRODUCTTYPE&', this.kitchen.ProductType__c);
        tab = tab.replace('&GROUP&', this.kitchen.Group__c);
        tab = tab.replace('&INSTALLATION&', this.kitchen.Installation__c);
        tab = tab.replace('&PRODUCTLINE&', this.kitchen.ProductLine2__c);
        tab = tab.replace('&ESTIMATEDINSTALL&', this.installationDate);

        tab = tab.replace('&BUDGET&', this.checkNull(String.valueOf(this.kitchen.Budget__c)));
        tab = tab.replace('&SAPDEPOSIT&', this.checkNull(String.valueOf(this.kitchen.SAPDeposit__c)));
        tab = tab.replace('&PRICINGCOND&', String.valueOf(this.kitchen.PricingCondition__c));
        tab = tab.replace('&RETAINER&', this.checkNull(String.valueOf(this.kitchen.RetainerFee__c)));

        tab = tab.replace('&NOTES&', this.checkNull(this.kitchen.ProjectNotes__c));

        return tab;
    } // buildKitchenTable

    private void readKitchen(Id id) {
        OppKitchen__c[] ks = [
            SELECT 
                Amount__c, Budget__c, CreatedById, CreatedDate, CurrencyIsoCode, DeliveryInstructions__c, 
                EstimatedInstallation__c, Group__c, Id, Installation__c, IsDeleted, KitchenDesigner__c, 
                KitchenManager__c, LastModifiedById, LastModifiedDate, Name, Opportunity__c, toLabel(PricingCondition__c), toLabel(ProductLine2__c), 
                toLabel(ProductType__c), ProjectNotes__c, RetainerFee__c, SAPDeposit__c, toLabel(Stage__c), Opportunity__r.Name,
                Opportunity__r.Owner.firstName,  Opportunity__r.Owner.NAME, Opportunity__r.Owner.EMail, Opportunity__r.Account.Name,
                kitchenManager__r.Name, kitchenManager__r.EMail, kitchenDesigner__r.Name, kitchenDesigner__r.EMail
            FROM OppKitchen__c
            WHERE Id = :id];
        if (ks.size() == 0) {
            throw new ObjectNotFoundException('Kitchen not found');
        }
        this.kitchen = ks[0];
        if (this.kitchen.Amount__c == null) this.kitchen.Amount__c = 0;
        if (this.kitchen.Group__c == null) this.kitchen.Group__c = '';
        if (this.kitchen.Installation__c == null) this.kitchen.Installation__c = '';        
        this.installationDate = '';
        if (this.kitchen.EstimatedInstallation__c != null) this.installationDate = this.kitchen.EstimatedInstallation__c.format();
    } // readKitchen

    private String checkNull(String arg) {
        if (arg == null) {
            return '';
        } else {
            return arg;
        }
    }

} // class