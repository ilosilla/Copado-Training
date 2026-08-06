/**
 * @author         Ramón Prades
 * @date           August 2023
 * @group          SAP Events
 * @description    Platform Event handler for SAP delivery note events
*/
public class PEVSAPDeliveryTriggerHandler {
    
    public static void afterInsert(List<SAP_SD_Delivery__e> events) {
        SystemLog log = new SystemLog('SAP-EVENTS');
        log.setInputObject(events);
        log.addInfo('Processing ' + events.size() + ' events of type SAP COLLECTION');
        
        SAPCasesService.SAPDeliveryInfoDTO[] collections = new List<SAPCasesService.SAPDeliveryInfoDTO>();
        SAP_SD_Delivery__e[] samples = new List<SAP_SD_Delivery__e>();
        Integer numEvent = 0;
        for (SAP_SD_Delivery__e e : events) {
            try {
                log.addSection('Event #' + ++numEvent);
                if (e.IsCollection__c) {
                    collections.add(makeCollection(e));
                } else if (e.IsSample__c) {
                    samples.add(e);
                }
            } catch (Exception ex) {
                log.addError('Inner Exception: ' + ex);
                log.addDebug(e.data__c);
                e.addError('Error processing event: ' + ex.getMessage());
            }
        }        

        log.addDebug('Updating collections status');
        SAPCasesService.updateStatusFromSAP(collections);
        OrdersService.updateDeliveryStatus(samples);
        log.addDebug('Case status updated!');
    }

    private static SAPCasesService.SAPDeliveryInfoDTO makeCollection(SAP_SD_Delivery__e e) {
        SAPCasesService.SAPDeliveryInfoDTO dto = new SAPCasesService.SAPDeliveryInfoDTO();
        dto.orderNumber = e.OrderNumber__c;
        dto.deliveryNumber = e.DeliveryNumber__c;
        dto.action = e.Action__c;
        dto.status = e.Status__c;
        dto.goodsPosted = e.GoodsPosted__c;
        dto.items = new List<SAPCasesService.SAPDeliveryItemDTO>();
        if (String.isNotBlank(e.data__c)) {
            dto.items = (List<SAPCasesService.SAPDeliveryItemDTO>) JSON.deserialize(e.data__c, List<SAPCasesService.SAPDeliveryItemDTO>.class);
        }
        return dto;
    }
    
} // PEVSAPDeliveryTriggerHandler