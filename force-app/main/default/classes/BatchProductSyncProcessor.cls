/**
 * @name        BatchProductSyncProcessor
 * @author      Ramón Prades
 * @date        April 2026
 * @group       SAP Integration - Products
 * @description 
 *      Handles the full synchronization of SAP product data into Salesforce.
 *      - Builds a material index from ZSfMatOrgv__x.
 *      - Processes Product2 records using the index (FULL or INCREMENTAL mode).
 *      - Supports scheduled or manual execution.
 *      - Tracks all activity through SystemLog and maintains execution state using Database.Stateful.
 *      - Optionally run the price update process at the end.
 * 
 * ===================================================================================================
 * ⚠️ IMPORTANT: This batch should only be executed through BatchProductSyncOrchestrator.
 *              The orchestrator handles critical pre-sync steps such as backoffice data loading. 
 * ===================================================================================================
 */

 public class BatchProductSyncProcessor implements Database.Batchable<SObject>, Database.Stateful {

    private Boolean fullMode = false;
    private Integer daysBack = 0;
    private Boolean runPricebookUpdate = false;
    private Boolean runB2BSync = false;
    private Set<String> materialIndex = new Set<String>();
    private SystemLog logger;
    private Map<String, String> validMakes;
    private Map<String, sObject> itemGroups;
    private Set<String> validUnits = new Set<String>();
    private Boolean forceActive = false;
    private Results resultObject;
    private DateTime startTime;
    private SAPDataReader sapReader = new SAPDataReader();
    private String [] skuFilter = new List<String>();

    // ---------------------- CONFIGURATION SETTERS ----------------------

    public void setLogger(SystemLog logger) {
        this.logger = logger;
    }

    public void setFullMode(Boolean value) {
        this.fullMode = value;
    }

    public void setDaysBack(Integer value) {
        this.daysBack = value;
    }

    public void setRunPricebookUpdate(Boolean value) {
        this.runPricebookUpdate = value;
    }

    public void setRunB2BSync(Boolean value) {
        this.runB2BSync = value;
    }

    public void setForceActive(Boolean value) {
        this.forceActive = value;
    }

    public void setSAPDataReader(SAPDataReader reader) {
        this.sapReader = reader;
    }

    public void setSKUFilter(List<String> filter) {
        this.fullMode = false;
        this.skuFilter = filter;
    }

    // ---------------------- BATCH START ----------------------

    public Database.QueryLocator start(Database.BatchableContext context) {
        if (this.logger == null) {
            this.logger = new SystemLog('PRODUCT-SYNC');
            this.logger.setSummary('BatchProductSyncProcessor');
            this.logger.setTag('Processor');
        }

        this.resultObject = new Results();
        this.startTime = DateTime.now();
        logger.addSection('Batch start: Product sync');
        logger.addInfo('Mode: ' + (this.fullMode ? 'FULL' : 'INCREMENTAL'));
        logger.addInfo('Force Active: ' + this.forceActive);

        // Prepare instance variables
        this.validMakes = PicklistCommons.getValues(Product2.SAPMake__c);     
        this.itemGroups = TypeConversionCommons.listToMap(new ItemGroupsSelector().selectAll(), 'SAPGroup__c', true);   

        // Build the query
        String objectName = 'ZSFMatBase__x';        
        String whereClause = '';
        if (!this.fullMode) {
            if (this.skuFilter?.size() > 0) {
                String sep = '';
                whereClause = ' WHERE Material__c in (';
                for (String sku : this.skuFilter) {
                    whereClause += sep + '\'' + String.escapeSingleQuotes(sku) + '\'';
                    sep = ',';
                }
                whereClause += ')';
            } else {
                if (this.daysBack == 0) {
                    try {
                        this.daysBack = Integer.valueOf(new PorcelanosaSetting('PRODUCT-SYNC', 'NDAYS').value1);
                    } catch(ObjectNotFoundException onf) {
                        logger.addWarning('Warning: Porcelansoa Setting/PRODUCT-SYNC/NDAYS not found: ' + onf.getMessage());
                        this.daysBack = 5;
                    }
                }
                this.logger.addInfo('Configured daysBack: ' + daysBack);    
                whereClause = ' WHERE Modificado__c >= ' + String.valueOf(Date.today().addDays(-this.daysBack)) + 'T00:00:00.000+0000';
            }
        }
        String query = 'SELECT ' + DatabaseCommons.getFieldList(objectName) + ' FROM ' + objectName + whereClause;     
        return Database.getQueryLocator(query);
    }
    
       // ---------------------- BATCH EXECUTE ----------------------

       public void execute(Database.BatchableContext context, List<ZSFMatBase__x> scope) {
            this.syncProductsWithSAP(scope);
        }

        public void finish(Database.BatchableContext bc){ 
            Datetime endTime = Datetime.now();
            Long elapsedMillis = endTime.getTime() - this.startTime.getTime();
            Integer totalSeconds = (Integer)(elapsedMillis / 1000);
            Integer minutes = totalSeconds / 60;
            Integer seconds = Math.mod(totalSeconds, 60);            
            this.logger.addInfo('Elapsed time: ' + minutes + 'm ' + seconds + 's');
            // ⚠️ NOTA DE CONCURRENCIA: los procesos lanzados desde aquí (pricebook update y B2B sync)
            // se ejecutan en paralelo, ya que Salesforce no garantiza orden entre batches lanzados
            // desde el mismo finish(). Actualmente no hay dependencias entre ellos, pero si en el
            // futuro el B2B sync necesitara precios actualizados (o viceversa), habría que encadenarlos.
            if (this.runPricebookUpdate) {
                try {
                    this.logger.addInfo('Updating price books ...');
                    BatchPriceUpdater.executeInBatch();
                    MasterSamplesSyncJob.executeInBatch();
                } catch(Exception ex) {
                    this.logger.addInfo('Exception received while updating price books ...');
                    this.logger.addError(ex);
                }
            }

            if (this.runB2BSync) {
                try {
                    this.logger.addInfo('Launching B2B sync (PIM → Images → CMS) ...');
                    BatchB2BSyncOrchestrator.executeBatch();
                } catch(Exception ex) {
                    this.logger.addInfo('Exception received while launching B2B sync ...');
                    this.logger.addError(ex);
                }
            }
            try {
                logProductSync();
            } finally {
                this.logger.saveLog(true);
            }        
         } // finish
    
    /***************************************************/
    /***************** PRIVATE METHODS *****************/
    /***************************************************/

    private void syncProductsWithSAP(List<ZSFMatBase__x> sapProducts) {
        
        List<Product2> productsToUpdate = new List<Product2>();

        this.resultObject.recordsProcessed += sapProducts.size();
        Set<String> productCodes = this.buildProductCodesSet(sapProducts);
        Set<String> productsInOrgs = this.buildProductIndex(productCodes);
        Map<String, Product2> sforceProducts = this.readSalesforceProducts(productCodes);
                
        for (ZSFMatBase__x sapProduct : sapProducts) {
            Boolean productEnabled = productsInOrgs.contains(sapProduct.Material__c);
            Product2 changedProduct = this.sapToSalesforce(sapProduct);  
            if (this.validMakes.containsKey(changedProduct.SAPMake__c)) {             
                if (sforceProducts.containsKey(sapProduct.Material__c)) {
                    Product2 existingProduct = sforceProducts.get(sapProduct.Material__c);
                    changedProduct.Id = existingProduct.Id;
                    changedProduct.isActive = productEnabled && (this.forceActive || (existingProduct.isActive && changedProduct.isActive));
                    productsToUpdate.add(changedProduct);
                } else {
                    if (productEnabled && changedProduct.isActive) {
                        productsToUpdate.add(changedProduct);
                    } else {
                        this.resultObject.recordsIgnored++;
                    }
                }
            } else {
                this.logger.addWarning('- Product ' + changedProduct.StockKeepingUnit + ' ignored: Make is not valid (' + changedProduct.SAPMake__c +  ')');
            }
        } 

        Database.UpsertResult[] results = Database.upsert(productsToUpdate);
        for (Database.UpsertResult result : results) {
            this.parseUpsertResult(result);
        }
    } // syncProductsWithSAP

    private Product2 sapToSalesforce(ZSFMatBase__x sapProductObj){        
        Product2 productObj = new Product2();
        productObj.IsActive = true; // It is enabled in a sales org, so it is active
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

        // Prepare the MAKE
        String marca = sapProductObj.Materia__c;
        if (marca == 'C') {
            marca = 'P';
        } else if (marca?.toUpperCase() == 'SIN MARCA') {
            marca = '-';
        }
        productObj.SAPMake__c = marca;
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
        product.UnitWeight__c = sapProduct.UmbKg__c;
        product.PcsXBox__c = sapProduct.PzsCj__c;
        product.M2XBox__c = sapProduct.Mt2Cj__c;
        product.BoxXPal__c = sapProduct.CjPal__c;
        product.Umv__c = sapProduct.Umv__c;
        product.PesoUMV__c = sapProduct.PesoUMV__c;
    }

    private Map<String, Product2> readSalesforceProducts(Set<String> productCodes) {
        List<Product2> productsList = new ProductsSelector().selectBySKU(productCodes);
        Map<String, Product2> sfProducts = new  Map<String, Product2>();
        for (Product2 pr : productsList) {            
            if (!sfProducts.containsKey(pr.StockKeepingUnit)) {
                sfProducts.put(pr.StockKeepingUnit, pr);
            }
        }
        return sfProducts;
    } // readSalesforceProducts

    // Builds a set with the products included in the scope
    private Set<String> buildProductCodesSet(List<ZSFMatBase__x> sapProducts) {
        Set<String> productCodes = new Set<String>();
        for(ZSFMatBase__x matBase : sapProducts ) {
            productCodes.add(matBase .Material__c);
        }
        return productCodes;
    }

    // Builds the set of material codes to be synchronized, based on entries found in ZSFMatOrgv__x
    private Set<String> buildProductIndex(Set<String> sapProducts) {
        // Read the products that are enabled in at least a sales organisation
        Set<String> selectedProducts = this.sapReader.readOrgData(sapProducts);
        return selectedProducts;
    } // buildProductCodesSet

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

    private void parseUpsertResult(Database.UpsertResult result) {
        this.resultObject.success = (this.resultObject.success && result.isSuccess());
        if (result.isSuccess()) {
            if (result.isCreated()) {
                this.resultObject.recordsCreated++;
            } else {
                this.resultObject.recordsUpdated++;
            }
        } else {
            this.resultObject.recordsError++;
            this.resultObject.success = false;
            for (Database.Error error : result.getErrors()) {
                this.resultObject.errors.add(error.message);
            }
        }
    } // parseUpsertResult

    private void logProductSync() {
        String newLine = '<br/>';
        String text = 'Success: ' + this.resultObject.success + newLine;
        text += 'Processed: ' + this.resultObject.recordsProcessed + newLine;
        text += 'Created: ' + this.resultObject.recordsCreated + newLine;
        text += 'Updated: ' + this.resultObject.recordsUpdated + newLine;
        text += 'Errors: ' + this.resultObject.recordsError + newLine;
        text += 'Ignored: ' + this.resultObject.recordsIgnored + newLine;
        this.logger.addSection('Results');
        this.logger.addInfo(text);
        if (this.resultObject.recordsError == 0) {
            this.logger.setSummary('MasterProductSyncJob completado con éxito');
        } else {
            this.logger.setSummary('MasterProductSyncJob completado con errores');
            text += newLine + 'Errors' + newLine + newLine;
            for (String message : this.resultObject.errors) {
                text += '- '  + message + newLine;
            }
            this.logger.addError(text);
        }    
    }

    private class Results {
        public Boolean success = true;
        public Integer recordsProcessed = 0;
        public Integer recordsCreated = 0;
        public Integer recordsUpdated = 0;
        public Integer recordsIgnored = 0;
        public Integer recordsError = 0;
        public List<String> errors = new List<String>();
    }

    public virtual class SAPDataReader {
        public virtual Set<String> readOrgData(Set<String> sapProducts) {
            Set<String> results = new Set<String>();
            for (ZSFMatOrgv__x mat : [select Material__c from ZSFMatOrgv__x WHERE Material__c in :sapProducts]) {
                results.add(mat.Material__c);
            }
            return results;
        }
    }

}