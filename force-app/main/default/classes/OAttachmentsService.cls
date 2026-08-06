/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Attachments
* @layer        Services
* @description 	Manages SObject Attachments
*/
public class OAttachmentsService {

    /**
     * Creates an attachment
     */
    public static void createAttachments(List<OAttachmentDTO> files) {
        ContentVersion[] versions = new List<ContentVersion>();
        ContentDocumentLink[] cdLinks = new List<ContentDocumentLink>();
        for (OAttachmentDTO file: files) {
            versions.add(attachmentToContentVersion(file));
        }
        insert versions;

        Integer index = 0;
        for (OAttachmentDTO file: files) {
            ContentVersion version = versions[index];
            Id conDoc = [SELECT contentDocumentId FROM ContentVersion WHERE Id =:version.Id].ContentDocumentId;    
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = file.parentId; // you can use objectId,GroupId etc
            cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
            cDe.Visibility = 'AllUsers';
            cdLinks.add(cDe);
            index ++;
        }
        insert cdLinks;    
    } // createAttachments

    /**
     * Gets a list with the attachments (ContentVersion) of an object
     */
    public static List<ContentVersion> getSObjectAttachments(String id) {
        List<ContentDocumentLink> links = [select contentDocumentId from ContentDocumentLink where LinkedEntityId  = :id];
        List<Id> ids = new List<Id>();
        for (ContentDocumentLink link :links) {
            ids.add(link.contentDocumentId);
        }
        return [
            SELECT 
                Id, contentDocumentId, CreatedDate, CreatedById, DocumentType__c,
                pathOnClient, Title, Description, FileExtension, OwnerId, Owner.Name
            FROM ContentVersion 
            WHERE
                contentDocumentId in :ids 
                and isLatest = true
                and isDeleted = false
            ORDER BY CreatedDate];
    } // getSObjectAttachments


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static ContentVersion attachmentToContentVersion(OAttachmentDTO att) {        
        Boolean encoded = att.encoded;
        if (att.encoded == null) {
            encoded = true;
        }
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.PathOnClient = att.fileName;
        if (String.isNotEmpty(att.title)) {
            conVer.Title = att.title;
        } else {
            conVer.Title = att.fileName;
        }
        if (encoded) {
            try {                        
                conVer.VersionData = EncodingUtil.base64Decode(att.content); 
            } catch (Exception ex) {
                encoded = false;
            }
        }

        if (!encoded) {
            conVer.VersionData = Blob.valueOf(att.content); 
        }

        return conVer;

    } // createAttachments
} // class