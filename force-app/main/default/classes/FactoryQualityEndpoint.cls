/**
 * @author         Ramón Prades
 * @date           June 2025
 * @group          CPI
 * @description    Asynchronous integration endpoint for factory quality systems.
 * -------------------------------------------------------------------------------
 *  This class extends the base architecture built on SAPAbstractEndpoint to
 *  enqueue integration requests related to quality incidents, enabling 
 *  communication with factory-level quality systems via CPI.
 * 
 *  Specifically, it handles the registration of claims reported by our subsidiaries,
 *  preparing and inserting the required data into the SAPRequestQueue__c queue.
 *  The dispatcher will later process these entries and route them through CPI.
 * 
 *  The getRequestType() method returns 'CPI', marking these requests as part of
 *  non-SAP integrations, while still leveraging the existing infrastructure.
 * -------------------------------------------------------------------------------
 */
public class FactoryQualityEndpoint extends SAPAbstractEndpoint {

    public FactoryQualityEndpoint(Set<Id> ids) {
        super(ids);
    }

    public override String getAPIHandlerName() {
        return 'FactoryQualityAPIHandler';
    }

    public override Boolean isEnabled() {
        return PORSAIntegrationSettings.SendClaims;
    }

    protected override String getActionRequested() {
        return 'CREATE';
    }

    /**
     * Allows duplicates in the queue
     */
    protected override Boolean allowDuplicates() {
        return true; 
    }

    /**
     * Adds the requests to send the case attachments
     */
    protected override void extendRequests(List<SAPRequestQueue__c> requests) {
        SAPRequestQueue__C[] newRequests = new List<SAPRequestQueue__c>();
        for (SAPRequestQueue__c request : requests) {
            Id caseId = request.RequesterID__c;
            List<ContentVersion> lfiles = AttachmentUtils.getSObjectAttachments(caseId);
            Integer index = 0;
            for (ContentVersion cv : lfiles) {
                index++;
                SAPRequestQueue__c newRequest = new SAPRequestQueue__c();
                newRequest.ActionRequested__c = 'CREATE';
                newRequest.SAPEndpoint__c = this.getEndpointName();
                newRequest.SAPAPIHandler__c = 'FactoryQualityFileAPIHandler';
                newRequest.Retries__c = 0;
                newRequest.RequesterID__c = request.RequesterID__c;
                newRequest.Name = this.getEndpointName() + ' (CREATE)';
                newRequest.AllowDuplicates__c = true;
                newRequest.Parameter__c = cv.Id + '-' + index + '-' + lfiles.size();
                newRequests.add(newRequest);                
            }
        }
        requests.addAll(newRequests);
    }
  

} // FactoryQualityEndpoint