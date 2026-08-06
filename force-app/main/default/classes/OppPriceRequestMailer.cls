// public class OppPriceRequestMailer implements Queueable{
public class OppPriceRequestMailer{
    
    private Boolean asyncMode = false;
    private String asyncId;
    private String asyncAction;

    private Id currentId = null;
    private OppPriceRequestHeader__c priceRequest;
    private List<OppPriceRequestItem__c> items;
    private String orgName;
    private String officeName;

    public OppPriceRequestMailer() {
        this.asyncMode = false;
    }

    public void sendToApprovalMail(Id id, Set<Id> itemsIds) {
        this.readObjects(id, itemsIds);
        this.keepToApprovalItems();

        List<String> emails = this.getApproversEmails();

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails);
        m.setSubject(System.Label.prequest_subject_approval_mail);

        String body = System.Label.prequest_body_approval_mail;
            
        body = this.fillBody(body, this.items, 'APPROVAL');
        m.setHtml(body);
        m.send();
    }

    public void sendToFactoryApprovalMail(Id id, Set<Id> itemsIds) {
        this.readObjects(id, itemsIds);
        this.keepToApprovalItems();

        List<String> emails = this.getPriceFactoryApproversEmails();

        Mail m = new Mail();
        m.setGeneric();
        m.setTo(emails);
        m.setSubject('Factory Price Request - Approval Needed');

        String body = System.Label.prequest_body_approval_mail;
        body = this.fillFactoryBody(body, this.items, 'APPROVAL');
        m.setHtml(body);
        m.send();
    }

    public void sendReviewedMail(Id id, Set<Id> itemsIds) {
        this.readObjects(id, itemsIds);
        this.keepReviewedItems();

        Map<Id, String> emails = new Map<Id, String>();

        Map<Id, List<OppPriceRequestItem__c>> mapManagers = new Map<Id, List<OppPriceRequestItem__c>>();
        for (OppPriceRequestItem__c item : this.items) {
            if (mapManagers.containsKey(item.CreatedBy.Id)) {
                List<OppPriceRequestItem__c> auxList = mapManagers.get(item.CreatedBy.Id);
                auxList.add(item);
                mapManagers.put(item.CreatedBy.Id, auxList);
            } else {
                mapManagers.put(item.CreatedBy.Id, new List<OppPriceRequestItem__c>{item});
            }
            emails.put(item.CreatedBy.Id, item.CreatedBy.Email);
        }

        for (Id elem : mapManagers.keySet()) {
            Mail m = new Mail();
            m.setGeneric();
            m.setTo(new List<String>{emails.get(elem)});
            m.setSubject(System.Label.prequest_subject_reviewed_mail);
    
            String body = System.Label.prequest_body_reviewed_mail;
                
            body = this.fillBody(body, mapManagers.get(elem),'REVIEWED');
            m.setHtml(body);
            m.send();
        }
    }

    public void sendFactoryReviewedMail(Id id, Set<Id> itemsIds) {
        this.readObjects(id, itemsIds);
        this.keepReviewedItems();

        List<String> emails = new List<String>();
        Set<String> itemsSubmittersEmails = new Set<String>();
        for (OppPriceRequestItem__c item : this.items) {
            if (item.SubmittedToFactoryManager__c != null) {
                itemsSubmittersEmails.add(item.SubmittedToFactoryManager__r.Email);
            }
        }

        if (itemsSubmittersEmails.size() > 0) {
            emails.addAll(itemsSubmittersEmails);
        } else {
            emails = this.getApproversEmails();
        }

        Mail m = new Mail();
        m.setTo(emails);
        m.setSubject(System.Label.prequest_subject_reviewed_mail);

        String body = System.Label.prequest_body_reviewed_mail;
                
        body = this.fillFactoryBody(body, this.items,'REVIEWED');
        m.setHtml(body);
        m.send();
    }

    /********************************************************************************* *
                                        Private Methods
    ************************************************************************************/

    private List<String> getApproversEmails() {
        Set<String> approverEmails = new Set<String>();
        List<User> approvers = getPriceApprovers(this.priceRequest.Opportunity__r.Owner.Default_Sales_Organization__c,this.priceRequest.Opportunity__r.Owner.Sales_Office__c, this.priceRequest.Opportunity__r.Owner.CountryCode);
        
        
        for (User usr : approvers) {
            approverEmails.add(usr.Email);
        }

        if (approverEmails.size() == 0) {
            approverEmails.add('ivan.losilla@porcelanosagrupo.com');
        }

        return new List<String>(approverEmails);
    }

    private List<String> getPriceFactoryApproversEmails() {
        Set<String> approverEmails = new Set<String>();
        List<User> approvers = getPriceFactoryApprovers(this.priceRequest.Opportunity__r.Owner.Default_Sales_Organization__c,this.priceRequest.Opportunity__r.Owner.Sales_Office__c, this.priceRequest.Opportunity__r.Owner.CountryCode);
        
        
        for (User usr : approvers) {
            approverEmails.add(usr.Email);
        }

        if (approverEmails.size() == 0) {
            approverEmails.add('ivan.losilla@porcelanosagrupo.com');
        }

        return new List<String>(approverEmails);
    }

    private String fillBody(String body, List<OppPriceRequestItem__c> items, String typeMail) {
        String reviewPageURL = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/Review_Pricing';
        String oppURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.priceRequest.Opportunity__c;
        String accountURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.priceRequest.Opportunity__r.AccountId;
        String ownerName = this.priceRequest.Opportunity__r.Owner.Name;
        String userName = UserInfo.getName();
        String aux = '';

        body = body.replace('&SUMMARY', this.getPriceRequestSummary());
        body = body.replace('&USERNAME', userName);
        body = body.replace('&OWNER.NAME', ownerName);
        body = body.replace('&OWNER.EMAIL', this.priceRequest.Opportunity__r.Owner.EMail);
        body = body.replace('&SALESORG', this.orgName);
        body = body.replace('&SALESOFFICE', this.officeName);
        body = body.replace('&ACCOUNT.NAME', this.priceRequest.Opportunity__r.Account.Name);
        body = body.replace('&ACCOUNT.URL', accountURL);
        body = body.replace('&NEEDEDBY', this.priceRequest.NeededBy__c != null ? (this.priceRequest.NeededBy__c).format() : '');
        body = body.replace('&APPROVECODE', this.priceRequest.ApproveCode__c != null ? this.priceRequest.ApproveCode__c : ' - ');
        body = body.replace('&NOTES', this.priceRequest.Notes__c != null ? this.priceRequest.Notes__c : '');
        body = body.replace('&OPP.NAME', this.priceRequest.Opportunity__r.Name);
        body = body.replace('&OPP.URL', oppURL);        
        body = body.replace('&REVIEWPAGE', reviewPageURL);

        Integer loopIndex = 1;

        if (typeMail == 'APPROVAL' && items.size() > 0 ) {
            aux += '<tr>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_product+'</td>'
                    + '<td class="row-header" style="text-align: center;" colspan="2">'+System.Label.dict_productName+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_quantity+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_reference_price+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_factory_price+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_price_needed+'</td>'
                    + '</tr>';
        }
        if (typeMail == 'REVIEWED' && items.size() > 0 ) {
            aux += '<tr>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.dict_product+'</td>'
                + '<td class="row-header" style="text-align: center;" colspan="2">'+System.Label.dict_productName+'</td>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.dict_status+'</td>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_price_needed+'</td>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_approved_price+'</td>'
                + '</tr>';
        }

        for (OppPriceRequestItem__c item : items) {
            aux += '<br/><p>';
            if (typeMail == 'APPROVAL') {
                aux += this.getPriceRequestItemApprovalSummary();
            }
            if (typeMail == 'REVIEWED') {
                aux += this.getPriceRequestItemReviewedSummary();
            }

            String textStatus = '';
            switch on item.Status__c {
                when 'APPROVED' {
                    textStatus = System.Label.dict_approved;
                }
                when 'REJECTED' {
                    textStatus = System.Label.dict_rejected;
                }
                when 'APPROVEDPARTIALLY' {
                    textStatus = System.Label.prequest_part_approved;
                }
                when 'PENDING' {
                    textStatus = System.Label.dict_pending;
                }
            }

            aux = aux.replace('&ITEM.INDEX', this.printNumberTosString(loopIndex) + ' - Submitted at ' + (item.SubmittedDate__c != null ? item.SubmittedDate__c.format() : '-'));
            aux = aux.replace('&ITEM.CODE', item.ProductCodeFormula__c != null ? item.ProductCodeFormula__c : '');
            aux = aux.replace('&ITEM.STATUS', textStatus);
            aux = aux.replace('&ITEM.NAME', item.ProductNameFormula__c != null ? item.ProductNameFormula__c : '');
            aux = aux.replace('&ITEM.QUANTITY', item.Quantity__c != null ? item.Quantity__c : '');
            aux = aux.replace('&ITEM.REFERENCEPRICE', this.printPrice(item.ReferencePrice__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            aux = aux.replace('&ITEM.ACTUALPRICE', this.printPrice(item.Price__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            aux = aux.replace('&ITEM.PRICENEEDED', this.printPrice(item.PriceNeeded__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            if (item.Status__c == 'REJECTED') {
                aux = aux.replace('&ITEM.APPROVEDPRICE','');
            } else {
                aux = aux.replace('&ITEM.APPROVEDPRICE',this.printPrice(item.ApprovedPrice__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            }
            aux += '</p>';
            loopIndex++;
        }

        aux += '</table>';

        body = body.replace('&ITEMS', aux);
        body = this.addHTMLTags(body);
        return body;
    }

    private String fillFactoryBody(String body, List<OppPriceRequestItem__c> items, String typeMail) {
        String reviewPageURL = URL.getOrgDomainUrl().toExternalForm() + '/lightning/n/Review_Factory_Pricing';
        String oppURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.priceRequest.Opportunity__c;
        String accountURL = URL.getOrgDomainUrl().toExternalForm() + '/' + this.priceRequest.Opportunity__r.AccountId;
        String ownerName = this.priceRequest.Opportunity__r.Owner.Name;
        String userName = UserInfo.getName();
        String aux = '';

        body = body.replace('&SUMMARY', this.getPriceRequestSummary());
        body = body.replace('&USERNAME', userName);
        body = body.replace('&OWNER.NAME', ownerName);
        body = body.replace('&OWNER.EMAIL', this.priceRequest.Opportunity__r.Owner.EMail);
        body = body.replace('&SALESORG', this.orgName);
        body = body.replace('&SALESOFFICE', this.officeName);
        body = body.replace('&ACCOUNT.NAME', this.priceRequest.Opportunity__r.Account.Name);
        body = body.replace('&ACCOUNT.URL', accountURL);
        body = body.replace('&NEEDEDBY', this.priceRequest.NeededBy__c != null ? (this.priceRequest.NeededBy__c).format() : '');
        body = body.replace('&APPROVECODE', this.priceRequest.ApproveCode__c != null ? this.priceRequest.ApproveCode__c : ' - ');
        body = body.replace('&NOTES', this.priceRequest.Notes__c != null ? this.priceRequest.Notes__c : '');
        body = body.replace('&OPP.NAME', this.priceRequest.Opportunity__r.Name);
        body = body.replace('&OPP.URL', oppURL);
        body = body.replace('&REVIEWPAGE', reviewPageURL);

        Integer loopIndex = 1;

        if (typeMail == 'APPROVAL' && items.size() > 0 ) {
            aux += '<tr>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_product+'</td>'
                    + '<td class="row-header" style="text-align: center;" colspan="2">'+System.Label.dict_productName+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_quantity+'</td>'
                    + '<td class="row-header" style="text-align: center;">Customer Price</td>'
                    + '<td class="row-header" style="text-align: center;">Customer Price Needed</td>'
                    + '<td class="row-header" style="text-align: center;">Factory Price</td>'
                    + '<td class="row-header" style="text-align: center;">Factory Price Needed</td>'
                    + '</tr>';
        }
        if (typeMail == 'REVIEWED' && items.size() > 0 ) {
            aux += '<tr>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.dict_product+'</td>'
                + '<td class="row-header" style="text-align: center;" colspan="2">'+System.Label.dict_productName+'</td>'
                + '<td class="row-header" style="text-align: center;">'+System.Label.dict_status+'</td>'
                + '<td class="row-header" style="text-align: center;">Customer Price</td>'
                + '<td class="row-header" style="text-align: center;">Customer Price Needed</td>'
                + '<td class="row-header" style="text-align: center;">Factory Price</td>'
                + '<td class="row-header" style="text-align: center;">Factory Price Needed</td>'
                + '<td class="row-header" style="text-align: center;">Factory Price Approved</td>'
                + '</tr>';
        }

        for (OppPriceRequestItem__c item : items) {
            aux += '<br/><p>';
            if (typeMail == 'APPROVAL') {
                aux += this.getPriceRequestItemFactoryApprovalSummary();
            }
            if (typeMail == 'REVIEWED') {
                aux += this.getPriceRequestItemFactoryReviewedSummary();
            }

            String textStatus = '';
            switch on item.FactoryStatus__c {
                when 'APPROVED' {
                    textStatus = System.Label.dict_approved;
                }
                when 'REJECTED' {
                    textStatus = System.Label.dict_rejected;
                }
                when 'APPROVEDPARTIALLY' {
                    textStatus = System.Label.prequest_part_approved;
                }
                when 'PENDING' {
                    textStatus = System.Label.dict_pending;
                }
            }

            aux = aux.replace('&ITEM.INDEX', this.printNumberTosString(loopIndex) + ' - Submitted at ' + (item.SubmittedDate__c != null ? item.SubmittedDate__c.format() : '-'));
            aux = aux.replace('&ITEM.CODE', item.ProductCodeFormula__c != null ? item.ProductCodeFormula__c : '');
            aux = aux.replace('&ITEM.STATUS', textStatus);
            aux = aux.replace('&ITEM.NAME', item.ProductNameFormula__c != null ? item.ProductNameFormula__c : '');
            aux = aux.replace('&ITEM.QUANTITY', item.Quantity__c != null ? item.Quantity__c : '');
            aux = aux.replace('&ITEM.CUSTOMERPRICENEEDED', this.printPrice(item.PriceNeeded__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            aux = aux.replace('&ITEM.CUSTOMERPRICE', this.printPrice(item.Price__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            aux = aux.replace('&ITEM.ACTUALPRICE', this.printPrice(item.FactoryPrice__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            aux = aux.replace('&ITEM.PRICENEEDED', this.printPrice(item.FactoryPriceNeeded__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            if (item.Status__c == 'REJECTED') {
                aux = aux.replace('&ITEM.APPROVEDPRICE','');
            } else {
                aux = aux.replace('&ITEM.APPROVEDPRICE',this.printPrice(item.FactoryApprovedPrice__c, item.CurrencyIsoCode) + ' / ' + item.UnitOfPrice__c);
            }
            aux += '</p>';
            loopIndex++;
        }

        aux += '</table>';

        body = body.replace('&ITEMS', aux);
        body = this.addHTMLTags(body);
        return body;
    }

    private String getPriceRequestSummary() {
        String body = '<table style="border-collapse:collapse;width:700px;">' +
                    + '<tr>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_opportunity+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_owner+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_salesOrg+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_sales_office+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.dict_account+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_needed_by+'</td>'
                    + '<td class="row-header" style="text-align: center;">'+System.Label.prequest_approve_code+'</td>'
                    + '</tr>'
                    + '<tr>'
                    + '<td style="text-align: center;"><a href="&OPP.URL">&OPP.NAME</a></td>'
                    + '<td style="text-align: center;"><a href="mailto:&OWNER.EMAIL">&OWNER.NAME</a></td>'
                    + '<td style="text-align: center;">&SALESORG</td>'
                    + '<td style="text-align: center;">&SALESOFFICE</td>'
                    + '<td style="text-align: center;"><a href="&ACCOUNT.URL">&ACCOUNT.NAME</a></td>'
                    + '<td style="text-align: center;">&NEEDEDBY</td>'
                    + '<td style="text-align: center;">&APPROVECODE</td>'
                    + '</tr>';
        return body;
    }

    private String getPriceRequestItemApprovalSummary() {
        String body = '<tr>'
        + '<td style="text-align: center;">&ITEM.CODE</td>'
        + '<td style="text-align: center;" colspan="2">&ITEM.NAME</td>'
        + '<td style="text-align: center;">&ITEM.QUANTITY</td>'
        + '<td style="text-align: center;">&ITEM.REFERENCEPRICE</td>'
        + '<td style="text-align: center;">&ITEM.ACTUALPRICE</td>'
        + '<td style="text-align: center;">&ITEM.PRICENEEDED</td>'
        + '</tr>';
        return body;
    }
    
    private String getPriceRequestItemReviewedSummary() {
        String body = '<tr>'
        + '<td style="text-align: center;">&ITEM.CODE</td>'
        + '<td style="text-align: center;" colspan="2">&ITEM.NAME</td>'
        + '<td style="text-align: center;" >&ITEM.STATUS</td>'
        + '<td style="text-align: center;">&ITEM.PRICENEEDED</td>'
        + '<td style="text-align: center;">&ITEM.APPROVEDPRICE</td>'
        + '</tr>';
        return body;
    }

    private String getPriceRequestItemFactoryApprovalSummary() {
        String body = '<tr>'
        + '<td style="text-align: center;">&ITEM.CODE</td>'
        + '<td style="text-align: center;" colspan="2">&ITEM.NAME</td>'
        + '<td style="text-align: center;">&ITEM.QUANTITY</td>'
        + '<td style="text-align: center;">&ITEM.CUSTOMERPRICE</td>'
        + '<td style="text-align: center;">&ITEM.CUSTOMERPRICENEEDED</td>'
        + '<td style="text-align: center;">&ITEM.ACTUALPRICE</td>'
        + '<td style="text-align: center;">&ITEM.PRICENEEDED</td>'
        + '</tr>';
        return body;
    }
    
    private String getPriceRequestItemFactoryReviewedSummary() {
        String body = '<tr>'
        + '<td style="text-align: center;">&ITEM.CODE</td>'
        + '<td style="text-align: center;" colspan="2">&ITEM.NAME</td>'
        + '<td style="text-align: center;" >&ITEM.STATUS</td>'
        + '<td style="text-align: center;">&ITEM.CUSTOMERPRICE</td>'
        + '<td style="text-align: center;">&ITEM.CUSTOMERPRICENEEDED</td>'
        + '<td style="text-align: center;">&ITEM.ACTUALPRICE</td>'
        + '<td style="text-align: center;">&ITEM.PRICENEEDED</td>'
        + '<td style="text-align: center;">&ITEM.APPROVEDPRICE</td>'
        + '</tr>';
        return body;
    }

    private String printPrice(Decimal value, String priceCurrency) {
        String aux = '';

        if (value != null) {
            switch on priceCurrency {
                when 'USD' {
                    aux += '$';
                }
                when 'EUR' {
                    aux += '€ ';
                }
                when 'GBP' {
                    aux += '£ ';
                }
                when 'CAD' {
                    aux += 'CA$ ';
                }
                when 'CHF' {
                    aux += 'CHF ';
                }
            }
            aux += this.printNumberTosString(value);
        }
        return aux;
    }

    private String printNumberTosString(Decimal value) {
        String aux = '';
        if (value != null) {
            aux = String.valueOf(value);
        }
        return aux;
    }

    
    private void readObjects(Id id, Set<Id> itemsIds) {
        if (this.currentId == null || this.currentId != id) {
            this.priceRequest = [select Id,Notes__c,NeededBy__c,CurrencyIsoCode,ApproveCode__c, Opportunity__r.Name,Opportunity__r.Id,Opportunity__r.Account.Name,Opportunity__r.Account.Id,
                                        Opportunity__r.Owner.Email,Opportunity__r.Owner.Name,Opportunity__r.Owner.Execution_Context__c,Opportunity__r.Owner.Sales_Office__c,
                                        Opportunity__r.Owner.Default_Sales_Organization__c, Opportunity__r.Owner.CountryCode,PendingItems__c,ApprovedItems__c,RejectedItems__c,
                                        CreatedBy.Email,CreatedBy.Name
                                        from OppPriceRequestHeader__c where Id =: id limit 1];
            if (itemsIds.size() > 0) {
                this.items = [SELECT Id,ApprovedPrice__c,Approver__c,Price__c,PriceNeeded__c,ReferencePrice__c,ProductCode__c, SubmittedDate__c, CreatedBy.Email,FactoryPrice__c, FactoryMargin__c,FactoryApprover__c,FactoryApprovedPrice__c,FactoryPriceNeeded__c,
                            ProductName__c,ProductNameFormula__c, ProductCodeFormula__c,FactoryStatus__c,Quantity__c,CurrencyIsoCode,toLabel(Status__c) labelStatus, toLabel(UnitOfPrice__c),Status__c,ReviewedDate__c, CreatedBy.Id,
                            SubmittedToFactoryManager__c,SubmittedToFactoryManager__r.Email,SubmittedToFactoryManager__r.Name,CreatedBy.Name
                            from OppPriceRequestItem__c where PriceRequestHeader__c =: id and Id IN : itemsIds
                            order by ReviewedDate__c DESC];
            } else {
                this.items = [SELECT Id,ApprovedPrice__c,Approver__c,Price__c,PriceNeeded__c,ReferencePrice__c,ProductCode__c, SubmittedDate__c, CreatedBy.Email,FactoryPrice__c, FactoryMargin__c,FactoryApprover__c,FactoryApprovedPrice__c,FactoryPriceNeeded__c,
                            ProductName__c,ProductNameFormula__c, FactoryStatus__c,ProductCodeFormula__c,Quantity__c,CurrencyIsoCode,toLabel(Status__c) labelStatus, toLabel(UnitOfPrice__c),Status__c,ReviewedDate__c, CreatedBy.Id,
                            SubmittedToFactoryManager__c,SubmittedToFactoryManager__r.Email,SubmittedToFactoryManager__r.Name,CreatedBy.Name
                            from OppPriceRequestItem__c where PriceRequestHeader__c =: id and ( Status__c <> null or Status__c <> '')
                            order by ReviewedDate__c DESC];
            }
            this.currentId = this.priceRequest.Id;
            this.orgName = OrganizationUtil.getSalesOrgName(this.priceRequest.Opportunity__r.Owner.Default_Sales_Organization__c); 
            this.officeName = OrganizationUtil.getSalesOfficeName(this.priceRequest.Opportunity__r.Owner.Sales_Office__c); 
        }
    }

    private void keepToApprovalItems() {
        List<OppPriceRequestItem__c> finalList = new List<OppPriceRequestItem__c>();
        for (OppPriceRequestItem__c item : this.items) {
            if (item.Status__c == 'PENDING' || item.FactoryStatus__c == 'PENDING') {
                finalList.add(item);
            }
        }
        this.items = finalList;
    }

    private void keepReviewedItems() {
        List<OppPriceRequestItem__c> finalList = new List<OppPriceRequestItem__c>();
        for (OppPriceRequestItem__c item : this.items) {
            if (item.Status__c == 'APPROVED' ||
                 item.FactoryStatus__c == 'APPROVED' ||
                 item.Status__c == 'APPROVEDPARTIALLY' ||
                 item.FactoryStatus__c == 'APPROVEDPARTIALLY' ||
                 item.Status__c == 'REJECTED' ||
                 item.FactoryStatus__c == 'REJECTED') {
                finalList.add(item);
            }
        }
        this.items = finalList;
    }

    private String addHTMLTags(String section) {
        String result = '<html><head><style>'
            + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 100; } '
            + 'a { color: #666; } '
            + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
            + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:5px;border:1px solid DimGray;font-size:12px;}'
            + '.row-header {background-color: #eff1f3;  font-weight: bold; width: 300px;} '
            + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
            + '.error-banner td {border-style:none; padding: 30px !important;} '
            + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
            + '.info-banner td {border-style:none;; padding: 30px !important;} '
            +  '</style></head><body>'
            +  section
            +  '</body></html>';
        return result;
    }

    /**
    * @description It gives the information of all the Price Request Approvers, looking first by sales office, then by sales org and at the end
    * by country code
    * @param salesOrg
    * @param salesOffice
    * @param countryCode
    * @return List of Users
    */
    public static List<User> getPriceApprovers(String salesOrg, String salesOffice, String countryCode) {
        List<User> users = new List<User>();
        Set<Id> usersIds = new Set<Id>();
        String nameGroupOffice = 'price_approvers_' + salesOffice;
        String nameGroupOrg = 'price_approvers_' + salesOrg;
        String nameGroupCountry = 'price_approvers_' + countryCode;

        List<GroupMember> groupMembersOffice = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupOffice];
        List<GroupMember> groupMembersOrg = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupOrg];
        List<GroupMember> groupMembersCountry = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupCountry];

        if (groupMembersOffice.size() > 0) {
            for (GroupMember elem : groupMembersOffice) {
                usersIds.add(elem.UserOrGroupId);
            }
            
            users = UserUtils.getData(usersIds);
        }
        if (groupMembersOrg.size() > 0) {
            for (GroupMember elem : groupMembersOrg) {
                usersIds.add(elem.UserOrGroupId);
            }
        } 
        if (groupMembersCountry.size() > 0) {
            for (GroupMember elem : groupMembersCountry) {
                usersIds.add(elem.UserOrGroupId);
            }
        }

        if (usersIds.size() > 0) {
            users = [Select Id, Email FROM USER where Id IN : usersIds];
        }

        return users;
    }

    public static List<User> getPriceFactoryApprovers(String salesOrg, String salesOffice, String countryCode) {
        List<User> users = new List<User>();
        Set<Id> usersIds = new Set<Id>();
        String nameGroupOffice = 'price_factory_approvers_' + salesOffice;
        String nameGroupOrg = 'price_factory_approvers_' + salesOrg;
        String nameGroupCountry = 'price_factory_approvers_' + countryCode;

        List<GroupMember> groupMembersOffice = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupOffice];
        List<GroupMember> groupMembersOrg = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupOrg];
        List<GroupMember> groupMembersCountry = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: nameGroupCountry];

        if (groupMembersOffice.size() > 0) {
            for (GroupMember elem : groupMembersOffice) {
                usersIds.add(elem.UserOrGroupId);
            }
            
            users = UserUtils.getData(usersIds);
        }
        if (groupMembersOrg.size() > 0) {
            for (GroupMember elem : groupMembersOrg) {
                usersIds.add(elem.UserOrGroupId);
            }
        } 
        if (groupMembersCountry.size() > 0) {
            for (GroupMember elem : groupMembersCountry) {
                usersIds.add(elem.UserOrGroupId);
            }
        }

        if (usersIds.size() > 0) {
            users = [Select Id, Email FROM USER where Id IN : usersIds];
        }

        return users;
    }

}