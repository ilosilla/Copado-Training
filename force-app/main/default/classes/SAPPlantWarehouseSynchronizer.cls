/**
 * @name        SAPPlantWarehouseSynchronizer
 * @author      Ramón Prades
 * @date        2025-07-07
 * @description
 *      Synchronizes both:
 *        - SAPPlant__c from SAP_Plants__x
 *          CampoDestino ← CampoOrigen : Comentario
 *          Plant__c ← Plant__c : Plant code
 *          Name ← Name1__c : Plant name
 *          Country__c ← Land1__c : Country
 *          Province__c ← Regio__c : Province / region
 *          Postcode__c ← Pstlz__c : Postcode
 *          Street__c ← Stras__c : Street
 *          SalesOrg__c ← Vkorg__c : Sales organization
 *          PurchaseOrg__c ← Ekorg__c : Purchase organization
 *
 *        - SAPWarehouse__c from SAP_Warehouses__x
 *          CampoDestino ← CampoOrigen : Comentario
 *          Plant__c ← Plant__c : Lookup to SAPPlant__c resolved by plant code
 *          Warehouse__c ← Warehouse__c : Warehouse code
 *          Name ← Name__c : Warehouse name
 *          WarehouseKey__c ← Plant__c + '-' + Warehouse__c : Unique warehouse key
 *
 *      Synchronization rules:
 *        - Inserts new records.
 *        - Updates changed records.
 *        - Resets IsDeleted__c = false when a previously deleted record appears again.
 *        - Marks missing local records as IsDeleted__c = true.
 *
 * @execution
 *      Execute via:
 *          SAPPlantWarehouseSynchronizer.executeNow();
 *
 * @designNotes
 *      External objects must be queried before any DML operation.
 *      Reading SAP_Plants__x or SAP_Warehouses__x after inserting/updating Salesforce
 *      records in the same transaction can fail because Salesforce treats the external
 *      object access as an external data source call.
 *
 *      For this reason, executeNow() loads all external source data first and then runs
 *      the local synchronization logic using in-memory lists.
 */
global class SAPPlantWarehouseSynchronizer {

    @TestVisible private static List<SAP_Plants__x> mockedPlants;
    @TestVisible private static List<SAP_Warehouses__x> mockedWarehouses;

    /* =========================================================
       PUBLIC METHODS (API)
       ========================================================= */

    global static void executeNow() {
        SAPPlantWarehouseSynchronizer synchronizer = new SAPPlantWarehouseSynchronizer();

        List<SAP_Plants__x> plantSources = getPlantSources();
        List<SAP_Warehouses__x> warehouseSources = getWarehouseSources();

        synchronizer.syncPlants(plantSources);
        synchronizer.syncWarehouses(warehouseSources);
    }

    /* =========================================================
       PRIVATE METHODS
       ========================================================= */

    private void syncPlants(List<SAP_Plants__x> plantSources) {
        Map<String, PlantSnapshot> plantsMap = new Map<String, PlantSnapshot>();

        for (SAP_Plants__x src : plantSources) {
            if (String.isBlank(src.Plant__c)) {
                continue;
            }

            PlantSnapshot snapshot = plantsMap.get(src.Plant__c);

            if (snapshot == null) {
                snapshot = new PlantSnapshot(src.Plant__c);
                plantsMap.put(src.Plant__c, snapshot);
            }

            snapshot.applySource(src);
        }

        Map<String, SAPPlant__c> existingMap = new Map<String, SAPPlant__c>();

        for (SAPPlant__c plant : [
            SELECT Id,
                   Plant__c,
                   Name,
                   Country__c,
                   Province__c,
                   Postcode__c,
                   Street__c,
                   SalesOrg__c,
                   PurchaseOrg__c,
                   IsDeleted__c
            FROM SAPPlant__c
        ]) {
            existingMap.put(plant.Plant__c, plant);
        }

        Set<String> activeKeys = plantsMap.keySet();
        List<SAPPlant__c> plantsToInsert = new List<SAPPlant__c>();
        List<SAPPlant__c> plantsToUpdate = new List<SAPPlant__c>();

        for (String plantCode : activeKeys) {
            PlantSnapshot sourcePlant = plantsMap.get(plantCode);

            if (existingMap.containsKey(plantCode)) {
                SAPPlant__c existingPlant = existingMap.get(plantCode);
                existingPlant.Name = sourcePlant.name;
                existingPlant.Country__c = sourcePlant.country;
                existingPlant.Province__c = sourcePlant.province;
                existingPlant.Postcode__c = sourcePlant.postcode;
                existingPlant.Street__c = sourcePlant.street;
                existingPlant.SalesOrg__c = sourcePlant.salesOrg;
                existingPlant.PurchaseOrg__c = sourcePlant.purchaseOrg;
                existingPlant.IsDeleted__c = false;
                plantsToUpdate.add(existingPlant);
                continue;
            }

            if (!PicklistCommons.isPicklistValue(SAPPlant__c.SalesOrg__c, sourcePlant.salesOrg)) {
                continue;
            }

            plantsToInsert.add(new SAPPlant__c(
                Plant__c       = plantCode,
                Name           = sourcePlant.name,
                Country__c     = sourcePlant.country,
                Province__c    = sourcePlant.province,
                Postcode__c    = sourcePlant.postcode,
                Street__c      = sourcePlant.street,
                SalesOrg__c    = sourcePlant.salesOrg,
                PurchaseOrg__c = sourcePlant.purchaseOrg,
                IsDeleted__c   = false
            ));
        }

        for (SAPPlant__c existingPlant : existingMap.values()) {
            if (!activeKeys.contains(existingPlant.Plant__c) && !existingPlant.IsDeleted__c) {
                existingPlant.IsDeleted__c = true;
                plantsToUpdate.add(existingPlant);
            }
        }

        if (!plantsToInsert.isEmpty()) {
            insert plantsToInsert;
        }

        if (!plantsToUpdate.isEmpty()) {
            update plantsToUpdate;
        }
    }

    private void syncWarehouses(List<SAP_Warehouses__x> warehouseSources) {
        Map<String, Id> plantCodeToId = new Map<String, Id>();

        for (SAPPlant__c plant : [
            SELECT Id,
                   Plant__c
            FROM SAPPlant__c
            WHERE IsDeleted__c = false
        ]) {
            plantCodeToId.put(plant.Plant__c, plant.Id);
        }

        Map<String, SAPWarehouse__c> existingMap = new Map<String, SAPWarehouse__c>();

        for (SAPWarehouse__c warehouse : [
            SELECT Id,
                   Plant__c,
                   Warehouse__c,
                   Name,
                   WarehouseKey__c,
                   IsDeleted__c
            FROM SAPWarehouse__c
        ]) {
            existingMap.put(warehouse.WarehouseKey__c, warehouse);
        }

        Set<String> activeKeys = new Set<String>();
        List<SAPWarehouse__c> warehousesToInsert = new List<SAPWarehouse__c>();
        List<SAPWarehouse__c> warehousesToUpdate = new List<SAPWarehouse__c>();

        for (SAP_Warehouses__x src : warehouseSources) {
            if (String.isBlank(src.Plant__c) || String.isBlank(src.Warehouse__c)) {
                continue;
            }

            String plantCode = src.Plant__c;
            String warehouseCode = src.Warehouse__c;
            String warehouseKey = buildWarehouseKey(plantCode, warehouseCode);

            if (!plantCodeToId.containsKey(plantCode)) {
                continue;
            }

            activeKeys.add(warehouseKey);

            Id plantId = plantCodeToId.get(plantCode);

            if (existingMap.containsKey(warehouseKey)) {
                SAPWarehouse__c existingWarehouse = existingMap.get(warehouseKey);

                if (hasWarehouseChanged(existingWarehouse, src, plantId)) {
                    existingWarehouse.Name = src.Name__c;
                    existingWarehouse.Plant__c = plantId;
                    existingWarehouse.Warehouse__c = warehouseCode;
                    existingWarehouse.IsDeleted__c = false;

                    warehousesToUpdate.add(existingWarehouse);
                }

                continue;
            }

            warehousesToInsert.add(new SAPWarehouse__c(
                Plant__c        = plantId,
                Warehouse__c    = warehouseCode,
                Name            = src.Name__c,
                WarehouseKey__c = warehouseKey,
                IsDeleted__c    = false
            ));
        }

        for (SAPWarehouse__c existingWarehouse : existingMap.values()) {
            if (!activeKeys.contains(existingWarehouse.WarehouseKey__c) && !existingWarehouse.IsDeleted__c) {
                existingWarehouse.IsDeleted__c = true;
                warehousesToUpdate.add(existingWarehouse);
            }
        }

        if (!warehousesToInsert.isEmpty()) {
            insert warehousesToInsert;
        }

        if (!warehousesToUpdate.isEmpty()) {
            update warehousesToUpdate;
        }
    }

    private static Boolean hasWarehouseChanged(
        SAPWarehouse__c existingWarehouse,
        SAP_Warehouses__x sourceWarehouse,
        Id plantId
    ) {
        return existingWarehouse.Name != sourceWarehouse.Name__c
            || existingWarehouse.Plant__c != plantId
            || existingWarehouse.Warehouse__c != sourceWarehouse.Warehouse__c
            || existingWarehouse.IsDeleted__c;
    }

    private static String buildWarehouseKey(String plantCode, String warehouseCode) {
        return plantCode + '-' + warehouseCode;
    }

    private static String pickValue(String currentValue, String newValue) {
        return String.isNotBlank(currentValue) ? currentValue : newValue;
    }

    @TestVisible
    private static List<SAP_Plants__x> getPlantSources() {
        if (Test.isRunningTest()) {
            return mockedPlants ?? new List<SAP_Plants__x>();
        }

        return [
            SELECT Plant__c,
                   Name1__c,
                   Land1__c,
                   Regio__c,
                   Pstlz__c,
                   Stras__c,
                   Vkorg__c,
                   Ekorg__c
            FROM SAP_Plants__x
            WHERE Plant__c != null
            AND Plant__c != '0001'
        ];
    }

    @TestVisible
    private static List<SAP_Warehouses__x> getWarehouseSources() {
        if (Test.isRunningTest()) {
            return mockedWarehouses ?? new List<SAP_Warehouses__x>();
        }

        return [
            SELECT Plant__c,
                   Warehouse__c,
                   Name__c
            FROM SAP_Warehouses__x
            WHERE Plant__c != null
            AND Warehouse__c != null
        ];
    }

    /* =========================================================
       PRIVATE DTOs
       ========================================================= */

    private class PlantSnapshot {
        private String plantCode;
        private String name;
        private String country;
        private String province;
        private String postcode;
        private String street;
        private String salesOrg;
        private String purchaseOrg;

        private PlantSnapshot(String plantCode) {
            this.plantCode = plantCode;
        }

        private void applySource(SAP_Plants__x src) {
            this.name = pickValue(this.name, src.Name1__c);
            this.country = pickValue(this.country, src.Land1__c);
            this.province = pickValue(this.province, src.Regio__c);
            this.postcode = pickValue(this.postcode, src.Pstlz__c);
            this.street = pickValue(this.street, src.Stras__c);
            this.salesOrg = pickValue(this.salesOrg, src.Vkorg__c);
            this.purchaseOrg = pickValue(this.purchaseOrg, src.Ekorg__c);
        }
    }
}