/**
 * @author         Ramón Prades
 * @date           July 2024
 * @group          SAP
 * @description    Class to serialize a Sales Order for SAP
*/
public class SAPSalesOrderSerializer extends SAPAbstractAPISerializer {


    private static final String SAP_API_VERSION = '2.1';        
    
    @testVisible private Map<Id, List<OrderItem>> itemsByOrder;
    @testVisible private Map<Id, OrderDeliveryGroup> deliveryByOrder;
    private SAPOrderHeaderDTO[] SAPOrders;
    private Map<Id, WebStore> storesMap;

    private Set<Id> orderIds;
    private List<Order> orders;   
    private String emailAddress;
    
    public void setEmail(String email) {
        this.emailAddress = email;
    }

    protected override List<Object> readObjects(Set<Id> objectIds) {
        List<Object> result = new List<Object>();
        List<Order> orders = this.readOrders(objectIds);
        for (Order o : this.orders) {
            result.add((Object) o);
        }
        return result;
    }

    protected override String serializeObject(Object obj) {        
        SAPOrderHeaderDTO SAPOrder = this.buildOrderDTO((Order) obj);
        return SAPOrder.serialize();
    }

    // --------------------------------------------------------------------------------< PRIVATE SECTION

    @testVisible private List<Order> readOrders(Set<Id> objectIds) {
        OrdersSelector selector = new OrdersSelector();
        selector.addRelationshipField('Account.SAP_Id__c');
        List<Order> orders = selector.selectById(objectIds);
        this.orderIds = objectIds;
        this.orders = new List<Order>();
        Set<Id> storeIds = new Set<Id>();
        for (Order order : orders) {
            //if (order.StatusCode == 'Activated' && order.sapRequestStatus__c == 'ready' && order.Sap_Id__c == null) {
                this.orders.add(order);
                if (!storeIds.contains(order.SalesStoreId)) {
                    storeIds.add(order.SalesStoreId);
                }
            //}
        }
        this.readOrderItems();
        this.readOrderAddresses();
        return this.orders;
    }    

    private SAPOrderHeaderDTO buildOrderDTO(Order order) {        
        OrderDeliveryGroup deliveryGroup = this.deliveryByOrder?.get(order.Id);
        OrderItem[] orderItems = this.itemsByOrder.get(order.Id);
        return new SAPSalesOrderMapper(order, deliveryGroup, orderItems)
            .withConfirmationEmail(this.emailAddress)
            .transform();                   
    }

    private void readOrderItems() {
        OrderItemsSelector selector = new OrderItemsSelector();
        selector.addRelationshipField('Product.Umv__c');
        OrderItem[] items = selector.selectByOrderId(this.orderIds);
        this.itemsByOrder = new Map<Id, List<OrderItem>>();
        for (OrderItem item : items) {
            OrderItem[] l = itemsByOrder.get(item.OrderId);
            if (l == null) {
                l = new List<OrderItem>();                
                this.itemsByOrder.put(item.OrderId, l);
            }
            l.add(item);
        }
    }

    private void readOrderAddresses() {
        SAPOrderAddressHelper helper = new SAPOrderAddressHelper(this.orders);
        helper.matchSAPId();
        this.deliveryByOrder = helper.getDeliveryAddressesMap();
    }
    
}