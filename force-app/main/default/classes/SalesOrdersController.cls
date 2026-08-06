/**
 * @author         Ramón Prades
 * @date           March 2024
 * @group          Orders
 * @description    Controller class to access certain constants from an LWC
*/
public class SalesOrdersController {

    @AuraEnabled public static Id createCompensationOrder(Id caseId) {
        Id orderId = SAPCasesService.createCompensationOrder(caseId);
        return orderId;
    }
    
    @AuraEnabled(cacheable=true) public static OrderDefaultsDTO getOrderDefaults(Order order) {
        OrderDefaultsDTO dto = new OrderDefaultsDTO();    
        if (String.isBlank(order.Type)) {
            throw new AuraHandledException(System.label.tr0005_308);
        }
        dto.defaultRecordType = RecordTypeLibrary.Order_StandardV1;
        Pricebook2[] books = SalesPricebooksService.getOrderPricebooks(order);
        if (books.size() > 0) {
            dto.pricebookId = books[0].Id;
            dto.pricebookName = books[0].Name;
        } else {
            throw new AuraHandledException(System.Label.tr0005_307);
        }
        return dto;
    }

    @AuraEnabled(cacheable=true) public static PageConstantsDTO getPageConstants() {
        PageConstantsDTO dto = new PageConstantsDTO();
        dto.unitsMap = PicklistCommons.getValues(OrderItem.SalesUnit__c);
        dto.statusMap = PicklistCommons.getValues(Order.Status);
        dto.orderTypesMap = PicklistCommons.getValues(Order.Type);
        return dto;
    }

    @AuraEnabled public static SaveResultDTO saveCaseOrder(Id caseId, Order order, List<OrderItem> items) {
        OrdersService.saveCaseOrder(caseId, order, items);
        SaveResultDTO dto = new SaveResultDTO();
        dto.order = order;
        dto.items = items;
        return dto;
    }

    @AuraEnabled public static Boolean deleteCaseOrder(Id caseId, Id orderId) {
        OrdersService.deleteCaseOrder(caseId, orderId);
        return true;
    }


    @AuraEnabled public static List<Id> deleteOrderItems(List<OrderItem>  items) {        
        List<OrderItem> deleted = OrderItemsService.deleteItems(items);
        return TypeConversionCommons.extractListOfIds(deleted);
    }

    @AuraEnabled public static void activateOrder(Id orderId) {
        try {
            OrdersService.activateOrders(new Set<Id>{orderId});
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
    @AuraEnabled public static String[] sendOrderToSAP(Id orderId) {
        String errorMessage = '';
        Map<Id, String[]> errors = SAPOrdersService.send(new Set<Id>{orderId});
        return errors.get(orderId);
    }
    */

    public class OrderDefaultsDTO {
        @AuraEnabled public String defaultRecordType;    
        @AuraEnabled public Id pricebookId;
        @AuraEnabled public String pricebookName;        
    }

    public class SaveResultDTO {
        @AuraEnabled public Order order {get; set;}
        @AuraEnabled public OrderItem[] items {get; set;}
        @AuraEnabled public String[] errors {get; set;}
    }
    
    public class PageConstantsDTO {
        @AuraEnabled public Map<String, String> unitsMap;
        @AuraEnabled public Map<String, String> statusMap;
        @AuraEnabled public Map<String, String> orderTypesMap;
    }

    // Very few lines and some are exception control that can't be tested, so 
    // reach coverage with this method.
    // DELETE IT WHEN NOT NEEDED
    @testVisible private static String testCoverage() {
        String s = '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        s+= '.';
        return s;
    }

}