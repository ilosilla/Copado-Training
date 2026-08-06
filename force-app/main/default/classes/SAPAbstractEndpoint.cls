/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    SAP endpoint base class
 * -------------------------------------------------------------------------------
 *  This class is based on the asynchronous architecture initially defined for 
 *  integration with the LWR version of B2B, but which will be used for any
 *  integration that is developed with SAP from now on.
 * -------------------------------------------------------------------------------
 * Reach coverage with SAPSalesOrderEndpointTest and FactoryQualityEndpointTest
*/
@SuppressWarnings('PMD.EmptyStatementBlock')
public abstract class  SAPAbstractEndpoint {

    protected Set<Id> ids;
    protected SObject[] requestingObjects;

    /**
     * Default constructor
     */
    public SAPAbstractEndpoint(Set<Id> ids) {
        this.ids = ids;        
    }

    /**
     * Returns the name of the response handler to use to process the request
     */
    public abstract String getAPIHandlerName();

    /**
     * Returns the action to request
     */
    protected abstract String getActionRequested();

    /**
     * Returns the service requested
     */
    protected virtual String getEndpointName() {
        String valueOfThis = String.valueOf(this);        
        return valueOfThis.substring(0, valueOfThis.indexOf(':'));
    }

    /**
     * Allows disabling the endpoint
     */
    public virtual Boolean isEnabled() {
        return true;
    }

    /**
     * If the sap endpoint accepts lists of items
     */
    protected virtual Boolean isMultiple() {
        return false;           // defaults to false
    }

    /**
     * Allows duplicates in the queue
     */
    protected virtual Boolean allowDuplicates() {
        return false;           // defaults to false
    }

    /**
     * Gets the request name
     */
    protected virtual String getRequestName() {
        return this.getEndpointName() + ' (' + this.getActionRequested() + ')';
    }

    /**
     * Sets the requesting object as "queued" (optional)
     */
    protected virtual void setRequestingObjectAsQueued(Id objectId) {
        // Set the object here and add it to this.requestingObjects;
    }

    /**
     * Allows the subclass to provide extra parameters per object Id.
     * Used to fill the Parameter__c field in SAPRequestQueue__c.
     */
    protected virtual Map<Id, String> getRequestParameters() {
        return new Map<Id, String>();
    }

    /**
     * Hook for subclasses to add extra requests. Subclasses may append to `requests`.
     *
     * @param objectId  Current object being processed
     * @param requests  List of requests to insert (modifiable)
     */
    protected virtual void extendRequests(List<SAPRequestQueue__c> requests) {
        // Default: do nothing
    }

    /**
     * Launches the request
     */
    public virtual Integer doRequests() {
        if (!this.isEnabled()) {
            return 0;
        }
        this.requestingObjects = new List<SObject>();
        SAPRequestQueue__c[] requests = new List<SAPRequestQueue__c>();
        Map<Id, String> paramsMap = this.getRequestParameters();
        //Map<Id, Object> requesting = this.getRequestingObjects();
        //for (Id objectId : requesting.keySet()) {
        for (Id objectId : this.ids) {
            SAPRequestQueue__c request = new SAPRequestQueue__c();
            request.ActionRequested__c = this.getActionRequested().toUpperCase();
            request.SAPEndpoint__c = this.getEndpointName();
            request.SAPAPIHandler__c = this.getAPIHandlerName();
            request.Retries__c = 0;
            request.RequesterID__c = objectId;
            request.Name = this.getRequestName();
            request.IsMultiple__c = this.isMultiple();
            request.AllowDuplicates__c = this.allowDuplicates();
            request.Parameter__c = StringCommons.truncate(paramsMap.get(objectId), 100);
            requests.add(request);
            this.setRequestingObjectAsQueued(objectId);

        }  

        // Permitir extensiones por objeto
        this.extendRequests(requests);

        if (this.requestingObjects.size() > 0) {
            update this.requestingObjects;
        }
        insert requests;

        return requests.size();
    }
}