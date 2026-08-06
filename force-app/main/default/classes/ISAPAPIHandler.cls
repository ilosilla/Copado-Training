/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    Interface for the SAP Response Handlers
*/
public interface ISAPAPIHandler {

    /**
     * Sets the request item that triggered the call
     */
    void setSAPRequestItem(SAPRequestQueue__c item);

    /**
     * Gets the name of the service to use (one of the SAPProxy services)
     */
    String getServiceName();

    /**
     * Gets the method to use when connecting to SAP
     */
    String getHttpMethod(String actionName);

    /**
     * Parses ten received JSON when an error is returned
     */
    String parseErrors(Id requesterId, String response);

    /**
     * Does the required changes to the input JSON to be sent to the SAP service in the body
     */
    String getPayload();

    /**
     * Porcesses the response received from SAP. Returns the SAP key that
     * will be stored in the SAP Request Item (for example, for orders, 
     * the order number; for customers, the sap customer number, etc).
     */
    String processResponse(Id requesterId, Integer httpStatusCode, String response);
}