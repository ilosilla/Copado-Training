@SuppressWarnings('PMD.ExcessiveClassLength')
/**
 * @author         Ramón Prades
 * @date           October 2023
 * @description    SAP Cases email services
 * 
 * Translation prefix: tr0006
 */
public class SAPCasesMailerService {

    public enum CaseVariant {CLAIM_FACTORY_INQUIRY, CLAIM_NEW, CLAIM_APPROVAL}

    public static final String SAT_FACTORY_KEY = 'SAT-FACTORY-MAIL';
    public static final String SAT_FACTORY_DEFAULT = 'DEFAULT';
    
    String fixedLanguage;
    Case myCase;
    Facturas_cabeceraSet__x invoice;
    SAPCasesSettings__c settings;
    ProductListItem__c[] items;
    Account account;
    User caseOwner;
    String caseURL;
    String approvalURL;
    String approverId;
    Blob sapDocumentPDF = null;
    String customerEmail;
    String language = 'en_US';
    Boolean breaksDaysPolicy = false;
    Integer invoiceAgeDays = 0; 
    Boolean hasSpecialProducts = false;

    /**
     * CLAIMS - Factory inquiry
     */
    @future public static void AsyncFactoryInquiryMail(Id caseId) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.sendClaimToFactory();
    }

    /**
     * CLAIMS - New claim notification to customer
     */
    @future public static void AsyncSendClaimReceipt(Id caseId) {        
        try {
            SAPCasesMailerService service = new SAPCasesMailerService(caseId);
            service.sendClaimReceipt();
        } catch (Exception ex) {
            SystemLog logger = new SystemLog('ERRORS');
            logger.setSummary('Error on SAPCasesMailerService.AsyncSendClaimReceipt');
            logger.setInputData(caseId);
            logger.addError(ex);
            logger.saveLog(true);
        }
    }

    /**
     * CLAIMS - New claim notification
     */
    @future public static void AsyncNotifyNewClaim(Id caseId) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.notifyNewClaim();
    }

    /**
     * CLAIMS - Sends a standard email to the customer with the propsed solution
     */
    @future public static void AsyncSendClaimSolutionToCustomer(Id caseId, String email) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.setCustomerEmail(email);
        service.sendClaimSolutionToCustomer();
    }

    /**
     * Collections approval email
     */
    @future public static void AsyncRequestApproval(Id caseId) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.emailApprovalRequest();
    }

    /**
     * Collection note created
     */
    @future public static void AsyncCollectionNoteCreated(Id caseId, Blob pdf) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.sapDocumentPDF = pdf;
        service.emailTransport();        
    }

    /**
     * Collections credit note raised
     */
    @future public static void AsyncAccountsEmail(Id caseId, Blob pdf) {
        SAPCasesMailerService service = new SAPCasesMailerService(caseId);
        service.sapDocumentPDF = pdf;
        service.emailCreditToAccounts();
    }

    /***********************************************************
     * CONSTRUCTORS
     ***********************************************************/ 

    public SAPCasesMailerService(Id caseId) {
        Case c = new CasesSelector().selectById(new Set<Id>{caseId})[0];
        this.readCaseInformation(c);
    }

    public SAPCasesMailerService(Case c) {        
        this.readCaseInformation(c);
    }
    
    /**
     * To force a language (testing purposes mainly)
     */
    public void setFixedLanguage(String lang) {
        this.fixedLanguage = lang;
        this.setLanguageOptions(this.myCase.SalesOrg__c);
    }

    /***********************************************************
     * CLAIMS
     ***********************************************************/ 

     public void setCustomerEmail(String email) {
        this.customerEmail = email;
     }

    /**
     * Sends an email to the customer acknowledging the opening of the case
     */
    public void sendClaimReceipt() {
        Mail mailer = new Mail();
        mailer.setGeneric();
        
        if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
            mailer.setTo(new List<String>{this.settings.CLAIM_DebugEMail__c});
        } else {
            AccountProxy proxy = new AccountProxy(this.myCase.AccountId);
            mailer.setTo(new List<String>{proxy.email});
        }
        
        List<String> emails = new List<String>();
        if (String.isBlank(this.settings.CLAIM_DebugEMail__c)) {
            if (this.isUser(this.myCase.OwnerId)) {
                emails.add(this.caseOwner.Email);
            }
        }
        if (String.isNotBlank(this.settings.CLAIM_EmailService__c)) {
            emails.add(this.settings.CLAIM_EmailService__c);
        }
        if (emails.size() > 0) {
            mailer.setBcc(emails);
        }

        String subject = this.getLabel('tr0006_016').replace('{0}', this.myCase.CaseNumber); // Acknowledgement of your case {0}
        mailer.setSubject(subject);
        String html = this.getStyle() + this.buildClaimReceipt();
        mailer.setHtml(html);
        mailer.send();

    }

    /**
     * Sends an email when a claim is assigned to an agent
     */
    public void notifyNewClaim() {
        if (this.myCase.IsClaim__c) {
            List<String> emails = new List<String>();
            if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
                emails.add(this.settings.CLAIM_DebugEMail__c);
            } else {
                if (this.settings.CLAIM_NotifyNewToOwner__c && this.isUser(this.myCase.OwnerId)) {
                    emails.add(this.caseOwner.Email);
                }
                if (String.isNotBlank(this.settings.CLAIM_NotifyNewTo__c)) {
                    emails.addAll(this.settings.CLAIM_NotifyNewTo__c.split(';'));
                }
                if (emails.size() == 0) {
                    return;     // No email sent if owner is a queue
                }
            }
            Mail mailer = new Mail();
            mailer.setGeneric();
            mailer.setTo(emails);
            mailer.setSubject(this.getLabel('tr0006_017').replace('{0}', this.myCase.CaseNumber)); // New Claim Assignment (case {0});
            String html = this.getStyle() + this.buildClaimBody(CaseVariant.CLAIM_NEW);
            List<Mail.DownloadLinkInfo> links = mailer.addObjectAttachments(this.myCase.Id, true);

            String linksLabel = this.getLabel('tr0006_044');
            String auxText = SAPCasesMailerHelper.getLinkedFilesText(links, linksLabel);
            html = html.replace('{{LINKED-FILES}}', auxText);

            mailer.setHtml(html);
            mailer.send();
        }
    }

    /**
     * Sends an email with a claim to the selected factory contact
     */
    public void sendClaimToFactory() {
        if (this.myCase.IsClaim__c) {
            Mail mailer = new Mail();
            //mailer.setGeneric();
            mailer.setFrom(UserInfo.getUserEmail());            
            if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
                mailer.setTo(new List<String>{this.settings.CLAIM_DebugEMail__c});
            } else {
                List<String> emailList = SAPCasesMailerHelper.getSATFactoryEmail(this.myCase.FactoryInquiryContact__c, this.myCase.SalesOrg__c);
                if (emailList.size() == 0) {
                    emailList.add('rprades@porcelanosagrupo.com');
                }
                mailer.setTo(emailList);
                    
            }
            if (String.isNotBlank(this.settings.CLAIM_EmailService__c)) {
                mailer.setCc(new List<String>{this.settings.CLAIM_EmailService__c});
            }
            mailer.setSubject(this.getLabel('tr0006_018').replace('{0}', this.myCase.CaseNumber)); // Case {0} (Claim Inquiry)
            List<Mail.DownloadLinkInfo> links = mailer.addObjectAttachments(this.myCase.Id, true);
            
            String html = '<html>' + this.getStyle() + this.buildClaimBody(CaseVariant.CLAIM_FACTORY_INQUIRY) + '</html>';

            String linksLabel = this.getLabel('tr0006_044');
            String auxText = SAPCasesMailerHelper.getLinkedFilesText(links, linksLabel);
            html = html.replace('{{LINKED-FILES}}', auxText);

            mailer.setHtml(html);
            
            mailer.send();
        }
    }

    public void emailApprovalRequest() {
        if (this.myCase.IsCollection__c) {
            this.emailCollectionApproval();
        } else if (this.myCase.IsClaim__c) {
            this.emailClaimApproval();
        }
    }
    
    public void emailClaimApproval() {
        User[] approvers = this.getApprovers(true);
        if (approvers.size() == 0) {            
            Id myId = UserUtils.getUserIdFromEmail('rprades@porcelanosagrupo.com');
            User myself = new UsersSelector().selectById(myId);
            approvers.add(myself);
        }
        for (User approver : approvers) {
            this.approverId = approver.Id;
            Mail mailer = new Mail();
            mailer.setFrom(UserInfo.getUserEmail());
            if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
                mailer.setTo(new List<String>{this.settings.CLAIM_DebugEMail__c});
            } else {    
                mailer.setTo(new List<String>{approver.Email});
            }
            String subject = this.getLabel('tr0006_001').replace('{0}', this.myCase.CaseNumber); // Case {0} (Approval Request)
            mailer.setSubject(subject);
            String html = this.getStyle() + this.buildClaimBody(CaseVariant.CLAIM_APPROVAL);
            mailer.setHtml(html);
            mailer.send();
        }
    }

    public void sendClaimSolutionToCustomer() {
        if (this.myCase.IsClaim__c) {
            Mail mailer = new Mail();
            mailer.setFrom(UserInfo.getUserEmail());
            if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
                mailer.setTo(new List<String>{this.settings.CLAIM_DebugEMail__c});
            } else {
                mailer.setTo(new List<String>{this.customerEmail});
            }
            mailer.setBcc(new List<String>{UserInfo.getUserEmail()});
            if (String.isNotBlank(this.settings.CLAIM_EmailService__c)) {
                mailer.setCc(new List<String>{this.settings.CLAIM_EmailService__c});
            }
            mailer.setSubject(this.getLabel('tr0006_019').replace('{0}', this.myCase.CaseNumber)); // Claim Resolution Proposal (Case {0})
            String html = this.buildCustomerSolutionEmail();
            mailer.setHtml(html);
            mailer.send();
        }
    }


    /***********************************************************
     * COLLECTIONS
     ***********************************************************/ 
    public void emailCollectionApproval() {
        User[] approvers = this.getApprovers(false);
        if (approvers.size() == 0) {            
            Id myId = UserUtils.getUserIdFromEmail('rprades@porcelanosagrupo.com');
            User myself = new UsersSelector().selectById(myId);
            approvers.add(myself);
            //throw new ObjectNotFoundException('No approvers found');
        }
        for (User approver : approvers) {
            String html = this.getStyle() + this.buildApprovalEmail(approver);
            Mail mailer = new Mail();
            mailer.setGeneric();
            if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
                mailer.setTo(new List<String>{this.settings.CLAIM_DebugEMail__c});
            } else {    
                mailer.setTo(new List<String>{approver.Email});
            }
            mailer.setSubject(this.getLabel('tr0006_032')); // Customer Return Approval Request
            mailer.setHtml(html);
            mailer.setRelatedObjectId(this.myCase.Id);
            mailer.send();
        }
    }

    public void emailTransport() {
        String[] transportMails = this.getTransportEmails();
        if (this.myCase.SAPDeliveryNumber__c == null || transportMails.size() == 0) {
            return;
        }
        String subject = 'Collection Note #' + this.myCase.SAPDeliveryNumber__c + ' has been issued';
        Mail mail = new Mail();
        mail.setGeneric();
        mail.setSubject(subject);
        mail.setTo(transportMails);
        if (this.sapDocumentPDF == null) {
            this.sapDocumentPDF = SAPSalesDocumentService.downloadSAPDocument('D', this.myCase.SAPDeliveryNumber__c, 'ZE15');
        }
        if (this.sapDocumentPDF != null) {
            mail.addAttachment(this.myCase.SAPDeliveryNumber__c + '.pdf', this.sapDocumentPDF);
        }
        mail.addObjectAttachments(this.myCase.Id);
        String html = this.getStyle() + this.buildTransportEmail();
        mail.setHtml(html);
        mail.send();
    }        

    /**
     * Emails account to request a credit note for a collection
     */
    public void emailCreditToAccounts() {
        // Only if no refund is required
        if (this.myCase.RefundCustomer__c) { return; }

        String subject = 'Collection Credit Note Issued';
        Mail mail = new Mail();
        mail.setGeneric();

        List<String> emails = new List<String>();
        if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
            emails.add(this.settings.CLAIM_DebugEMail__c);
        } else if (String.IsNotBlank(this.settings.COL_AccountsEmails__c)) {
            emails = this.settings.COL_AccountsEmails__c.split(';');
        }
        
        String afterSalesChannels = this.settings.COL_AfterSalesChannels__c;
        if (String.IsNotBlank(afterSalesChannels) && afterSalesChannels.contains(this.invoice.Distchannel__c)) {
            emails = this.settings.COL_AfterSalesEmails__c.split(';');
        }

        if (emails.size() == 0) {
            return;
        }
        
        mail.setTo(emails);        
        mail.setSubject(subject);
        if (this.sapDocumentPDF == null) {
            this.sapDocumentPDF = SAPSalesDocumentService.downloadSAPDocument('I', this.myCase.SAPCreditNote__c);
        }
        if (this.sapDocumentPDF != null) {
            mail.addAttachment(this.myCase.SAPCreditNote__c + '.pdf', this.sapDocumentPDF);
        }
        String html = this.getStyle() + this.buildAccountsEmail();
        mail.setHtml(html);
        mail.send();
    } // 

    /**********/

    private void readCaseInformation(Case c) {
        this.myCase = c;
        this.invoice = new SAPInvoicesSelector().selectByNumber(this.myCase.SAPInvoice__c);
        this.settings = CasesDomain.getSAPSettings(this.invoice.SalesOrg__c, this.invoice.Ordernum__C);
        this.account = new AccountsSelector().selectById(new Set<Id>{this.myCase.AccountId})[0];
        // this.items = new ProductListItemsSelector().selectByCase(new Set<Id>{caseId});
        this.items = [select Id, Quantity__c, Unit__c, ProductCode__c, Product__r.Name from ProductListItem__c where Case__c = :this.myCase.Id order by SAPLine__c];
        this.caseURL = SystemCommons.getObjectURL(this.myCase.Id);    
        if (this.myCase.IsClaim__c) {
            this.approvalURL = EnterpriseSalesforceCatalog.CLAIMS_OPEN_API  + '/' + this.myCase.Id;
        } else if (this.myCase.IsCollection__c) { 
            this.approvalURL = EnterpriseSalesforceCatalog.COLLECTIONS_OPEN_API + '/' + this.myCase.Id;
            this.setCollectionReasons();
        }
        List<User> us = new UsersSelector().selectById(new Set<Id>{this.myCase.OwnerId});
        if (us.size() > 0) {
            this.caseOwner = us[0];
        } else {
            this.caseOwner = new UsersSelector().selectById(new Set<Id>{UserInfo.getUserId()})[0];
        }
        if (this.myCase.IsClaim__c) {
            this.setLanguageOptions(this.myCase.SalesOrg__c);
        }
    }

    private void setCollectionReasons() {
        Set<String> productCodes = new Set<String>();
        for (ProductListItem__c pli : this.items) {
            productCodes.add(pli.ProductCode__c);
        }  
        this.hasSpecialProducts = !(ProductCommons.checkStockProgram(this.invoice.SalesOrg__c, productCodes));
        this.invoiceAgeDays = this.myCase.CreatedDate.date().daysBetween(this.invoice.Orderdate__c.date());
        this.invoiceAgeDays = Math.abs(this.invoiceAgeDays);
        this.breaksDaysPolicy = (this.invoiceAgeDays > this.settings.COL_PolicyDays__c);

    }

    /** 
     * useClaims = true  - Claim approvers
     * useClaims = false - Collection approvers
     */
    private User[] getApprovers(Boolean useClaims) {
        User[] approvers = new List<User>();
        List<String> emails = new List<String>();
        String defaultApprovers = this.settings.COL_ApproverEmails__c;
        if (useClaims)  {
            defaultApprovers = this.settings.CLAIM_ApproverEmails__c;
        } 
        if (!useClaims && !this.hasSpecialProducts && this.settings.COL_AskManagerApproval__c) {
            String managers = SAPCasesMailerHelper.getReturnsApprover(this.myCase.OwnerId);
            if (String.isNotBlank(managers)) {
                defaultApprovers = managers + ';' + defaultApprovers;
            }
        }

        if (String.isNotBlank(defaultApprovers)) {
            emails = defaultApprovers.split(';');
        }

        String customPermission = CasesDomain.COL_APPROVER_CUSTOM_PERMISSION;
        if (useClaims) {
            customPermission = CasesDomain.CLAIM_APPROVER_CUSTOM_PERMISSION;
        }
        User[] users = UserUtils.getUsersFromEmails(emails);
        for (User u : users) {
            if (UserCommons.hasCustomPermission(u.Id, customPermission)) {
                approvers.add(u);
            }
        }
        return approvers;
    }

    private String[] getTransportEmails() {        
        if (String.isNotBlank(this.settings.CLAIM_DebugEMail__c)) {
            return new List<String>{this.settings.CLAIM_DebugEMail__c};
        } else if (String.isNotBlank(this.settings.COL_TransportEmails__c)) {
            return this.settings.COL_TransportEmails__c.split(';');
        } else {
            return new List<String>();
        }
    }    

    private String buildApprovalEmail(User approver) {     
        String approveLink = this.approvalURL + '?approvedBy=' + approver.Id;
        String here = '<a href="' + this.caseURL + '">' + this.getLabel('dict_here') + '</a>';
        Map<String, String> reasons = PicklistCommons.getValues(Case.Reason);
        String mailTo = UserInfo.getUserEmail() + '?subject=Collection #' + this.myCase.caseNumber + ' rejected!&Body=Ref: ' + this.caseUrl ;
        String requester = '<a href="mailto:' + mailTo + '">' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</a>';

        String body = '<body class="backdrop">';
        body += '<div class="canvas">';

        body += '<div class="page-header">';
        body += '<h2 class="page-title">' + this.getLabel('tr0006_031')?.toUpperCase() + '</h2>';
        body += '</div>';

        body += '<div class="page-content">';
        body += '<p>' + this.getLabel('tr0006_033') + '</p>';

        if (this.hasSpecialProducts && this.breaksDaysPolicy) {
            body += '<p><b>' + this.getLabel('tr0006_043') + '</b></p>';
        } else if (this.hasSpecialProducts) {
            body += '<p><b>' + this.getLabel('tr0006_041') + '</b></p>';
        } else if (this.breaksDaysPolicy) {
            body += '<p><b>' + this.getLabel('tr0006_042') + '</b></p>';
        }       

        body += '</p>';
        body += '<table width="100%" celspacing="0" cellpadding="0" class="box1">';
        body += '<tr><td colspan="2"><span class="label1">' + this.getLabel('dict_subject') + ':</span><br/>' + this.myCase.Subject + '</td></tr>';
        body += '<tr><td colspan="2"><span class="label1">' + this.getLabel('tr0006_035') + ':</span><br/>' + reasons.get(this.myCase.Reason) + '</td></tr>';
        body += '<tr><td colspan="2"><span class="label1">' + this.getLabel('dict_account') + ':</span><br/>' + this.account.Name + '</td></tr>';
        body += '<tr><td><span class="label1">' + this.getLabel('dict_invoice_no') + ':</span><br/>' + this.invoice.Ordernum__c + '</td>';
        body += '<td><span class="label1">' + this.getLabel('dict_invoice_date') + ':</span><br/>' + this.invoice.Orderdate__c.date().format() + '</td></tr>';
        body += '</table>';

        // body += '<p>Items to return:</p>';
        body += '<table width="100%" celspacing="0" cellpadding="0" class="box1" style="margin-top:1rem;">';
        body += '<thead><tr><th>' + this.getLabel('dict_quantity') + '</th><th>' + this.getLabel('dict_productName') + '</th><th>' + this.getLabel('dict_product_code') + '</th></tr></thead>';

        for (ProductListItem__c item : this.items) {
            String itemLine ='<tr><td>&QUANTITY</td><td>&NAME</td><td>&CODE</td></tr>';
            itemLine = itemLine.replace('&QUANTITY', item.Quantity__c + ' ' + item.Unit__c);
            itemLine = itemLine.replace('&NAME', item.Product__r?.Name ?? '');
            itemLine = itemLine.replace('&CODE', item.ProductCode__c);
            body += itemLine;
        }
        body += '</table>';

        String description = this.myCase.Description;
        if (String.isBlank(description)) {
            description = '(' + this.getLabel('tr0006_036') + ')';
        }

        String comments = this.myCase.Comments;
        if (String.isBlank(comments)) {
            comments = '(' + this.getLabel('tr0006_037') + ')';
        }        

        body += '<table width="100%" celspacing="0" cellpadding="0" class="box1" style="margin-top:1rem;">';
        body += '<tr><td><span class="label1">' + this.getLabel('dict_description') + '</span><br/>' + description + '</td></tr>';
        //body += '<tr><td><span class="label1">Internal Comments:</span><br/>' + comments + '</td></tr>';
        body += '</table>';

        body += '<p>' + this.getLabel('tr0006_038') + '</p>';
        body += '<a class="big-button" href="' + approveLink + '">' + this.getLabel('tr0006_039') + '</a>';
        body += '<p>' + this.getLabel('tr0006_040') + '.</p>';
        body += '</div>';

        body += '</div>';

        body += '<div style="font-size:.8rem; line-height:1.2rem; text-align:center; margin-top:20px; margin-bottom: 20px;">';
        body += '<p>Porcelanosa Salesforce</p><br/>';
        body += '</div>';

        body +='</body>';

        body = body.replace('{{REQUESTER}}', requester);
        body = body.replace('{{HERE}}', here);
        Integer ndays = this.settings?.COL_PolicyDays__c?.intValue() ?? 28;
        body = body.replace('{{DAYS}}', String.valueOf(ndays));
        return body;
    }

    private String buildTransportEmail() {     
        AddressDTO address = null;
        if (this.myCase.ContactPointAddress__c != null) {
            address = AddressDTO.readContactPointAddress(this.myCase.ContactPointAddress__c);
        } else {
            address = addressDTO.readFromAccount(this.myCase.AccountId);
        }            
        String body = '<body class="backdrop"><br/><br/>';
        body += '<div class="canvas">';

        body += '<div class="page-header">';
        body += '<h2 class="page-title">Collection Note #' + this.myCase.SAPDeliveryNumber__c + ' Issued</h2>';
        body += '</div>';

        body += '<div class="page-content">';
        body += '<p>We would like to inform you that a new collection request has been initiated.';
        body += ' Please take the necessary steps to ensure the collection of goods on the requested date.</p>';
        body += '<p>Collection Details:</p>';
        body += '<ul>';
        body += '<li>Collection Number: ' + this.myCase.SAPDeliveryNumber__c + '</li>';
        body += '<li>Customer Name: ' + this.account.Name + '</li>';
        body += '<li>Collection Date:' + this.myCase.CollectionDate__c + '</li>';
        body += '<li>Collection Address:<br/>' + new AddressFormatter(address).formatAsHTML();
        body += '<li>Phone: ' + TypeConversionCommons.deNullify(address.phone1);
        if (String.IsNotBlank(address.phone2)) {
            body += ' - ' + TypeConversionCommons.deNullify(address.phone2);
         }
        body += '</li>';
        body += '</ul>';
        body += '<p>The collection note is attached to this email for your convenience.</p>';
        body += '<p>Best regards</p>';

        body += '</div>';
        body += '</div>';

        body += '<div style="font-size:.8rem; line-height:1.2rem; text-align:center; margin-top:20px; margin-bottom: 20px;">';
        body += '<p>Porcelanosa Salesforce</p><br/>';
        body += '</div>';

        body +='</body>';

        return body;
    } // buildTransportEmail

    private String buildAccountsEmail() {     
        AddressDTO address = null;
        if (this.myCase.ContactPointAddress__c != null) {
            address = AddressDTO.readContactPointAddress(this.myCase.ContactPointAddress__c);
        } else {
            address = addressDTO.readFromAccount(this.myCase.AccountId);
        }            
        String body = '<body class="backdrop"><br/><br/>';
        body += '<div class="canvas">';

        body += '<div class="page-header">';
        body += '<h2 class="page-title">Credit Note #' + this.myCase.SAPCreditNote__c + ' Issued</h2>';
        body += '</div>';

        body += '<div class="page-content">';
        body += '<p>This is an automated notification to inform you of the issuance of a credit note for a customer return.';
        if (!this.myCase.RefundCustomer__c) {
            body += ' <b>Please note that no refund is required for this transaction</b>.';
        }
        body += '</p>';
        body += '<p>Details of the transaction are as follows:</p>';
        body += '<ul>';
        body += '<li>Customer Name: ' + this.account.Name + '</li>';
        body += '<li>Credit Note: ' + this.myCase.SAPCreditNote__c + '</li>';
        body += '<li>Credited Invoice: ' + this.myCase.SAPInvoice__c + '</li>';
        body += '<li>Case Owner: <a href="mailto:' +  this.caseOwner.email + '">' + this.caseOwner.Name + '</a></li>';
        body += '</ul>';
        body += '<p>The credit note note is attached to this email for your convenience.</p>';
        body += '<p>This is an automated message, please do not reply.</p>';
        body += '</div>';
        body += '</div>';

        body += '<div style="font-size:.8rem; line-height:1.2rem; text-align:center; margin-top:20px; margin-bottom: 20px;">';
        body += '<p>Porcelanosa Salesforce</p><br/>';
        body += '</div>';

        body +='</body>';

        return body;
    } // buildAccountsEmail

    /*
     * Claim details
     */
    private String buildClaimBody(CaseVariant variant) {      
        String body = '<body class="backdrop">';
        body += '<div class="canvas">';

        body += '<div class="page-header">';
        if (variant == CaseVariant.CLAIM_APPROVAL) {
            body += '<span class="page-title">' + this.getLabel('tr0006_002') + '</span>'; // Claim Solution Approval
        } else {
            body += '<span class="page-title">' + this.getLabel('tr0006_003') + '</span>'; // Product Claim
        }
        body += '<span class="page-subtitle">' + this.myCase.ProductName__c + '</span>';
        body += '</div>';
        
        body += '<div class="page-content">';
        body += this.buildClaimIntro(variant);
        body += this.buildClaimSummary(variant);

        body += '</div>';
        body += '</div>';
        body += '</body>';

        return body; 

    } 

    private String buildClaimIntro(CaseVariant variant) {
        
        String intro = '';

        switch on variant {
            when CLAIM_FACTORY_INQUIRY {   
                /*
                * This is an automated email to inform you that we have received a claim from a customer regarding one of 
                * your products. Below are the observations from our after-sales agent, followed by the complete details of the claim for your 
                * review. To ensure your response is correctly associated with the case, please make sure your reply includes all the addresses 
                * listed in this email. Thank you for your prompt attention to this matter.
                * Best regards.
                */            
                intro = this.getLabel('tr0006_020');
                intro = intro.replace('{0}', this.myCase.FactoryInquiryComments__c ?? '')
                    .replace('{1}', UserInfo.getName())
                    .replace('{2}', OrganizationUtil.getSalesOrgName(BusinessStructureCommons.getRedirectedSalesOrg(this.invoice.Salesorg__c)));
                if (String.isNotBlank(this.settings.CLAIM_EmailService__c)) {
                    /*
                    * The email address {0} 
                    * in the recipients list is legitimate and will 
                    * automatically process your response, linking it to 
                    * the case.
                    */
                    intro += '<p class="footnote">' + this.getLabel('tr0006_021').replace('{0}', this.settings.CLAIM_EmailService__c) + '</p>';
                    intro += '<span style="display:none;visibility:hidden;overflow:hidden;height:0; width:0">%form-id:[CLAIM_FACTORY_INQUIRY]%</span>'; // form id to identify tyhe inquiry
                }
            }

            when CLAIM_NEW {
                // This is an automated email generated by our system to 
                // inform you that a new claim has been assigned to you 
                // for processing. Please prioritize this claim and ensure 
                // all necessary steps are taken promptly to address the 
                // customer's needs. You can see the details of the claim 
                // below, or you can view it in Salesforce. Thank you for 
                // your prompt attention to this matter. Best regards. 
                // Salesforce Team
                String link = '<a href="' + this.caseURL + '">' + this.getLabel('dict_click_here') + '</a>';
                intro = this.getLabel('tr0006_022').replace('{0}', link);
            }

            when CLAIM_APPROVAL {
                intro = this.getClaimApprovalIntro();
                intro += this.getLabel('tr0006_008'); //'<p>Thank you for your prompt attention to this matter.</p><p>Best regards.</p><p>Salesforce Team</p>
            }
        }
        return intro;
    }

    private String buildClaimSummary(CaseVariant variant) {

        Map<String, String> unitNames = PicklistCommons.getValues(Case.Unit__c);
        Map<String, String> warrantyOptions = PicklistCommons.getValues(Case.Warranty__c);
        Map<String, String> problemOptions = PicklistCommons.getValues(Case.Problem__c);
        Map<String, String> productTypeOptions = PicklistCommons.getValues(Case.ProductType__c);
        Map<String, String> symptomOptions = PicklistCommons.getValues(Case.Symptoms__c);
        Map<String, String> symptomDetailsOptions = PicklistCommons.getValues(Case.SymptomsDetails__c);
        Map<String, String> causeOptions = PicklistCommons.getValues(Case.LikelyCause__c);
        Map<String, String> solutionOptions = PicklistCommons.getValues(Case.RecommendedCure__c);
        Map<String, String> statusOptions = PicklistCommons.getValues(Case.Status);

        Integer daysOpened = this.myCase.CreatedDate.dateGMT().daysBetween(Date.today());
        String daysOpenedText = daysOpened == 0 ? 'Today' : String.valueOf(daysOpened);
        String yes = this.getLabel('dict_yes');
        String no = this.getLabel('dict_no');
        
        String body = '';
        /*
        if (variant == CaseVariant.CLAIM_FACTORY_INQUIRY && this.myCase.FactoryInquiryComments__c != null) {
            body += '<span class="page-section">' + this.getLabel('claim_inquiry_section') + '</span>';
            body += '<table width="100%" class="white-box painted-cells">';
            body += '<tr><td colspan="6"><span class="label1">' + this.getFieldLabel('Case', 'FactoryInquiryComments__c') + ':</span><br/>' + this.myCase.FactoryInquiryComments__c + '</td></tr>';
            body += '<tr><td colspan="6"><span class="label1">' + this.getFieldLabel('Case', 'FactoryInvoice__c') + ':</span><br/>' + this.myCase.FactoryInvoice__c + '</td></tr>';
            body += '</table>';
        }
            */

        body += '<span class="page-section">' + this.getLabel('tr0006_009') + '</span>';
        body += '<table width="100%" class="white-box painted-cells">';
        body += '<tr><td colspan="4"><span class="label1">' + this.getFieldLabel('Case', 'Subject') + ':</span><br/>' + this.myCase.Subject + '</td>';
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'Status') + ':</span><br/>' + statusOptions.get(this.myCase.Status) + '</td></tr>';
        body += '</tr>';
        
        body += '<tr><td colspan="4"><span class="label1">' + this.getFieldLabel('Case', 'ProductName__c') + ':</span><br/>' + this.myCase.ProductCode__c + ' - ' + this.myCase.ProductName__c + '</td>';
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'Quantity__c') + ':</span><br/>' + this.myCase.Quantity__c + ' ' + unitNames.get(this.myCase.Unit__c) + '</td></tr>';
        
        body += '<tr>';
        body += '<td colspan="6"><span class="label1">' + this.getFieldLabel('Case', 'Description') + ':</span><br/>' + (this.myCase.Description ?? '--') + '</td>';        
        body += '</tr>';
        
        body += '<tr>';
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'CaseNumber') + ':</span><br/>' + this.myCase.CaseNumber + '</td>';        
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'CreatedDate') + ':</span><br/>' + this.myCase.CreatedDate.format() + '</td>';    
        
        if (this.myCase.ClosedDate != null) {
            body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'ClosedDate') + ':</span><br/>' + this.myCase.ClosedDate.date() + '</td>';        
        } else {
            body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'DaysOpened') + ':</span><br/>' + daysOpenedText + '</td>';        
        }
        body += '</tr>';
        
        body += '</table>';
        
        body += '<span class="page-section">' + this.getLabel('tr0006_010') + '</span>'; // Invoice Details'
        body += '<table width="100%" class="white-box painted-cells">';
        
        body += '<tr>';
        body += '<td colspan="4"><span class="label1">' + this.getFieldLabel('Case', 'CustomerName') + ':</span><br/>' + this.account.Name + '</td>';        
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'SAP_Id__c') + ':</span><br/>' + this.account.SAP_Id__c + '</td>';        
        body += '</tr>';
        
        body += '<tr>';
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'Ordernum__c') + ':</span><br/>' + this.invoice.Ordernum__c + '</td>';    
        body += '<td colspan=""><span class="label1">' + this.getFieldLabel('Case', 'Orderdate__c') + ':</span><br/>' + this.invoice.Orderdate__c.date().format() + '</td>';
        body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'Warranty__c') + ':</span><br/>' +(warrantyOptions.get(this.myCase.Warranty__c) ?? '--') + '</td>';
        body += '</tr>';
        
        body += '<tr><td colspan="6"><span class="label1">' + this.getFieldLabel('Case', 'Salesorg__c') + ':</span><br/>' + '[' + this.invoice.Salesorg__c + '] ' + OrganizationUtil.getSalesOrgName(BusinessStructureCommons.getRedirectedSalesOrg(this.invoice.Salesorg__c)) + '</td></tr>';
        body += '</table>';
        
        body += '<span class="page-section">' + this.getLabel('tr0006_011') + '</span>'; // Problem Qualification
        body += '<table width="100%" class="white-box painted-cells">';
        
        body += '<tr>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'Problem__c') + ':</span><br/>' + (problemOptions.get(this.myCase.Problem__c) ?? '--') + '</td>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'ProductType__c') + ':</span><br/>' + (productTypeOptions.get(this.myCase.ProductType__c) ?? '--') + '</td>';
        body += '</tr>';
        
        body += '<tr>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'Symptoms__c') + ':</span><br/>' + (symptomOptions.get(this.myCase.Symptoms__c) ?? '--') + '</td>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'SymptomsDetails__c') + ':</span><br/>' + (symptomDetailsOptions.get(this.myCase.SymptomsDetails__c) ?? '--') + '</td>';
        body += '</tr>';
        
        body += '<tr>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'LikelyCause__c') + ':</span><br/>' + (causeOptions.get(this.myCase.LikelyCause__c) ?? '--') + '</td>';
        body += '<td colspan="3"><span class="label1">' + this.getFieldLabel('Case', 'RecommendedCure__c') + ':</span><br/>' + (solutionOptions.get(this.myCase.RecommendedCure__c) ?? '--') + '</td>';
        body += '</tr>';
        
        body += '</table>';
        
        if (this.myCase.RecommendedCure__c != null) {
            body += '<span class="page-section">' + this.getLabel('tr0006_012') + '</span>'; // Solution Proposed
            body += '<table width="100%" class="white-box painted-cells">';
            body += '<tr><td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'SupplyReplacement__c') + ':</span><br/>';
            if (this.myCase.SupplyReplacement__c) {
                body += yes.toUpperCase();
            } else {
                body += no.toUpperCase();
            }
            body += '</td>';
            body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'SupplyInstallation__c') + ':</span><br/>';
            if (this.myCase.SupplyInstallation__c) {
                body += yes.toUpperCase();
            } else {
                body += no.toUpperCase();
            }
            body += '</td>';
            body += '<td colspan="2"><span class="label1">' + this.getFieldLabel('Case', 'Compensation__c') + ':</span><br/>' + this.myCase.Compensation__c + ' ' + this.myCase.CurrencyIsoCode + '</td>';
        
            String text = this.getLabel('tr0006_013'); // Proposal not sent to the customer yet
            if (this.myCase.CustomerAgreed__c != null) {
                text = this.getLabel('tr0006_014').replace('{0}', this.myCase.CustomerAgreed__c.format()); // Proposed solution accepted by the customer on {0}
            } else if (this.myCase.ProposalDate__c != null) {
                text = this.getLabel('tr0006_015').replace('{0}', this.myCase.ProposalDate__c.format()); // Proposed solution sent to the customer on {0}
            }
        
            body += '<tr>';
            body += '<td colspan="6"><p><b>' + text + '</b></p></td>';
            body += '</tr>';
            body += '</table>';
        }
        
        return body;
    }
        
    private String getClaimApprovalIntro() {     
        String approveLink = this.approvalURL + '?approvedBy=' + this.approverId;
        String here = '<a href="' + this.caseURL + '">' + this.getLabel('dict_here') + '</a>';
        String subject = this.getLabel('tr0006_004').replace('{0}', this.myCase.caseNumber); // Claim #{0} rejected!
        String mailTo = UserInfo.getUserEmail() + '?subject='+ subject + '&Body=Ref: ' + this.caseUrl;
        String requester = '<a href="mailto:' + mailTo + '">' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</a>';

        // <p>{0} has requested your approval for the proposed solution of paying <b>{1} {2}</b> as settlement for the claim detailed below.</p>
        // <p>Click {3} to view the full case details, or use the link below to approve the solution directly.</p>
        String body = this.getLabel('tr0006_005')
            .replace('{0}', requester)
            .replace('{1}', String.valueOf(this.myCase.Compensation__c ?? 0))
            .replace('{2}', this.myCase.CurrencyIsoCode)
            .replace('{3}', here);
        body += '<a class="big-button" href="{approveLink}">' + this.getLabel('tr0006_006')?.toUpperCase() + '</a>';
        body += this.getLabel('tr0006_007')?.replace('{0}', requester);
        body = body.replace('{approveLink}', approveLink);    
        return body;
    }
    public String buildCustomerSolutionEmail() {
        Integer nsolutions = 0;
        if (this.myCase.SupplyReplacement__c) {
            nsolutions++;
        }
        if (this.myCase.Compensation__c > 0) {
            nsolutions++;
        }
        if (this.myCase.SupplyInstallation__c) {
            nsolutions++;
        }
        String html = '<style>' 
            + 'body {background-color: #f0f4f8;font-family: Arial, sans-serif;margin: 0;padding: 20px;}'
            + '.email-container {max-width: 600px;margin: 0 auto;background-color: #ffffff;border-radius: 8px;padding: 20px;box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);border-top: 8px solid #4a90e2;'
            + '.logo {text-align: center;margin-bottom: 20px;}'
            + 'ul {margin: 10px 0;padding-left: 20px;}'
            + 'li {margin-bottom: 10px;}'
            + '</style>';

        html = '<body><div class="email-container">';

        // Dear customer, We sincerely apologize for the 
        // inconvenience you have experienced with our product. 
        // At Porcelanosa, we strive to deliver the highest 
        // quality, and it is regrettable that we did not meet 
        // your expectations on this occasion. After reviewing 
        // your claim, we would like to propose the following 
        // solution(s) to resolve the issue.
        
        html += this.getLabel('tr0006_023');

        if (nsolutions == 1) {
            html +=  this.getLabel('tr0006_024');
        } else {
            html +=  this.getLabel('tr0006_025');
        }
        html += '<ul>';

        if (this.myCase.SupplyReplacement__c) {
            html += '<li>' + this.getLabel('tr0006_026') + '</li>'; // The products will be replaced free of charge.
        }
        if (this.myCase.Compensation__c > 0) {
            String text = this.getLabel('tr0006_027').replace('{0}', String.valueOf(this.myCase.Compensation__c)).replace('{1}', this.myCase.CurrencyIsoCode);            
            html += '<li>' + text + '</li>'; // We are offering a compensation of 9 XXX for the trouble caused
        }
        if (this.myCase.SupplyInstallation__c) {
            html += '<li>' + this.getLabel('tr0006_028') + '</li>'; // We will cover all expenses for refitting the product.
        }
        html += '</ul>';

        // Please review these options and let us know if they 
        // are acceptable to you by replying to all recipients. 
        // If you accept the proposed solution, we will 
        // immediately begin making the necessary arrangements 
        // to execute it as quickly as possible. If you have any 
        // further concerns or would like to discuss alternative 
        // solutions, feel free to let us know, and we will be 
        // happy to assist you further. Once again, we apologize 
        // for the inconvenience and appreciate your patience 
        // and understanding. Best regards, 
        // Name Surname 
        // Aftersales Department

        html += this.getLabel('tr0006_029').replace('{0}', UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        html += 'PORCELANOSA</p>'
            + '<div class="logo">'
            + '<img src="https://mgt-media.porcelanosa.com/media/icons/PORCELANOSA-Grupo-Prince.png" alt="Company Logo" width="150">'
            + '</div></body>';

        return html;
    }

    /**
     * Dear customer,
     * We are truly sorry to hear about the issue you’ve experienced with one of our products&PRODUCTNAME&.
     * Please accept our sincere apologies for any inconvenience this may have caused.
     * Rest assured, our team is looking into the matter, and we will work on finding a solution as quickly as possible.
     * We will keep you updated on the progress and aim to resolve this for you promptly.
     * If you have any further details to share or questions in the meantime, please feel free to reach out.
     * Thank you for your patience and understanding.
     */
    public String buildClaimReceipt() {

        String productString = '';
        if (String.isNotBlank(this.myCase.ProductName__c)) {
            productString = ' (' + this.myCase.ProductName__c + ')';
        }

        String html = '<style>' 
            + 'body {font-family: Arial, sans-serif;margin: 0;padding: 20px;}'
            + '.email-container {max-width: 600px;margin: 0 auto;'
            + '.logo {text-align: center;margin-bottom: 20px;}'
            + 'ul {margin: 10px 0;padding-left: 20px;}'
            + 'li {margin-bottom: 10px;}'
            + '</style>';

        html += '<body><div class="email-container">';                
        html += this.getLabel('tr0006_030').replace('{{PRODUCTNAME}}', productString);
        html += this.getSignature();
        html += '</body>';
        
        html = html.replace('&PRODUCTNAME&', productString);

        return html;
    }

    private String getStyle() {
        String style = '<head><style>'
            + '.backdrop {height:100%; min-height:auto; background-color:#f1f1f1; padding:20px 0px 20px 0px;font-family: Arial, sans-serif;font-size: 15px;}'
            + '.footnote {font-size: 12px; border-top: 1px solid #6c757d; border-bottom: 1px solid #6c757d; font-style: italic; margin-top: 8px; margin-bottom: 16px; padding: 8px 0;}'
            + '.canvas {color: #373230; width:700px; max-width:100%; background-color: white;border: 1px solid #d6d6d6;padding: 0px 0px; margin: 0 auto;}'
            + '.page-header {background-color: #60676C; padding: 20px 20px;}'
            + '.page-title {color: white; font-weight: 200;display:block;font-size:24px;}'            
            + '.page-subtitle {color: white; font-weight: 200;display:block;font-size:16px;}'
            + '.page-section {font-weight: 400; display:block; font-size:20px; border-bottom: 1px solid #d6d6d6;margin: 0.5rem 0;}'
            + '.page-content {padding: 20px 20px;}'
            + '.box1 {background-color: #f6f8f8; border: 0px solid #d6d6d6; padding: 10px;}'
            + '.white-box {background-color: #fff; border: 0px;}'
            + '.painted-cells  {border-spacing: 4px;}'
            + '.painted-cells td {background-color: #f6f8f8; padding: 4px 8px;}'
            + '.label1 {font-size:.8rem; margin-bottom: 10px;}'
            + '.big-button { display: block; margin:20px 100px; padding: 20px; background-color: #C2B280; color: white; text-align: center;}'
            + 'thead tr {border-bottom: 1px solid black;}'
            + 'th {font-size: .8rem;text-align: left; font-weight: 300;}'
            + '</style></head>';
        return style;
    }

    private Boolean isUser(Id theId) {
        Schema.SObjectType sObjectType = theId.getSObjectType();
        String sObjectName = sObjectType.getDescribe().getName();
        return (sObjectName?.toLowerCase() == 'user' );
    }

    /**
     * Sets the language options
     */
    private void setLanguageOptions(String salesOrg) {
        if (String.isNotBlank(this.fixedLanguage)) {
            this.language = this.fixedLanguage;
            return;
        }
        if (salesOrg?.left(1) == '2') {
            this.language = 'fr';
        } else {
            this.language = 'en_US';
        }        
    }

    /**
     * Gets the email signature
     */
    private String getSignature() {
        String html = this.settings.CLAIM_Signature__c;
        String logo = this.settings.CLAIM_SignatureLogo__c;
        if (String.isNotBlank(logo)) {
            html += '<div class="logo">'
                + '<img src="' + logo + '" alt="Company Logo" width="150">'
                + '</div>';    
        }
        return html;
    }

    /**
     * Gets a custom label
     */
    private String getLabel(String customLabel) {
        String label = '';
        try {
            label = System.Label.get('', customLabel, this.language);
        } catch (Exception ex) {
            label = customLabel;
        }
        return label;
    }

    /**
     * Gets a field's label
     */
    private String getFieldLabel(String objectName, String fieldName) {
        String customLabel = 'obj_' + objectName.toLowerCase() + '_' + fieldName.toLowerCase();        
        return this.getLabel(customLabel.replace('__c', '_c'));
    }

}