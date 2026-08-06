/**
 * @author         Ramón Prades
 * @date           January 2026
 * @group          SAP
 * @description    DTO representing a SAP Sales Order header.
 *                 Encapsulates the JSON serialization logic required
 *                 to adapt reserved words to SAP API expectations.
 * 
 * Use SAPSalesOrderMapperTest to reach coverage
 * 
 */
public class SAPOrderHeaderDTO {

    // ------------------------------- Metadata
    public String Version;
    public String OperationType;
    public String OperationName;
    public Integer Index;

    // ------------------------------- Identification & references
    public String SourceOrderId;
    public String OrderRef;
    public String Reference;
    public String Invoice;
    public String OrderReason;

    // ------------------------------- Parties
    public String RequestedBy;
    public String RequestedByAlias;
    public String Email;
    public String BillTo;
    public String BillToAlias;
    public String DeliverTo;
    public String DeliverToAlias;

    // ------------------------------- Dates (reserved words)
    public Date m_Date;          // Serialized as "Date"
    public Date DeliveryDate;

    // ------------------------------- Sales data
    public String SalesOrg;
    public String Channel;

    // ------------------------------- Delivery & logistics
    public Boolean StorePickup = false;
    public String ShippingCondition;
    public String Freight;
    public String DeliveryInstructions;
    public Boolean ApplyRestockingCharges;
    public String RestockingCharges;

    // ------------------------------- Amounts & currency (reserved word)
    public Decimal NetValue;
    public Decimal Total;
    public String m_Currency;    // Serialized as "Currency"

    // ------------------------------- Items
    public SAPOrderItemDTO[] Items;

     /**
     * Serializes this SAP order header using the SAP API contract.
     * The payload is wrapped under the "order" root node as required by SAP.
     */
    public String serialize() {

        Map<String, Object> wrapper = new Map<String, Object>();
        wrapper.put('order', this);

        String json = JSON.serialize(wrapper, true);

        // Reserved words workaround
        json = json.replace('"m_Date"', '"Date"');
        json = json.replace('"m_Currency"', '"Currency"');

        return json;
    }
}