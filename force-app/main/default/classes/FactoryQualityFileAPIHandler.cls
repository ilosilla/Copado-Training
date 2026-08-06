/**
 * @author      Ramón Prades
 * @date        July 2025
 * @description 
 * 
 * FactoryQualityFileAPIHandler
 * =============================
 * 
 * This class implements the logic required to prepare and send file attachments 
 * related to Claims (Salesforce Cases) to the factory quality systems.
 * 
 * It extends SAPAbstractAPIHandler and is designed to:
 * - Generate the proper JSON payload for each file attachment.
 * - Send the request to the configured endpoint via CPI .
 * 
 * The class is invoked automatically from SAPRequestDispatcher, typically 
 * through an entry in the SAPRequestQueue__c object.
 * 
 * ⚠️ Expected Input:
 * The `RequesterId__c` must point to a Case (Claim), and the file ID must be 
 * passed in the `Parameter__c` field in the format: `<FileId>::<Index>`.
 */
public class FactoryQualityFileAPIHandler extends SAPAbstractAPIHandler {

    static final Integer TIMEOUT = 120000; // 2 minutes, can be adjusted as needed
    
    public override String getServiceName() {
        return SAPCPIProxy.FACTORY_QUALITY;
    }

    public override String getRequestType() {
        return SAPRequestDispatcher.REQUEST_TYPE_CPI;
    }

    public override Integer getTimeout() {
        return TIMEOUT;
    }    

    public override String buildSimplePayload() {
        Id caseId = this.sapRequest.RequesterID__c;
        String[] parts = this.sapRequest.Parameter__c?.split('-');
        if (parts.size() != 3) {
            throw new IllegalArgumentException('Invalid format: expected <file_id>-<index>-<number-of-files>');
        }
        AttachmentDTO dto = new AttachmentDTO();
        dto.caseId = caseId;
        dto.fileId = parts[0];
        dto.index = Integer.valueOf(parts[1]);
        dto.numberOfFiles = Integer.valueOf(parts[2]);

        ContentVersion cv = [
            SELECT Id, PathOnClient, FileType, ContentSize
            FROM ContentVersion 
            WHERE Id = :dto.fileId 
            LIMIT 1
        ];
 
        // margen prudente dentro de 12 MB async
        Integer maxBytes = 8000000;
        if (cv.ContentSize > maxBytes) {
            // evita leer VersionData si sabes que no te cabe
            throw new SAPRequestDispatcher.SkipFlagException('File too large for binary upload in this context (' + cv.ContentSize + ' bytes).');
        }

        // ahora lo lee
        ContentVersion cvData = [
            SELECT Id, PathOnClient, FileType, VersionData , ContentSize
            FROM ContentVersion 
            WHERE Id = :dto.fileId 
            LIMIT 1
        ];

        dto.fileType = cvData.FileType;
        dto.fileName = cvData.PathOnClient;
        dto.content = EncodingUtil.base64Encode(cvData.VersionData);

        String json = '{ "attachment": ' + JSON.serialize(dto) + '}';
        return json;
    }

    public override String processResponse(Id requesterId, Integer httpStatusCode, String response) {
        ResponseDTO dto = parseResponseDTO(response);
        if (dto != null && dto.status?.toLowerCase() == 'success' && dto.data != null) {
            return dto.data.toString();
        }
        return '';
    }
    
    public override String parseErrors(Id requestedId, String response) {
        ResponseDTO dto = parseResponseDTO(response);
        if (dto != null) {
            return dto?.message;
        }
        return 'Invalid JSON in response';
    }

    private static ResponseDTO parseResponseDTO(String response) {
        if (String.isBlank(response)) {
            return null;
        }
        try {
            return (ResponseDTO) JSON.deserialize(response, ResponseDTO.class);
        } catch (Exception ex) {
            return null;
        }
    }

    public class ResponseDTO {
        public String status;
        //public String date;
        public Integer data;
        public String message;
        public Boolean automaticChanges;
    }

    public class AttachmentDTO {
        public String caseId;
        public String fileId;
        public Integer index;
        public Integer numberOfFiles;
        public String fileName;
        public String fileType;
        public String content;
    }
}