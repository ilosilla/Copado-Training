/**
 * @name        BatchSAPPlantWarehouses
 * @author      Ramón Prades
 * @date        2025-07-07
 * @description
 *      Batch Apex class to synchronize both:
 *        - SAPPlant__c: from SAP_Plants__x
 *          (fields: Plant__c, Name ← Name1__c, Country__c ← Land1__c,
 *           Province__c ← Regio__c, Postcode__c ← Pstlz__c, Street__c ← Stras__c,
 *           SalesOrg__c ← Vkorg__c, PurchaseOrg__c ← Ekorg__c)
 *        - SAPWarehouse__c: from SAP_Warehouses__x (fields: Plant__c, Warehouse__c, Name, WarehouseKey__c)
 *
 *      Each section:
 *        - Inserts new records
 *        - Updates changed names or resets IsDeleted__c = false
 *        - Marks missing records as IsDeleted__c = true
 *
 *      In SAPWarehouse__c, the field Plant__c is a lookup to SAPPlant__c, resolved via Plant__c code.
 *
 * @execution
 *      Execute via: BatchSAPPlantWarehouses.executeNow();
 *      Background via: BatchSAPPlantWarehouses.submitInBatch();
 */
global class BatchSAPPlantWarehouses {
    global static Id submitInBatch() {
        return System.enqueueJob(new BackgroundJob());
    }
    global class BackgroundJob implements Queueable {
        global void execute(QueueableContext context) {
            SAPPlantWarehouseSynchronizer.executeNow();
        }
    }
}