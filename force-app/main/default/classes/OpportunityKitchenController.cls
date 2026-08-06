/**
* @author 		Ramón Prades
* @date 		July 2021
* @group 		Opportunities
* @description 	OpportunityKitchen component controller
*/
public class OpportunityKitchenController {
    /**
     * Reads opp and kitchen data
     */
    @AUraEnabled public static DataDTO readKitchenData(String opportunityId, String kitchenId) {
        DataDTO dto = new DataDTO();
        dto.isNew = (kitchenId == null);
        dto.hasDrawing = false;
        dto.opportunity = [select Id, Name, OwnerId, Owner.Name, StageName, CloseDate, CurrencyIsoCode from Opportunity where Id = :opportunityId limit 1];
        dto.managers = UserUtils.getKitchenManagers('US');
        dto.designers = UserUtils.getKitchenDesigners('US');
        dto.attachments = readAttachments(kitchenId);
        dto.location = InternationalAddress.fromOpportunity(opportunityId).format();
        dto.userName = UserInfo.getName();
        dto.currencyCode = dto.opportunity.CurrencyIsoCode;

        //setAttachmentFlags(dto);
        //setUserProperties(dto);
        return dto;
    } // readKitch4enData

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
        }
    } // contentIds

    /**
     * Deletes a list of attachments
     */
    @AuraEnabled public static void deleteAttachments(String projectId, List<String> documentIds) {
        ContentDocument[] documents = [select Id from ContentDocument where Id in :documentIds];
        if (documents.size() > 0) {
            delete documents;
        }
    } // deleteAttachments


    /*********************************************************/    
    /********************* INNER CLASSES *********************/
    /*********************************************************/
    /**
     * Inner class to return a set of data to the component
     */
    public class DataDTO {
        @AUraEnabled public Boolean isNew;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public Opportunity opportunity;
        @AuraEnabled public User[] managers;
        @AuraEnabled public KitchenTeam__c[] designers;
        @AuraEnabled public Boolean hasDrawing;
        @AuraEnabled public String location;
        @AuraEnabled public String userName;
        @AuraEnabled public List<AttachmentDTO> attachments;
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

    /*********************************************************/    
    /******************* PRIVATE METHODS *********************/
    /*********************************************************/

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

} // class