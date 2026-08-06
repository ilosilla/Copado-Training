/**
 * @author         Ramón Prades
 * @date           August 2023
 * @group          SAP Events
 * @description    Platform Event handler for SAP credit note events
*/
public class PEVSAPInvoicesTriggerHandler {

    public static void afterInsert(List<SAP_SD_Invoices__e> events) {
        SAPCasesService.SAPCreditNoteDTO[] collections = new List<SAPCasesService.SAPCreditNoteDTO>();
        SystemLog log = new SystemLog('SAP-EVENTS');
        log.addInfo('Processing ' + events.size() + ' events of type SAP CREDITNOTE');
        log.saveLog();
        try {
            Integer numEvent = 0;
            for (SAP_SD_Invoices__e e : events) {
                log.addSection('Event #' + ++numEvent);
                log.setInputData(JSON.serializePretty(e));
                SAPCasesService.SAPCreditNoteDTO dto = new SAPCasesService.SAPCreditNoteDTO();
                dto.invoiceNumber = e.InvoiceNumber__c;
                dto.orderNumber = e.OrderNumber__c;
                dto.deliveryNumber = e.DeliveryNumber__c;
                dto.action = e.Action__c;
                dto.isCollection = e.IsCollection__c;
                dto.isReversal = e.isReversal__c;
                dto.isCredit = e.isCredit__c;
                dto.refInvoiceNumber = e.refInvoiceNumber__c;
                dto.salesOrg = e.SalesOrg__c;
                dto.channel = e.Channel__c;
                if (dto.isCollection && dto.action != 'UNCLEAR') {  // Desactivo UNCLEAR poara no reabrir casos cerrados
                    collections.add(dto);
                }
            }              
            log.addDebug('Updating case status');            
            if (collections.size() > 0) {
                SAPCasesService.setSAPCreditNote(collections);            
            }
            log.addDebug('Case credit note updated!');
        } catch(Exception ex2){            
            log.addSection('Outer Exception');
            log.addError(ex2);
            throw ex2;
        } finally {
            log.saveLog(true);
        }
    }

} // PEVSAPCollectionTriggerHandler}