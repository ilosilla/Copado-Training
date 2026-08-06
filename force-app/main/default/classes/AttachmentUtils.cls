/**
* @author 		Ramón Prades
* @date 		July 2021
* @group 		Utils
* @description 	Utility methods to handle attachemnts (ContentDocument*)
*/
public class AttachmentUtils {

    /**
     * Gets a list with the attachments (ContentVersion) of an object
     */
    public static List<ContentVersion> getSObjectAttachments(Id id) {
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

    /**
     * Gets a map with the attachments (ContentVersion) of an object
     */
    public static Map<String, ContentVersion> getSObjectAttachmentsMap(Id id) {
        Map<String, ContentVersion> versions = new Map<String, ContentVersion>();
        ContentVersion[] cvs = AttachmentUtils.getSObjectAttachments(id);
        for (ContentVersion cv :cvs) {
            versions.put(cv.contentDocumentId, cv);
        }
        return versions;
    } // getSObjectAttachmentsMap

    /**
     * Gets a BLOB with the attachment content
     */
    public static Blob getAttachmentContent() {
        return null;
    }
} // class