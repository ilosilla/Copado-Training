/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Orders service layer
 * ----
 * Version 1.1.0 - Free collections supported
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class OrdersService {

    private static final String ORDERS_LOG_SCENARIO = 'ORDER';
    private static final String CURRENT_ORDER_VERSION = 'V2';

    /**
     * Saves a sales order
     */
    public static void saveCaseOrder(Id caseId, Order order, List<OrderItem> items) {   
        SystemLog logger = new SystemLog(ORDERS_LOG_SCENARIO);
        logger.setTag('OrdersService.saveCaseOrder');
        List<SObject> inputs = new List<SObject>();
        inputs.add(order);
        inputs.addAll(items);
        logger.setInputObject(inputs);
        try {
            logger.addInfo('Order Id BEFORE the save is ' + order.Id);
            logger.addInfo('Order Type is ' + order.Type);
            OrdersService.saveOrder(order, items);
            Case c = new Case();
            c.Id = caseId;
            if (OrderCommons.isCollection(order)) {
                logger.addInfo('This is a collection');
                c.CollectionOrderId__c = order.Id;
            } else {
                logger.addInfo('This is NOT a collection');
                c.OrderId__c = order.Id;            
            }
            update c;
            logger.addInfo('Order created/updated succesfully');
            logger.addInfo('Order ID is ' + order.id);
            logger.saveLog(true);
        } catch (DmlException dex) {
            logger.addError('Dml Error creating the order');
            logger.addError(dex);
            SystemLog.writeLog(JSON.serialize(logger));
            throw dex;
        } catch (Exception ex) {
            logger.addError('Error creating the order');
            logger.addError(ex);
            SystemLog.writeLog(JSON.serialize(logger));
            throw ex;
        }
    }

    /**
     * Saves a sales order
     */
    public static void saveOrder(Order order, List<OrderItem> items) {   
        persistOrder(order, null, items);
    } // saveOrder

    /** 
     * Creates an order with its items and delivery group 
     */
    public static void createOrder(Order order, List<OrderItem> items, OrderDeliveryGroup deliveryGroup) {
        persistOrder(order, deliveryGroup, items);
    }

    /**
     * Saves a list of orders
     */
    public static void saveOrders(List<Order> orders) {
        update orders;
    }

    /**
     * Deletes an order
     */
    public static void deleteCaseOrder(Id caseId, Id orderId) {   
        // Use a select instead of the selector to read only the fields we are about to update
        Case c = [select Id, OrderId__c, CompensationOrderId__c, CollectionOrderId__c from Case where Id = :caseId limit 1];
        if (c.OrderId__c == orderId) {
            c.OrderId__c = null;
        } else if (c.CompensationOrderId__c == orderId) {
            c.CompensationOrderId__c =null;
        } else if (c.CollectionOrderId__c == orderId) {
            c.CollectionOrderId__c = null;
        }
        Order order = new Order(Id = orderId);
        delete order;
        //update c;
    }


    /**
     * Activates an order (sends it to SAP)
     */
    public static void activateOrders(Set<Id> orderIds) {
        Order[] orders = new List<Order>();
        for (Id orderId : orderIds ) {
            Order order = new Order();
            order.Id = orderId;
            order.Status = OrdersDomain.STATUS_ACTIVATED;
            order.Version__c = OrdersDomain.VERSION2;
            orders.add(order);
        }
        update orders;
    }

    /**
     * Updates the delivery status from an ORDER
     */
    public static void updateDeliveryStatus(List<SAP_SD_Delivery__e> events) {
        Map<String, SAP_SD_Delivery__e> eventsMap = new Map<String, SAP_SD_Delivery__e>();
        Set<String> orderNumbers = new Set<String>();
        for (SAP_SD_Delivery__e evt : events) {
            if (!orderNumbers.contains(evt.OrderNumber__c)) {
                orderNumbers.add(evt.OrderNumber__c);
                eventsMap.put(evt.OrderNumber__c, evt);
            }
        }
        List<Order> orders = new OrdersSelector().selectBySAPOrder(orderNumbers);
        for (Order ord : orders) {
            SAP_SD_Delivery__e e = eventsMap.get(ord.SAP_Id__c);
            if (e != null) {
                ord.SAPDeliveryNumber__c = e.DeliveryNumber__c;
                ord.SAPGoodsPosted__c = e.GoodsPosted__c;
            }
        }
        update orders;
    } 

    /**
     * Sets the SAP Order Number in a Salesfroce Order
     */
    public static void setSAPOrderNumber(Id orderId, String sapNumber) {
        Order o = new Order();
        o.Id = orderId;
        o.Sap_Id__c = sapNumber;
        o.SAPRequestStatus__c = OrdersDomain.SAP_REQUEST_ACCEPTED;
        update o;
    }
    
    /* -------------------------------------------------------------------------------- */

    /**
     * Saves a sales order
     */
    private static void persistOrder(Order order, OrderDeliveryGroup deliveryGroup, List<OrderItem> items) {   
        Boolean isNew = (order.Id == null);    
        if (isNew) {
            order.Version__c = CURRENT_ORDER_VERSION;
        } 
        upsert order;

         // Link and save the delivery group
        if (deliveryGroup != null) {
            deliveryGroup.OrderId = order.Id;
            upsert deliveryGroup;
        }

        // Items
        if (items != null && items.size() > 0) {
            Set<Id> products = new Set<Id>();
            for (OrderItem item :items) {
                if (item.OrderId == null) {
                    item.OrderId = order.Id;
                    item.OrderDeliveryGroupId = deliveryGroup?.Id;  
                }
                if (item.PricebookEntryId == null && !products.contains(item.Product2Id)) {
                    products.add(item.Product2Id);
                }
                if (item.UnitPrice == null) {
                    item.UnitPrice = 0;
                }
            }
            if (products.size() > 0) {
                setPricebookEntries(order.Pricebook2Id, order.CurrencyIsoCode, items, products);
            }
            upsert items;
        }   
    } // saveOrder


    /**
     * Sets the missing pricebook entries
     */
    private static void setPricebookEntries(Id pricebookId, String currencyCode, List<OrderItem> items, Set<Id> products) {
        Map<Id, PricebookEntry> entriesMap = PricingCommons.getPricebookEntries(pricebookId, currencyCode, products);
        for (OrderItem item : items) {
            if (item.PricebookEntryId == null && entriesMap.containsKey(item.Product2Id)) {
                PricebookEntry entry = entriesMap.get(item.Product2Id);
                item.PricebookEntryId = entry.Id;
            }
        }
     }
     


}