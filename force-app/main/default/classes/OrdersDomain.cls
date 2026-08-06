/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Orders domain layer class
 * ---
 * Version 1.1.0 - Free collections supported
*/
public class OrdersDomain extends zflib_TriggerDomainClass {  

    public static final String DELIVERY_PENDING = '10';
    public static final String DELIVERY_DELIVERING = '11';
    public static final String DELIVERY_DELIVERED = '12';

    public static final String REPLACEMENT_TYPE = 'Z051';
    public static final String CREDIT_REQUEST_TYPE = 'Z016';
    public static final String COLLECTION_TYPE = 'Z018';
    public static final String FREE_COLLECTION_TYPE = 'Z018_F';
    public static final String MATERIALS_ORDER = 'ZW04';

    public static final String STATUS_ACTIVATED = 'Activated';
    public static final String STATUS_DRAFT = 'Draft';

    public static final String SAP_REQUEST_READY = 'ready';
    public static final String SAP_REQUEST_QUEUED = 'queued';
    public static final String SAP_REQUEST_ACCEPTED = 'accepted';

    public static final String DELETE_SENT_TO_SAP = 'ORDER_DELETE_SENT_TO_SAP';

    public static final String VERSION2 = 'V2';
    public static final String VERSION3 = 'V3';

    public OrdersDomain() {
        super();
        this.setAssignDefaultsOnUpdate(true);
    }

    public OrdersDomain(List<Order> orders) {
        super(orders);
        this.setAssignDefaultsOnUpdate(true);
    }

    public override zflib_TriggerDomainClass cast() {
        return (OrdersDomain) this;
    } 

    public override Type getSObjectType() {
        return OrdersDomain.class;
    }

    public override void onApplyDefaults() {              
        for (Order o :(List<Order>) this.Records) {
            if (o.EffectiveDate == null) {
                o.EffectiveDate = Date.today();
            }
            if (o.status == null) {
                o.Status = STATUS_DRAFT;
            }    
            if (o.Status == STATUS_ACTIVATED && String.isBlank(o.SAPRequestStatus__c)) {
                o.SAPRequestStatus__c = SAP_REQUEST_READY;
            }
            this.setDeliveryStatus(o);
        }
    }

    public override void onAfterInsert() { 
        this.enqueue();
    }

    public override void onAfterUpdate(Map<Id,SObject> existingRecords) { 
        this.enqueue();
    }

    public override void onValidate() {
        Map<String, Sales_Org__c> salesOrgsMap = this.readSalesOrgs();
        for (Order order : (List<Order>) this.Records) {
            Order before = (this.isUpdate ? (Order) existingRecords.get(order.Id) : null);
            Boolean activated = (order.Status == STATUS_ACTIVATED && (this.isInsert || before.Status == STATUS_DRAFT));
            Boolean reversed = (this.isUpdate && order.Status == STATUS_DRAFT && before.Status == STATUS_ACTIVATED);
            if (reversed) {
                if (String.isNotBlank(order.SAPRequestStatus__c)) {
                    order.Status.addError(System.Label.tr0005_300); // The order cannot be reverted to DRAFT status after activation. All changes must now be managed directly in SAP
                }
            }
            if (activated) {
                SAPOrdersHelper.validateOrderForSAP(order, salesOrgsMap.get(order.SalesOrg__c));
            }
       }
    } // onValidate

    public override void onBeforeDelete() {
        Boolean canDelete = UserCommons.hasCustomPermission(DELETE_SENT_TO_SAP);
        if (!canDelete) {
            for (Order order : (List<Order>) this.Records) {
                if (order.Status == STATUS_ACTIVATED) {
                    order.status.addError(System.Label.tr0005_309);
                }
            }
        }
    }

    /***************************************************/
    /***************** PRIVATE METHODS *****************/    
    /***************************************************/
    /**
     * Sets he delivery status of the order
     */
    private void setDeliveryStatus(Order o) {
        o.NB2B_DeliveryStatus__c = DELIVERY_PENDING;
        if (o.SAPDeliveryNumber__c != null) {
            if (o.SAPGoodsPosted__c) {
                o.NB2B_DeliveryStatus__c = DELIVERY_DELIVERED;
            } else {
                o.NB2B_DeliveryStatus__c = DELIVERY_DELIVERING;
            }
        }
    }

    /**
     * Enqueues order to be sent to SAP
     */
    private void enqueue() {
        Set<Id> orderIds = new Set<Id>();
        for (Order order : (List<Order>) this.Records) {
            if ((order.Version__c == VERSION2 || order.Version__c == VERSION3) && order.Status == STATUS_ACTIVATED && order.SAPRequestStatus__c == SAP_REQUEST_READY && !orderIds.contains(order.Id)) {
                orderIds.add(order.Id);
            }
        }
        SAPSalesOrderEndpoint endpoint = new SAPSalesOrderEndpoint(orderIds);
        endpoint.doRequests();
    }
    
   /**
     * Reads the Sales orgs from the Sales_Org__c custom settings
     * @return Map of the Sales_Org__c custom settings
     */
    private Map<String, Sales_Org__c> readSalesOrgs() {
        Set<String> codes = new Set<String>();
        for (Order o : (List<Order>) this.Records) {
            if (o.SalesOrg__c != null && !codes.contains(o.SalesOrg__c)) {
                codes.add(o.SalesOrg__c);
            }
        }
        Map<String, Sales_Org__c> salesOrgsMap = new Map<String, Sales_Org__c>();
        for (Sales_Org__c org : new SalesOrgsSelector().selectBySAPId(codes)) {
            salesOrgsMap.put(org.SalesOrg__c, org);
        }
        return salesOrgsMap;
    }
}