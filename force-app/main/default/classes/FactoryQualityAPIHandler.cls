/**
 * @author         Ramón Prades
 * @date           June 2025
 * @group          CPI
 * @description    Response handler for factory quality claim integration.
 * -------------------------------------------------------------------------------
 *  This class extends SAPAbstractAPIHandler and is responsible for processing
 *  the response received from the factory quality system via CPI.
 * 
 *  It is invoked by the dispatcher once the integration request has been 
 *  completed, using the handler class name stored in SAPRequestQueue__c.
 * 
 *  Depending on the response content, it may update the originating record, 
 *  log errors, or trigger follow-up actions.
 * -------------------------------------------------------------------------------
 */
public class FactoryQualityAPIHandler extends SAPAbstractAPIHandler {

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
        Case c = this.readCase(this.sapRequest.RequesterID__c);
        c.Liability__c = null;      // Remove this field from the JSON
        return JSON.serialize(c, true);
    }

    public override String processResponse(Id requesterId, Integer httpStatusCode, String response) {
        String result = '';
        return result;
    }
    
    public override String parseErrors(Id requestedId, String response) {
        String message = '';
        ResponseDTO dto = (ResponseDTO) JSON.deserialize(response, ResponseDTO.class);
        return dto?.message;
    }


    public class ResponseDTO {
        public String status;
        //public String date;
        public Integer data;
        public String message;
        public Boolean automaticChanges;
    }

    private Case readCase(Id caseId) {
        String fields = DatabaseCommons.getFieldList('Case');
        fields += ', Account.SAP_Id__c, Account.Name, OrderId__r.Sap_Id__c';
        String query = 'SELECT ' + fields + ' FROM Case WHERE Id = :caseId';
        List<Case> cases = Database.query(query);
        return cases[0];
    }

}