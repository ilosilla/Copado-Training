/**
* @author 		Ramón Prades
* @date 		May 2021
* @group 		Opportunities
* @description 	Opportunity Custom Project controller
*/
public class OpportunityCustomProjectController {
    /**
     * Sets the custom project default values 
     */
    @AUraEnabled public static ProjectDTO readCustomProjectData(String opportunityId, String customProjectId) {
        ProjectDTO dto = new ProjectDTO();
        dto.isNew = (customProjectId == null);
        dto.hasQuote = false;
        dto.hasDrawing = false;
        dto.opportunity = [select Id, Name, OwnerId, Owner.Name, StageName, CurrencyIsoCode from Opportunity where Id = :opportunityId limit 1];
        dto.productManagers = UserUtils.getProductManagers('US');
        dto.requestLines = readRequestLines(customProjectId);
        dto.attachments = readAttachments(customProjectId);
        dto.location = InternationalAddress.fromOpportunity(opportunityId).format();
        dto.userName = UserInfo.getName();
        dto.currencyCode = dto.opportunity.CurrencyIsoCode;
        setAttachmentFlags(dto);
        setUserProperties(dto);
        return dto;
    } // readCustomProjectData

    /**
     * Validates & saves the custom project
     * OBSOLETE: No se usa de momento para validar nada en servidor
     */
    @AuraEnabled public static ResultDTO saveCustomProject(OppCustomProject__c customProject) {
        ResultDTO dto = new ResultDTO();
        dto.success = false;
        if (validateCustomProject(customProject)) {
            if (customProject.Id == null) {
                insert customProject;
                dto.success = true;
                dto.command = 'INSERT';
                dto.arg = customProject.Id;
            } else {
                update customProject;
                dto.success = true;
                dto.command = 'MODIFY';
                dto.arg = customProject.Id;
            }
            return dto;
        }
        return dto;
    } // saveCustomProject

    /**
     * Saves the request lines
     */
    @AuraEnabled public static  OppCustomProjectRequest__c[] saveRequestLines(String projectId, OppCustomProjectRequest__c[] requestLines,  OppCustomProjectRequest__c[] deleteLines) {
        for (OppCustomProjectRequest__c req :requestLines) {
            if (req.OppCustomProject__c == null) {
                req.OppCustomProject__c = projectId;
            }
        }
        upsert requestLines;
        delete deleteLines;

        return requestLines;
    } // saveRequestLines

    /**
     * Actions after uploading a file
     */
    @AuraEnabled public static void afterUploadFile(String projectId, List<String> contentIds, String contentType) {
        if (String.isNotEmpty(contentType)) {
            ContentVersion[] versions = [select Id, contentDocumentId, CreatedDate, CreatedById, DocumentType__c from ContentVersion where Id in :contentIds];
            for (ContentVersion version :versions) {
                version.DocumentType__c = contentType;
            }            
            update versions;
            if (contentType == 'DRAWING'||contentType == 'QUOTE') {                
                OppCustomProject__c cp = [select Id, ShopDrawings__c from OppCustomProject__c where id = :projectId limit 1];
                if (!cp.ShopDrawings__c) {
                    cp.ShopDrawings__c = true;
                    update cp;
                }
                if (SystemSettings.CPNotificationsEnabled) {
                    CustomProjectMailer mailer = new CustomProjectMailer(projectId, contentType);
                    mailer.setMailAttachments(contentIds);
                    ID jobId = System.enqueueJob(mailer);
                }
            }
        }
    } // contentIds

    /**
     * Deletes a list of attachments
     */
    @AuraEnabled public static void deleteAttachments(String projectId, List<String> documentIds) {
        ContentDocument[] documents = [select Id from ContentDocument where Id in :documentIds];
        if (documents.size() > 0) {
            delete documents;
            setDrawingFlag(projectId);
        }
    } // deleteAttachments

    /*********************************************************/    
    /********************* INNER CLASSES *********************/
    /*********************************************************/
    /**
     * Inner class to return a set of data to the component
     */
    public class ProjectDTO {
        @AUraEnabled public Boolean isNew;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Opportunity opportunity;
        @AuraEnabled public User[] productManagers;
        @AuraEnabled public Boolean hasQuote;
        @AuraEnabled public Boolean hasDrawing;
        @AuraEnabled public List<OppCustomProjectRequest__c> requestLines;
        @AuraEnabled public String location;
        @AuraEnabled public String userName;
        @AuraEnabled public List<AttachmentDTO> attachments;
        @AuraEnabled public Boolean isProductManager = false;
        @AuraEnabled public Boolean isProjectsStaff = false;
        @AuraEnabled public Boolean isAdmin = false;
    } // inner class

    public class AttachmentDTO {
        @AuraEnabled public String id;        
        @AuraEnabled public String fileName;        
        @AuraEnabled public DateTime createdDate;        
        @AuraEnabled public String createdBy;        
        @AuraEnabled public String documentType; 
        @AuraEnabled public String contentDescription; 
        @AuraEnabled public String contentVersionId;
    }

    /**
     * Inner class to return the result of the save operation
     */
    public class ResultDTO {
        @AuraEnabled public Boolean success = false;     
        @AuraEnabled public String command;     
        @AuraEnabled public String arg;     
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static Boolean validateCustomProject(OppCustomProject__c projectId) {
        return true;
    } // validateCustomProject

    private static List<OppCustomProjectRequest__c> readRequestLines(Id projectId) {
        List<OppCustomProjectRequest__c> lines = new List<OppCustomProjectRequest__c>();
        if (projectId != null) {
            lines = [
                select 
                    Id, isDeleted, BacksplashDetail__c, BacksplashHeight__c, ColorName__c,
                    OppCustomProject__c, Edge__c, EdgeThickness__c,Finish__c,
                    ProductDescription__c, Name, Underlayment__c                
                from OppCustomProjectRequest__c
                where OppCustomProject__c = :projectId
                and isDeleted = false
                order by Name
            ];            
        }
        return lines;
    } // readRequestLines

    private static void setDrawingFlag(Id projectId) {
        List<ContentDocumentLink> links = [select contentDocumentId from ContentDocumentLink where LinkedEntityId  = :projectId];
        List<Id> ids = new List<Id>();
        for (ContentDocumentLink link :links) {
            ids.add(link.contentDocumentId);
        }
        // prepares a map of versions (a document can have several versions)
        Map<String, ContentVersion> versions = new Map<String, ContentVersion>();
        for (ContentVersion cv : [select Id, contentDocumentId, CreatedDate, CreatedById, DocumentType__c from ContentVersion where contentDocumentId in :ids order by createdDate desc]) {
            if (!versions.containsKey(cv.contentDocumentId)) {
                versions.put(cv.contentDocumentId, cv);
            }
        }
    } // setDrawingFlag

    private static List<AttachmentDTO> readAttachments(Id projectId) {        
        if (projectId == null ) {
            return new List<AttachmentDTO>();
        }

        List<ContentDocumentLink> links = [select contentDocumentId from ContentDocumentLink where LinkedEntityId  = :projectId];
        List<Id> ids = new List<Id>();
        for (ContentDocumentLink link :links) {
            ids.add(link.contentDocumentId);
        }
        // prepares a map of versions (a document can have several versions)
        Map<String, ContentVersion> versions = new Map<String, ContentVersion>();
        for (ContentVersion cv : [select Id, contentDocumentId, CreatedDate, CreatedById, DocumentType__c from ContentVersion where contentDocumentId in :ids order by createdDate desc]) {
            if (!versions.containsKey(cv.contentDocumentId)) {
                versions.put(cv.contentDocumentId, cv);
            }
        }
        List<ContentDocument> docs = [select Id, Title, Description, CreatedDate, FileExtension, OwnerId, Owner.Name from ContentDocument where id in :ids order by createdDate];
        AttachmentDTO[] atts = new List<AttachmentDTO>();
        for (ContentDocument doc :docs) {
            AttachmentDTO att = new AttachmentDTO();            
            att.id = doc.Id;            
            att.fileName = doc.Title + '.' + doc.FileExtension;
            att.createdDate = doc.createdDate;
            att.createdBy = doc.Owner.Name;
            att.documentType = '';
            ContentVersion version = versions.get(doc.Id);
            if (version != null) {
                att.documentType = version.documentType__c;
                att.contentVersionId = version.Id;
            }            
            atts.add(att);
        }
        return atts;
    } // readAttachments

    private static void setAttachmentFlags(ProjectDTO dto) {
        dto.hasQuote = false;
        dto.hasDrawing = false;
        for (AttachmentDTO att :dto.attachments) {
            switch on att.documentType {
                when 'QUOTE'    { dto.hasQuote = true;   }
                when 'DRAWING'  { dto.hasDrawing = true; }
            }
        }
    } // setFlagAttachments

    private static void setUserProperties(ProjectDTO dto) {
        dto.isAdmin = UserUtils.isAdministrator();
        dto.isProductManager = false;
        for (User manager : dto.productManagers) {
            if (manager.Id == UserInfo.getUserId()) {
                dto.isProductManager = true;
            }
        }
        dto.isProjectsStaff = false;
        for (User staff : UserUtils.getProjectsStaff('US')) {
            if (staff.Id == UserInfo.getUserId()) {
                dto.isProjectsStaff = true;
            }
        }
    } // setUserProperties    

} // class