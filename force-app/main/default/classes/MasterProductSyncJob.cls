/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		Products
* @description 	Master program to synchronize SAP products with Salesforce. Reads information from ZSFMATBASE__X 
*               (salesforce connect table) and updates object Product2.
* ----------------------------------------------------------------------------------------------------------------
* Process updated products since the last date the program was executed (default)
*
* 3 modes of execution:
* - STANDARD: Reads products modified in SAP and updates the changes in Salesforce.
* - MAINTENANCE: Executes these tasks:
*     > Delete duplicates (by ProductCode) 
*     > Fills products with blank StockKeepingUnit.
* - ACTIVE: Updates isActive
* - CONVERSION: Refreshes the conversion factors (use setConversionMode)
* - UPDATE-F
*    > Updates a field (change method *updateFields* every time)
* 
* Methods:
* - "setDeleteDuplicates" to instruct the program to try to delete dups.
* - "setNumberOfItems" limits the products to process (for testing purposes mainly).
* - "setNumberOfDays" to set the days back to check for modifications
* - "syncPricebooks" to sync prices after products are updated (default is false) 
* - "setMaxInfo" to add the product codes updated on the confirmation email
*
* Two methods are specially important:
* - "sapToSalesforce" is the method where SAP fields are assigned to Salesforce fields, so any
*   new field has to be added here.
* - "updateFields" is calledd on every Product2 record when we run this in UPDATE mode. New fields
*   that need to be initialized or old fields that need updating should be handled here.
* ----------------------------------------------------------------------------------------------------------------
*            THIS CLASS IIS OBSOLETE AND HAS BEEN REPLACED BY BatchProductSyncOrchestrator
* ----------------------------------------------------------------------------------------------------------------
*/
global class MasterProductSyncJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    private final String logScenario = 'PRODUCT-SYNC';

    private enum ExecutionMode {STANDARD_MODE, MAINTENANCE_MODE, CONVERSION_MODE, UPDATE_MODE, ACTIVE_MODE}
    private List<Product2> dupProducts;
    private List<String> errorMessages;
    private ExecutionMode mode = ExecutionMode.STANDARD_MODE;
    private Boolean success = true;
    private Boolean syncBackofficeFlag = true;
    private Integer recordsProcessed = 0;
    private Integer recordsUpdated = 0;
    private Integer recordsCreated = 0;
    private Integer recordsDeleted = 0;
    private Boolean deleteDups = false;
    private Boolean syncPrices = false;
    private Integer numberOfDays = 0;
    private Integer maxItems = 0;
    private Boolean extendedInfo = false;
    private List<String> info;
    private Set<String> validUnits = new Set<String>();
    private SystemLog logger;
    private Map<String, String> validMakes;
    private Map<String, sObject> itemGroups;
    private Boolean isFirstExecution = false;
    
    global MasterProductSyncJob() {     
        this.logger = new SystemLog(this.logScenario);
        this.logger.setTag('MasterProductSyncJob');
        this.logger.addInfo('Proceso de sincronización de productos creado');
        this.logger.saveLog(false);
        this.dupProducts = new List<Product2>();
        this.errorMessages = new List<String>();
        this.info = new List<String>();
        this.success = true;
        this.recordsProcessed = 0;
        this.recordsUpdated = 0;
        this.recordsCreated = 0;
        this.recordsDeleted = 0;
        this.deleteDups = false;
        this.maxItems = 0;
        this.validMakes = PicklistCommons.getValues(Product2.SAPMake__c);
        this.itemGroups = TypeConversionCommons.listToMap(new ItemGroupsSelector().selectAll(), 'SAPGroup__c', true);
        this.logger.addDebug('Valid makes are ' + JSON.serialize(this.validMakes.keySet()));
    }

    global void setActiveMode() {
        this.mode = ExecutionMode.ACTIVE_MODE;
    }

    global void setMaintenaceMode() {
        this.mode = ExecutionMode.MAINTENANCE_MODE;
    }

    global void setConversionMode() {
        this.mode = ExecutionMode.CONVERSION_MODE;    
    }

    global void setUpdateMode() {
        this.mode = ExecutionMode.UPDATE_MODE;    
    }

    global void setStandardMode() {
        this.mode = ExecutionMode.STANDARD_MODE;
    }

    global void setMaxInfo(Boolean value) {
        this.extendedInfo = value;
    }

    global void setNumberOfDays(Integer days) {
        this.numberOfDays = days;    
    }

    global void syncPricebooks(Boolean value) {
        this.syncPrices = value;
    }

    global void setDeleteDuplicates(Boolean del) {
        this.deleteDups = del;
    }

    global void setNumberOfItems(Integer num) {
        this.maxItems = num;
    }

    global void setBackofficeSync(Boolean value) {
        this.syncBackofficeFlag = value;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.isStandardMode()) {
            return Database.getQueryLocator(this.buildQueryString());
        } else if (this.isMaintenanceMode()) {
            return Database.getQueryLocator(this.buildMaintenanceQuery());
        } else if (this.isActiveMode()) {
            return Database.getQueryLocator(this.buildActiveQuery());
        } else {
            // Conversion and Update modes
            return Database.getQueryLocator(this.buildSAPObjectQuery());
        } 
    }
    
    global void execute(System.SchedulableContext context) {
        this.logger.addInfo('Ejecución programada iniciada a las ' + System.now());
        //MasterProductSyncJob job = new MasterProductSyncJob();
        try {
            this.syncPricebooks(true);
            //Database.executeBatch(this);
        } catch (Exception ex) {
            this.logger.addError(ex);
            this.logger.saveLog(true);
        }
    } 

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (this.isFirstExecution) {
            this.isFirstExecution = false;
            this.runFirstExecutionTasks();         
        }
        if (this.isActiveMode()) {
            this.deleteDups = false;
            this.syncPrices = false;
            this.runActivateTasks(scope);
        } else if (this.isMaintenanceMode()) {
            this.deleteDups = true;
            this.syncPrices = false;
            this.runMaintenanceTasks(scope);
        } else if (this.isConversionMode()) {
            this.deleteDups = false;
            this.syncPrices = false;
            this.setConversions(scope);
        } else if (this.isUpdateMode()) {  
            this.deleteDups = false;
            this.syncPrices = false;
            this.updateFields(scope);      
        } else {
      	    this.syncProductsWithSAP(scope);
        }
    }

    global void finish(Database.BatchableContext bc){       
        if ((this.deleteDups || this.isMaintenanceMode()) && this.dupProducts.size() > 0) {
            try {
                this.logger.addInfo('Deleting duplicates ...');
                this.deleteDuplicates();
            } catch(Exception ex) {
                this.logger.addInfo('Exception received while deleting duplicates ...');
                this.logger.addError(ex);
            }
        }

        if (this.syncPrices && !this.isMaintenanceMode()) {
            try {
                this.logger.addInfo('Updating price books ...');
                BatchPriceUpdater.executeInBatch();
                MasterSamplesSyncJob.executeInBatch();
            } catch(Exception ex) {
                this.logger.addInfo('Exception received while updating price books ...');
                this.logger.addError(ex);
            }
        }

        try {
            logProductSync();
        } finally {
            this.logger.saveLog(true);
        }        
     } // finish

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/    

    private void runFirstExecutionTasks() {
        if (this.syncBackofficeFlag) {
            this.syncBackofficeData();
        }
    }

    private void syncProductsWithSAP(List<ZSFMatBase__x> sapProducts) {
        this.recordsProcessed += sapProducts.size();
        List<Product2> updatedProducts = new List<Product2>();
        Map<String, Product2> sfProducts = this.readSalesforceProducts(sapProducts);
        for (ZSFMatBase__x sapProduct : sapProducts) {
            Product2 changedProduct = this.sapToSalesforce(sapProduct);            
            if (sfProducts.containsKey(sapProduct.Material__c)) {
                Product2 existingProduct = sfProducts.get(sapProduct.Material__c);
                changedProduct.Id = existingProduct.Id;
                changedProduct.isActive = existingProduct.isActive && changedProduct.isActive;
                updatedProducts.add(changedProduct);
                info.add(changedProduct.ProductCode + '[' + changedProduct.Id + ']');
            } else {
                if (changedProduct.isActive) {
                    updatedProducts.add(changedProduct);
                    info.add(changedProduct.ProductCode + '[' + changedProduct.Id + ']');
                }
            }
        } 
        Database.UpsertResult[] results = Database.upsert(updatedProducts);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        }
    } // syncProductsWithSAP

    /*
     * Returns true if a product needs to be updated.
     * The conditions evaluated are:
     * - The make is a valid make AND
     * - It is finished proproduct OR
     * - It is a sample OR
     * - It is a spare product
     */
    private Boolean isProductSyncable(ZSFMatBase__x sapProduct) {
        Boolean syncable = false;
        if (this.validMakes.containsKey(sapProduct.Materia__c)) {            
            syncable = (sapProduct.GrupoArticulos__c?.startsWith('PT') ?? false);
            syncable = syncable || sapProduct.IsSample__c || sapProduct.isSampleAccessory__c;
            syncable = syncable || (sapProduct.TipoMaterial__c == 'ZRYC');
        } else {
            this.logger.addDebug('Product is not syncable because the make is not valid: ' + sapProduct.Materia__c);
        }
        return syncable;
    }

    private Map<String, Product2> readSalesforceProducts(List<ZSFMatBase__x> sapProducts) {
        Set<String> productCodes = this.buildProductCodesSet(sapProducts);
        List<Product2> productsList = new ProductsSelector().selectBySKU(productCodes);
        Map<String, Product2> sfProducts = new  Map<String, Product2>();
        for (Product2 pr : productsList) {            
            if (!sfProducts.containsKey(pr.StockKeepingUnit)) {
                sfProducts.put(pr.StockKeepingUnit, pr);
            } else {
                this.dupProducts.add(pr);
                this.info.add(pr.productCode + '[' + pr.Id + '] DUPLICATE');
            }
        }
        return sfProducts;
    } // readSalesforceProducts

    private Set<String> buildProductCodesSet(List<ZSFMatBase__x> sapProducts) {
        Set<String> productCodes = new Set<String>();
        for(ZSFMatBase__x matBase : sapProducts ) {
            if (!productCodes.contains(matBase.Material__c)) {
                productCodes.add(matBase.Material__c);
            }
        }
        return productCodes;
    } // buildProductCodesSet

    /*
     * Query for STANDARD mode
     * Reads all sap products modifified in the last X days
     */
    private  String buildQueryString() {                
        String objectName = 'ZSFMatBase__x';        
        Integer daysFilter = getDaysBack();
        String dateFilter = ' WHERE Modificado__c >= ' + String.valueOf(Date.today().addDays(-daysFilter)) + 'T00:00:00.000+0000';
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ' FROM ' + objectName + dateFilter;     
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }
        return query;
    } // buildQueryString

    /*
     * Query for ACTIVE mode 
     * Selects all active products
     */
    private  String buildActiveQuery() {            
        String query = 'SELECT Id, StockKeepingUnit, SAPMake__c, SAPItemGroup__c, SAPItemGroup__r.SAPGroup__c, SAPMAterialType__c FROM Product2 WHERE IsActive = true';
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }
        return query;
    } // buildMaintenanceQuery   


    /*
     * Query for MAINTENANCE mode 
     * Selects all products with blank StockKeepingUnit
     */
    private  String buildMaintenanceQuery() {            
        String query = 'SELECT Id, ProductCode, StockKeepingUnit FROM Product2 WHERE StockKeepingUnit = \'\'';
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }
        return query;
    } // buildMaintenanceQuery   
    
    /*
     * Query for UDPATE and CONVERSION modes
     * Reads all SAP Products
     */
    private String buildSAPObjectQuery() {             
        String objectName = 'ZSFMatBase__x';   
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ' FROM ' + objectName;
        if (this.maxItems > 0) {
            query += ' LIMIT ' + this.maxItems;
        }    
        return query;    
    } // buildSAPObjectQuery

    private Integer getDaysBack() {
        Integer days = this.numberOfDays;
        if (this.numberOfDays == 0) {
            try {
                PorcelanosaSetting setting = new PorcelanosaSetting('PRODUCT-SYNC', 'NDAYS');
                days = Integer.valueOf(setting.value1);
            } catch (Exception ex) {
                days = 3;
            }
        }
        return days;
    } // getDaysBack

    private Product2 sapToSalesforce(ZSFMatBase__x sapProductObj){        
        Product2 productObj = new Product2();
        productObj.IsActive = this.isProductSyncable(sapProductObj);
        productObj.CurrencyIsoCode = 'EUR';
        productObj.DisplayUrl = sapProductObj.DisplayUrl;
        productObj.Name = sapProductObj.Nombre__c;
        productObj.ProductCode = sapProductObj.Material__c;
        productObj.StockKeepingUnit = productObj.ProductCode;
        productObj.ExternalId = productObj.ProductCode;
        productObj.URL_PDF__c = sapProductObj.UrlPdf__c;
        productObj.URL_Photo_1__c = sapProductObj.UrlPhoto1__c;
        productObj.URL_Photo_2__c = sapProductObj.UrlPhoto2__c;
        productObj.URL_Photo_3__c = sapProductObj.UrlPhoto3__c;
        productObj.URL_Photo_4__c = sapProductObj.UrlPhoto4__c;
        productObj.URL_Photo_5__c = sapProductObj.UrlPhoto5__c;
        productObj.URL_Photo_6__c = sapProductObj.UrlPhoto6__c;
        productObj.Altura__c = sapProductObj.Altura__c;
        productObj.Ancho__c = sapProductObj.Ancho__c;
        productObj.Jerarquia__c = sapProductObj.Jerarquia__c;
        productObj.Longitud__c = sapProductObj.Longitud__c;
        productObj.Marca__c = sapProductObj.Marca__c;
        // productObj.Material__c = sapProductObj.Material__c;
        productObj.Modificado__c = sapProductObj.Modificado__c;
        productObj.Ramo__c = sapProductObj.Ramo__c;
        productObj.IsSample__c = (sapProductObj.IsSample__c || sapProductObj.IsSampleAccessory__c); 
        productObj.SAPMaterialType__c = sapProductObj.TipoMaterial__c;
        productObj.SAPMake__c = sapProductObj.Materia__c;
        if (productObj.SAPMake__c == 'C') {
            productObj.SAPMake__c = 'P';
        }
        productObj.SAPItemGroup__c = this.getItemGroup(sapProductObj.GrupoArticulos__c);
        this.setConversionFields(productObj, sapProductObj);

        return productObj;

    } // sapToSalesforce

    private Id getItemGroup(String grupoArticulos) {    
        Id groupId = null;    
        if (String.isNotBlank(grupoArticulos)) {
            ItemGroup__c itemGroup = (ItemGroup__c) this.itemGroups.get(grupoArticulos.toUpperCase());
            groupId = (itemGroup?.Id ?? null);
        }
        return groupId;
    }

    private void setConversionFields(Product2 product, ZSFMatBase__x sapProduct) {

        // Old conversion fields - deprecated!
        product.UmbCj__c = sapProduct.PzsCj__c;
        product.UmbKg__c = sapProduct.UmbKg__c;
        product.UmbMt2__c = sapProduct.Mt2Cj__c;
        product.UmbPal__c = sapProduct.CjPal__c;
        product.Umb__c = sapProduct.Umb__c;
        

        // New fields 
        product.stockUnit__c = this.setPicklistValue(sapProduct.Umb__c);
        product.salesUnit__c = this.setPicklistValue(sapProduct.Umv__c);
        product.UnitsXBox__c = sapProduct.UmbCj__c;
        product.UnitsXM2__c = sapProduct.UmbMt2__c;
        product.UnitsXPal__c = sapProduct.UmbPal__c;
        product.UnitWeight__C = sapProduct.UmbKg__c;
        product.PcsXBox__c = sapProduct.PzsCj__c;
        product.M2XBox__c = sapProduct.Mt2Cj__c;
        product.BoxXPal__c = sapProduct.CjPal__c;
        product.Umv__c = sapProduct.Umv__c;
        product.PesoUMV__c = sapProduct.PesoUMV__c;
    }

    private void logProductSync() {
        String newLine = '<br/>';
        String text = 'Success: ' + this.success + newLine;
        text += 'Maintenace Mode: ' + this.isMaintenanceMode() + newLine;
        text += 'Conversion Mode: ' + this.isConversionMode() + newLine;
        text += 'Processed: ' + this.recordsProcessed + newLine;
        text += 'Duplicates: ' + this.dupProducts.size() + newLine;
        text += 'Created: ' + this.recordsCreated + newLine;
        text += 'Updated: ' + this.recordsUpdated + newLine;
        text += 'Deleted: ' + this.recordsDeleted + newLine;
        this.logger.addInfo(text);
        if (this.errorMessages.size() == 0) {
            this.logger.setSummary('MasterProductSyncJob completado con éxito');
        } else {
            this.logger.setSummary('MasterProductSyncJob completado con errores');
            text += newLine + 'Errors' + newLine + newLine;
            for (String message : this.errorMessages) {
                text += '- '  + message + newLine;
            }
            this.logger.addError(text);
        }    
    }

    private void deleteDuplicates() {
        if (this.deleteDups) {
            Database.deleteResult[] results = Database.delete(this.dupProducts);
            for (Database.DeleteResult result : results) {
                if (result.isSuccess()) {
                    this.recordsDeleted++;
                } else {
                    for (Database.Error error : result.getErrors()) {
                        this.errorMessages.add(error.message);
                    }        
                }
            }        
        }
    } // deleteDuplicates

    private void parseUpsertResult(Database.UpsertResult result) {
        this.success = (this.success && result.isSuccess());
        if (result.isSuccess()) {
            if (result.isCreated()) {
                this.recordsCreated++;
            } else {
                this.recordsUpdated++;
            }
        } else {
            this.success = false;
            for (Database.Error error : result.getErrors()) {
                this.errorMessages.add(error.message);
            }
        }
    } // parseUpsertResult

    private void runActivateTasks(List<Product2> products) {
        List<Product2> changed = new List<Product2>();
        for (Product2 product :products) {
            Boolean isActive = false;
            if (this.validMakes.containsKey(product.SAPMake__c)) {
                isActive = (product.SAPItemGroup__r.SAPGroup__c?.startsWith('PT') ?? false);
                isActive = isActive || product.IsSample__c  || (product.SAPMaterialType__c == 'ZRYC');
            }
            if (!isActive) {
                product.isActive = false;
                changed.add(product);
            }
        } 
        if (changed.size() > 0) {
            this.recordsUpdated += changed.size();
            this.logger.addDebug(' --> Active changed to false in products: ' + changed.size());
            update changed;
        }        
    }

    private void runMaintenanceTasks(List<Product2> products) {
        products = this.dedupProducts(products);
        List<Product2> updatedProducts = new List<Product2>();
        Map<string, Product2> productIndex = prepareSKUIndex(products);
        this.recordsProcessed += products.size();
        for (Product2 p : products) {
            if (productIndex.containsKey(p.ProductCode)) {
                this.dupProducts.add(p);
                this.info.add(p.productCode + '[' + p.Id + '] DUPLICATE');
            } else {
                p.StockKeepingUnit = p.ProductCode; 
                updatedProducts.add(p);               
                this.info.add(p.productCode + '[' + p.Id + ']');
            }
        }
        Database.UpsertResult[] results = Database.upsert(updatedProducts);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        }
    }

    /**
     * It is possible to have the same product code twice on products (if both rows have StockKeepingUnit empty)
     * Remove those duplicates to avoid exceptions
     */
    private List<Product2> dedupProducts(List<Product2> products) {
        List<Product2> result = new List<Product2>();
        Set<String> pcodes = new Set<String>();
        for (Product2 p : products) {
            if (!pcodes.contains(p.ProductCode)) {
                result.add(p);
                pcodes.add(p.ProductCode);
            } else {
                this.dupProducts.add(p);
            }
        }
        return result;
    } // dedupProducts

    private Map<String, Product2> prepareSKUIndex(List<Product2> products) {
        Set<String> pcodes = new Set<String>();
        for (Product2 p : products) {
            if (!pcodes.contains(p.ProductCode)) {
                pcodes.add(p.ProductCode);
            }
        }
        
        Map<String, Product2> index = new Map<String, Product2>();
        List<Product2> productsSKU = [select Id, ProductCode from Product2 where StockKeepingUnit in :pcodes ];
        for (Product2 p : productsSKU) {
            index.put(p.ProductCode, p);
        }
        return index;
    }

    private void updateFields(List<ZSFMatBase__x> sapProducts) {
        String[] invalidMakes = new List<String>();
        List<Product2> changed = new List<Product2>();
        this.recordsProcessed += sapProducts.size();

        Map<String, ZSFMatBase__x> sapProductsMap = new Map<String, ZSFMatBase__x>();
        for (ZSFMatBase__x sapProduct :sapProducts) {
            sapProductsMap.put(sapProduct.Material__c, sapProduct);
        }
        List<Product2> products = new ProductsSelector().selectBySKU(sapProductsMap.keySet());
        for (Product2 p : products) {
            ZSFMatBase__x sapProduct = sapProductsMap.get(p.ProductCode);
            if (sapProduct != null) {
                if (this.validMakes.containsKey(sapProduct.Materia__c)) {
                    // Fields to update from SAP go here
                    p.isActive = true;
                    p.SAPMaterialType__c = sapProduct.TipoMaterial__c;
                    p.SAPMake__c = sapProduct.Materia__c;         
                    p.SAPItemGroup__c = this.getItemGroup(sapProduct.GrupoArticulos__c);
                    p.isActive = (p.isActive && this.isProductSyncable(sapProduct));
                    changed.add(p);
                } else {
                    if (!invalidMakes.contains(sapProduct.Materia__c)) {
                        invalidMakes.add(sapProduct.Materia__c);
                    }
                }
            }
        }
        if (invalidMakes.size() > 0) {
            this.logger.addDebug('Invalid Makes ' + String.join(invalidMakes, ','));
        }
        Database.UpsertResult[] results = Database.upsert(changed);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        }                
    } // updateFields

    private void setConversions(List<ZSFMatBase__x> sapProducts) {
        List<Product2> changed = new List<Product2>();
        this.recordsProcessed += sapProducts.size();
        Map<String, ZSFMatBase__x> sapProductsMap = new Map<String, ZSFMatBase__x>();
        for (ZSFMatBase__x sapProduct :sapProducts) {
            sapProductsMap.put(sapProduct.Material__c, sapProduct);
        }
        List<Product2> products = new ProductsSelector().selectByProductCode(sapProductsMap.keySet());
        for (Product2 p : products) {
            ZSFMatBase__x sapProduct = sapProductsMap.get(p.ProductCode);
            this.setConversionFields(p, sapProduct);
            changed.add(p);
        }
        Database.UpsertResult[] results = Database.upsert(changed);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        }
    }

   private String setPicklistValue(String unit) {
        if (this.validUnits.size() == 0) {
            Map<String, String> valueSet = PicklistCommons.getUpperCaseKeys(Product2.StockUnit__c);
            this.validUnits = valueSet.keySet();
            if (this.validUnits.size() == 0) {
                throw new ObjectNotFoundException('Units picklist not found');
            }
        }
        unit = unit.toUpperCase();
        if (this.validUnits.contains(unit)) {
            return unit;
        } else {
            return 'UN';
        }
    }

    private Boolean isStandardMode() {
        return this.mode == executionMode.STANDARD_MODE;
    }

    private Boolean isMaintenanceMode() {
        return this.mode == executionMode.MAINTENANCE_MODE;
    }

    private Boolean isConversionMode() {
        return this.mode == executionMode.CONVERSION_MODE;
    }

    private Boolean isUpdateMode() {
        return this.mode == executionMode.UPDATE_MODE;
    }

    private Boolean isActiveMode() {
        return this.mode == executionMode.ACTIVE_MODE;
    }

    private void syncBackofficeData() {
        MasterProductBackofficeSync syncer = new MasterProductBackofficeSync();
        Integer nrecords = syncer.sync();
        this.logger.addInfo('Backoffice synced record ' + nrecords);
    }

}