/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    Class to send a sales order (Order object) to SAP. Uses the V2 of the orders API.
*/
public class SAPSalesOrderEndpoint extends SAPAbstractEndpoint {
    /*public SAPSalesOrderEndpoint() {
    }*/

    public SAPSalesOrderEndpoint(Set<Id> ids) {
        super(ids);
    }

    /**
     * Orders Response Handler
     */
    public override String getAPIHandlerName() {
        return 'SAPSalesOrderAPIHandler';
    }

    protected override String getActionRequested() {
        return 'CREATE';
    }

    protected override void setRequestingObjectAsQueued(Id objectId) {
        Order o = new Order();
        o.Id = objectId;
        o.SAPRequestStatus__c = 'queued';
        this.requestingObjects.add(o);
    }

} // SAPSalesOrderEndpoint