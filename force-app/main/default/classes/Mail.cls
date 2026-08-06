@SuppressWarnings('PMD.ExcessiveParameterList')
public class Mail {

    public Integer ValidityHours = 72;

    private Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
    private List<Messaging.EmailFileAttachment> files = new List<Messaging.EmailFileAttachment>();
    private String genericMail = 'salesforce@porcelanosagrupo.com';
    public List<String> developerMail = new List<String>{'salesforce.dev@porcelanosagrupo.com'};
    private String textVersion;

    public Mail() {
        this.setTo(new List<String>());
        this.setCc(new List<String>());
        this.setBcc(new List<String>());
        this.setSubject('Default Subject');
        this.setHtml('<html></html>');
    }

    // ********************************* SETTERS ***********************************************

    /**
    * @description Sets the From of the mail to the genericMail. Organization-Wide Address needs to exist https://help.salesforce.com/articleView?id=orgwide_email.htm&type=5
    */
    public void setGeneric() {
        this.setFrom(this.genericMail);
    }

    public void setFrom(String fromString) {
            List<OrgWideEmailAddress> owea = [select Id from OrgWideEmailAddress where Address =: fromString];
        if ( owea.size() > 0 ) {
            this.mail.setOrgWideEmailAddressId(owea.get(0).Id);
            this.mail.setUseSignature(false);
        }
    }

    public void setFrom(Id fromId) {
        this.setFrom(MailUtils.getMail(fromId)[0]);
    }
    
    public void setTo(List<String> emails) {
        this.mail.setToAddresses(emails);
    }

    public void setTo(Id objectId) {
        this.mail.setToAddresses(MailUtils.getMail(objectid));
    }
    
    public void setCc(List<String> ccMailAccounts) {
        this.mail.setCcAddresses(ccMailAccounts);
    }

    public void setCc(Id ccMailAccount) {
        this.mail.setCcAddresses(MailUtils.getMail(ccMailAccount));
    }
    
    public void setBcc(List<String> bccMailAccounts) {
        this.mail.setBccAddresses(bccMailAccounts);
    }

    public void setBcc(Id bccMailAccount) {
        this.mail.setBccAddresses(MailUtils.getMail(bccMailAccount));
    }

    public void setSubject(String subjectString) {
        this.mail.setSubject(subjectString);
    }

    public void setHtml(String html) {
        this.mail.setHtmlBody(html);
    }
    
    public void setAttachments(List<Id> attachments) {
        this.mail.setEntityAttachments(attachments);
    }    

    public void addObjectAttachments(String objectId) {
        List<ContentVersion> lfiles = AttachmentUtils.getSObjectAttachments(objectId);
        Set<Id> ids = TypeConversionCommons.listToSet(lfiles);
        ContentVersion[] cvs = [select Id, PathOnCLient, VersionData from ContentVersion where id in :ids];
        for (ContentVersion cv : cvs) {  
            this.addAttachment(cv.PathOnClient, cv.versionData);
        }
    }  
    
    
    //--------------------------------------------------------------------------------------------
    public List<DownloadLinkInfo> addObjectAttachments(String objectId, Boolean checkSize) {

        final Integer MAX_TOTAL_SIZE_B64 = 25 * 1024 * 1024; // 25 MB
        final Integer MAX_FILE_SIZE_B64  = 25 * 1024 * 1024; // 25 MB per file

        if (!checkSize) {
            this.addObjectAttachments(objectId);
            return new List<DownloadLinkInfo>();
        }

        List<ContentVersion> lfiles = AttachmentUtils.getSObjectAttachments(objectId);
        Set<Id> ids = TypeConversionCommons.listToSet(lfiles);

        List<ContentVersion> cvsMeta = [
            SELECT Id, PathOnClient, ContentSize
            FROM ContentVersion
            WHERE Id IN :ids
        ];

        Integer totalSizeB64 = 0;
        List<DownloadLinkInfo> downloadLinks = new List<DownloadLinkInfo>();

        for (ContentVersion meta : cvsMeta) {
            // Estimate base64 size (ceil for safety)
            Integer fileSizeB64 = Integer.valueOf(Math.ceil(meta.ContentSize / 3.0) * 4);

            // If file is too big, don't download it—just generate link
            if (fileSizeB64 > MAX_FILE_SIZE_B64) {
                String link = generateContentDistributionLink(meta.Id, this.ValidityHours);
                downloadLinks.add(new DownloadLinkInfo(meta.PathOnCLient, link));
                continue;
            }
            // If the total would exceed, same logic
            if (totalSizeB64 + fileSizeB64 > MAX_TOTAL_SIZE_B64) {
                String link = generateContentDistributionLink(meta.Id, this.ValidityHours);                
                downloadLinks.add(new DownloadLinkInfo(meta.PathOnCLient, link));
                continue;
            }
            // If we reach here, download VersionData and attach
            ContentVersion cv = [
                SELECT PathOnClient, VersionData
                FROM ContentVersion
                WHERE Id = :meta.Id
            ];
            this.addAttachment(cv.PathOnClient, cv.VersionData);
            totalSizeB64 += fileSizeB64;
        }
        return downloadLinks;
    }
    /**
     * Generates a public ContentDistribution link for the given ContentVersion Id.
     * If a public link already exists, it will be reused.
     */
    @testVisible
    private String generateContentDistributionLink(Id contentVersionId, Integer validityHours) {
        
        // Calculate expiry date
        DateTime expiryDate = (validityHours != null && validityHours > 0)
            ? System.now().addHours(validityHours)
            : null; // Null means no expiration
        
        Boolean expires = (validityHours != null && validityHours > 0);

        // Check if a valid public link already exists
        List<ContentDistribution> existing = [
            SELECT DistributionPublicUrl, ExpiryDate
            FROM ContentDistribution
            WHERE ContentVersionId = :contentVersionId
            AND PreferencesAllowViewInBrowser = true
            AND PreferencesAllowOriginalDownload = true
            AND PreferencesLinkLatestVersion = true
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            // Optionally, check if the link's expiry is after now
            if (expiryDate == null || existing[0].ExpiryDate == null || existing[0].ExpiryDate >= System.now()) {
                return existing[0].DistributionPublicUrl;
            }
        }
        // Otherwise, create a new ContentDistribution record
        ContentDistribution cd = new ContentDistribution(
            Name = 'Shared File',
            ContentVersionId = contentVersionId,
            PreferencesAllowViewInBrowser = true,
            PreferencesLinkLatestVersion = true,
            PreferencesAllowOriginalDownload = true,
            ExpiryDate = expiryDate,
            PreferencesExpires = expires
        );
        insert cd;
        return cd.DistributionPublicUrl;
    }

    //--------------------------------------------------------------------------------------------

    public void addAttachment(String fileName, Blob content) {
        Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
        file.setFileName(fileName);
        file.setBody(content);
        if (content != null) {
            this.files.add(file);
        }
    }

    public void setRelatedObjectId(Id objectId) {
        this.mail.setWhatId(objectId);
    }

    // ********************************* GETTERS ***********************************************
    public List<String> getTo() {
        return this.mail.getToAddresses();
    }

    public List<String> getCc() {
        return this.mail.getCcAddresses();
    }

    public List<String> getBcc() {
        return this.mail.getBccAddresses();
    }

    public String getSubject() {
        return this.mail.getSubject();
    }
    
    public String getHtml() {
        return this.mail.getHtmlBody();
    }

    public List<Id> getAttachments() {
        return this.mail.getEntityAttachments();
    }

    public Messaging.Singleemailmessage getEmail() {
        return this.mail;
    }

    // ********************************* METHODS ***********************************************

    /**
    * @description Send an email passing all parameters. Don't use this to send multiple mails because the governor limit. Use MailUtils.sendBatch
    * @return Boolean message sent?
    */
    public Boolean send(Boolean generic, List<String> toList, List<String> ccList, List<String> bccList, String subject, String text) 
    {
        if (generic == true) {
            this.setGeneric();
        }
        this.setTo(toList);
        this.setCc(ccList);
        this.setBcc(bccList);
        this.setSubject(subject);
        this.setHtml(text);

        return this.send();
    }

    /**
    * @description Send an email passing all parameters. Don't use this to send multiple mails because the governor limit. Use MailUtils.sendBatch
    * @return Boolean message sent?
    */
    public Boolean send(Boolean generic,List<Id> toList, List<Id> ccList, List<Id> bccList, String subject, String text) 
    {
        if (generic == true) {
            this.setGeneric();
        }
        this.setTo(MailUtils.getMail(toList));
        this.setCc(MailUtils.getMail(ccList));
        this.setBcc(MailUtils.getMail(bccList));
        this.setSubject(subject);
        this.setHtml(text);

        return this.send();
    }

    public void sendDevelopers(String subject, String text) 
    {
        this.setTo(this.developerMail);
        this.setSubject(subject);
        this.setHtml(text);

        this.send();
    }

    /**
    * @description Send an email. Don't use this to send multiple mails because the governor limit. Use MailUtils.sendBatch
    * @return Boolean message sent?
    */
    public Boolean send() {
        try {
            if (files.size() > 0) {
                this.mail.setFileAttachments(files);
            }
            String plainText = '';
            try {
                plainText = HTMLCommons.htmlToPlainText(this.mail.getHtmlBody());
            } catch (Exception ex) {
                plainText = '';
            }
            this.mail.setPlainTextBody(plainText);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {this.mail});
        } catch(Exception e) {
            return false;          
        }
        return true;
    }

    public class DownloadLinkInfo {
        public String fileName;
        public String url;
        public DownloadLinkInfo(String fileName, String url) {
            this.fileName = fileName;
            this.url = url;
        }
    }
}