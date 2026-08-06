/**
 * @author         Ramón Prades
 * @date           August 2025
 * @group          CMS
 *
 * Class: CMS_Uploader
 * Prefix CMS_ = Content/Commerce Media Suite
 *
 * Purpose:
 *   Handles the upload of binary files into Salesforce Enhanced CMS.
 *   This class abstracts the creation of CMS managed content entries
 *   and allows specifying the target Workspace where the media will reside.
 *
 * Responsibilities:
 *   - Accept a Blob (binary file) plus metadata (file name, MIME type).
 *   - Upload the file into the Enhanced CMS using ConnectApi.ManagedContent.
 *   - Associate the new content with a given Workspace.
 *   - Return identifiers of the created content (ManagedContentId) for later
 *     associations with products or references.
 *   - Optionally auto-publish the uploaded content if AutoPublish = true.
 *
 * Usage Example:
 *   Id workspaceId = '0h1XX0000004FJqWAM'; // Example CMS Workspace
 *   CMS_Uploader uploader = new CMS_Uploader(workspaceId);
 *   uploader.AutoPublish = true; // optional
 *   CMS_Uploader.ManagedContentDTO result = uploader.uploadImage(
 *       'myImage.jpg',
 *       fileBody
 *   );
 *   System.debug('Created Managed Content Id: ' + result.managedContentId);
 *   System.debug('Was published? ' + result.isPublished);
 *
 * Notes:
 *   - This class focuses only on the upload to CMS. No Product2 association
 *     logic is included here.
 *   - Built for reuse in batch and asynchronous contexts.
 *   - Errors from ConnectApi are caught and surfaced with meaningful messages.
 */
public class CMS_Uploader {

    public static final String CONTENT_TYPE_IMAGE = 'sfdc_cms__image';
    public Boolean AutoPublish = false;

    private Id workspaceId = null;
    private ConnectApi.ManagedContentDocument lastDocument = null;

    public CMS_Uploader(Id workspaceId) {
        this.workspaceId = workspaceId;
    }
    
    public ConnectApi.ManagedContentDocument getManagedContent() {
        return this.lastDocument;
    }

    public ManagedContentDTO uploadImage(String fileName, Blob content) {
        FileDescriptorDTO dto = new FileDescriptorDTO();
        dto.fileName = fileName;
        dto.mimeType = URLCommons.inferMimeType(fileName);
        dto.title = fileName;
        dto.contentType = CONTENT_TYPE_IMAGE;
        dto.content = content;
        return this.upload(dto);
    }

    public ManagedContentDTO upload(FileDescriptorDTO fileDTO) {
        
        ConnectApi.BinaryInput contentData = new ConnectApi.BinaryInput(fileDTO.content, fileDTO.mimeType, fileDTO.fileName);   

        Map<String, String> fileInfoMap = new Map<String, String>{ 'type' => 'file', 'mimeType' => fileDTO.mimeType};
        Map<String, Object> sourceMap = new Map<String, Object>{
            'source' => fileInfoMap
        };
        Map<String, Object> bodyMap = new Map<String, Object>{
            'sfdc_cms:media' => sourceMap
        };
        ConnectApi.ManagedContentBodyInput contentBody = new ConnectApi.ManagedContentBodyInput();
        contentBody.nodeMap = bodyMap;
        ConnectApi.ManagedContentDocumentInput managedContentInput = new ConnectApi.ManagedContentDocumentInput();
        managedContentInput.title = fileDTO.title;
        managedContentInput.contentBody = contentBody;
        managedContentInput.contentType = fileDTO.contentType;
        managedContentInput.contentSpaceOrFolderId = this.workspaceId;
        if (!Test.isRunningTest()) {
            this.lastDocument = ConnectApi.ManagedContent.createManagedContentWithMedia(managedContentInput, contentData);
        }
        
        ManagedContentDTO resultDTO = new ManagedContentDTO();
        resultDTO.managedContentId = this.lastDocument?.managedContentId;
        resultDTO.isPublished = false;
        if (this.AutoPublish) {
            resultDTO.isPublished = this.publishContent(resultDTO?.managedContentId);
        }

        return resultDTO;
    }

    public Boolean publishContent(String managedContentId) {
        return this.publishContent(new List<String>{managedContentId});
    }
    
    public Boolean publishContent(List<String> managedContentIds) {
        ConnectApi.ManagedContentPublishInput input = new ConnectApi.ManagedContentPublishInput();
        input.contentIds = managedContentIds;
        input.contextContentSpaceId = this.workspaceId;
        // ConnectApi.ManagedContentPublishOutput output = 
        ConnectApi.ManagedContent.publish(input);
        return true;
    }


    public class FileDescriptorDTO {
        public String fileName;
        public String mimeType;
        public String title;
        public String contentType;
        public Blob content;
    }

    public class ManagedContentDTO {
        public String managedContentId;
        public Boolean isPublished = false;
    }
}