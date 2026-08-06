/**
 * @author         Ramón Prades
 * @date           July 2024
 * @group          SAP
 * @description    Serializes salesforce objects for a specific SAP API.
 * -------------------------------------------------------------------------------
 *  This class is based on the asynchronous architecture initially defined for 
 *  integration with the LWR version of B2B, but which will be used for any
 *  integration that is developed with SAP from now on.
 * -------------------------------------------------------------------------------
 * Test it with SAPSalesOrderSerializerTest to reach the required coverage.
*/
public abstract class SAPAbstractAPISerializer {

    List<Object> serializedObjects;
    

    public virtual String serialize(Set<Id> objectIds) {
        this.serializedObjects = this.readObjects(objectIds);
        
        List<String> payloads = new List<String>();
        for (Object obj : this.serializedObjects) {
            String payload = this.serializeObject(obj);
            payloads.add(payload);
        }
        return getPayload(payloads);
    }

    public List<Object> getSerializedObjects() {
        return this.serializedObjects;
    }

    protected virtual String getPayload( List<String> payloads) {
        return '[' + String.join(payloads, ',') + ']';
    }

    protected abstract List<Object> readObjects(Set<Id> objectIds);
    protected abstract String serializeObject(Object obj);
}