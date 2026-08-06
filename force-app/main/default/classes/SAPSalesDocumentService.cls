/**
 * @author         Ramón Prades
 * @date           October 2023
 * @group          SAP
 * @description    Services related to SAP Documents
*/
public class SAPSalesDocumentService {

    /**
     * Downloads a sales doc of the following types:
     * - O Order
     * - D Delivery note
     * - I Invoice
     */
    public static Blob downloadSAPDocument(String docType, String docNumber, String form){
        String objectId = docType.toLowerCase() + '/' + docNumber.leftPad(10, '0');
        if (String.isNotBlank(form)) {
            objectId += '?form=' + form;
        }
        SAPWS_Utility.SapResponse response = SAPConnector.connect(objectId, SAPConnector.SALES_DOCUMENTS_SERVICE, 'GET', '');
        if (response.json != null) {
            return EncodingUtil.base64Decode(response.json);    
        } else {
            return null;
        }
    }

    public static Blob downloadSAPDocument(String docType, String docNumber){
        return SAPSalesDocumentService.downloadSAPDocument(doctype, docNumber, '');
    }
}