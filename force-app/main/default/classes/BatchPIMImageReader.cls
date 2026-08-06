@SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
/**
 * BatchPIMImageReader
 *
 * @author          Ramón Prades
 * @date            October 2025
 * @description
 *
 * Batch job that synchronizes product media (images and documents) from the
 * Porcelanosa image manager (PIWIGO) into Salesforce via SAP CPI.
 *
 * The process works as follows:
 * - Determines the set of products whose media must be fetched (see *Modes of Operation*).
 * - Splits the list into fixed-size chunks of CHUNK_SIZE (10 products per request).
 * - Builds a JSON request body with the SKUs of the current chunk.
 * - Calls the SAP CPI proxy (PIWIGO endpoint) and retrieves media metadata/URLs.
 * - Normalizes and persists results into PIMProductImages__c.
 * - Logs execution details, successes, and errors using SystemLog.
 *
 * *Modes of Operation
 * - FullMode:
 *   - Purges all existing records in PIMProductImages__c (table-wide cleanup).
 *   - Reads all products from PIMProduct__c and fetches their media.
 * - Normal mode:
 *   - Selects products created in the last N days in PIMProduct__c.
 *   - Fetches media only for that recent subset.
 *
 * *Responsibilities
 * - Identify the scope of products (all or “last N days”) from PIMProduct__c.
 * - Chunk products in groups of CHUNK_SIZE = 10 (PIWIGO/CPI constraint).
 * - Build the CPI payload for the current chunk and perform the callout.
 * - Map/normalize PIWIGO response (images/documents, variants, ordering, MIME, etc.).
 * - Upsert records into PIMProductImages__c (ensuring de-duplication per product/asset).
 * - Maintain detailed logs and metrics via SystemLog throughout the batch.
 *
 * *Key Characteristics
 * - Implements Database.Batchable to support large-scale processing.
 * - Implements Database.Stateful to maintain counters and log context across batches.
 * - Implements Database.AllowsCallouts to perform external HTTP requests to SAP CPI.
 * - Implements Schedulable to allow scheduled runs (e.g., nightly syncs).
 * - Fixed CHUNK_SIZE = 10 products per request to respect CPI/PIWIGO limits.
 *
 * *Usage
 * Examples (signatures shown for illustration purposes):
 *
 * Batch size is aligned with CHUNK_SIZE to respect endpoint constraints.
 *
 * *Configuration
 * - Input scope:
 *   - FullMode flag (boolean) to trigger full reload behavior.
 *   - daysBack (integer) to define the “last N days” window in normal mode.
 * - External integration:
 *   - SAP CPI proxy endpoint for PIWIGO (HTTP callout).
 * - Persistence:
 *   - Source products: PIMProduct__c
 *   - Target media table: PIMProductImages__c
 * - Observability:
 *   - Centralized logging via SystemLog (levels, counters, errors).
 *
 */
global class BatchPIMImageReader implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable { 

    public static final Integer CHUNK_SIZE = 10;
    private static final Integer DAYS_BACK = 30;    

    private SystemLog logger;
    private Integer totalInserts = 0;
    private Integer totalDeletes = 0;
    private Integer totalProductsRead = 0;
    private Integer totalProductsWithImages = 0;
    private Boolean fullMode = false;

    private Boolean chainToCMS = false;
    private Id workspaceId;
    private Id catalogId;

    public void setChainToCMS(Boolean value) { this.chainToCMS = value; }
    public void setWorkspaceId(Id value) { this.workspaceId = value; }
    public void setCatalogId(Id value) { this.catalogId = value; }
    //Map<String, PIMProduct__c> selectedProductsMap;
    //PIMProductImage__c[] existingImages;
    
    /**
     * Launches the batch process
     */
    global static void executeBatch() {
        Database.executeBatch(new BatchPIMImageReader(false), CHUNK_SIZE);
    }

    global static void executeBatch(Boolean fullMode) {
        Database.executeBatch(new BatchPIMImageReader(fullMode), CHUNK_SIZE);
    }

    // Constructor vacío
    global BatchPIMImageReader() {
        this(false);
    }

    global BatchPIMImageReader(Boolean fullMode) {
        this.logger = new SystemLog('PIM');
        this.logger.setTag('IMAGES');
        this.totalInserts = 0;
        this.totalDeletes = 0;
        this.totalProductsRead = 0;
        this.totalProductsWithImages = 0;
        this.fullMode = fullMode;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String soql = 'select Id, Product__c, StockKeepingUnit__c, CreatedDate from PIMProduct__c';
        if (!this.fullMode) {
            soql += ' where CreatedDate = LAST_N_DAYS:' + DAYS_BACK;
        }
        this.logger.addInfo('Batch start. Full mode = ' + this.fullMode + '. Query = ' + soql);
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext bc, List<PIMProduct__c> scope) {
        this.logger.addInfo('Procesando un lote de ' + scope.size() + ' productos');

        //this.selectedProductsMap = new Map<String, PIMProduct__c>();
        Set<String> productSkus = new Set<String>();
        Set<String> allProductSkusInScope = new Set<String>();
        List<String> dawData = new List<String>();

        Integer lastIndex = scope.size() - 1;
        for (Integer i = 0; i < scope.size(); i++) {
            String sku = scope[i].StockKeepingUnit__c;
            if (String.isBlank(sku)) {
                this.logger.addWarning('Skipping PIMProduct without SKU. Record Id: ' + scope[i].Id);
                continue;
            }

            //this.selectedProductsMap.put(sku, scope[i]);
            productSkus.add(sku);
            allProductSkusInScope.add(sku);
            this.totalProductsRead++;

            if (productSkus.size() == CHUNK_SIZE || i == lastIndex) {
                try {
                    String response = this.getPIMImageData(productSkus);
                    if (String.isNotBlank(response)) {
                        dawData.add(response);
                    }
                } catch (Exception ex) {
                    this.logger.addError(ex);
                }
                productSkus.clear();
            }
        }

        this.logger.addInfo('Se ha finalizado la lectura de datos desde el DAW');
        this.deleteExistingImages(allProductSkusInScope);

        try {
            for (String data : dawData) {
                if (String.isBlank(data)) {
                    continue;
                }
                this.processDAWData(data);
            }
        } catch (Exception ex) {
            this.logger.addError(ex);
        }
    }

    // Método finish: acciones al finalizar el batch
    global void finish(Database.BatchableContext bc) {
        
        Boolean hasWarnings = false;

        this.logger.addSection('Resumen');
        this.logger.addInfo('BatchPIMImageReader finalizado.');
        this.logger.addInfo('==> TOTAL PRODUCTS READ: ' + this.totalProductsRead);
        this.logger.addInfo('==> TOTAL PRODUCTS WITH IMAGES: ' + this.totalProductsWithImages);
        this.logger.addInfo('==> TOTAL DELETES: ' + this.totalDeletes);
        this.logger.addInfo('==> TOTAL INSERTS: ' + this.totalInserts);
        String summary = 'Leyendo imágenes PIM. Productos: ' + this.totalProductsRead + ', con imágenes: ' + this.totalProductsWithImages + ', inserts: ' + this.totalInserts + ', deletes: ' + this.totalDeletes;
        if(this.logger.hasErrors()) {
            summary = 'ERRORS: ' + summary;
        } else if (hasWarnings)   {
            summary = 'WARNINGS: ' + summary;
        }      
        this.logger.setSummary(summary);
        this.logger.saveLog(true);

        if (this.chainToCMS && this.workspaceId != null && this.catalogId != null) {
            CMS_ProductOrchestratorBatch.executeBatch(this.workspaceId, this.catalogId);
        }
    }

    // Método execute para Schedulable: ejecuta el batch
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPIMImageReader(false), CHUNK_SIZE);
    }

    /* ==================================================================================== */
    
    /*
     * Gets data from the PIM
     */
    private String getPIMImageData(Set<String> productCodes) {
        String response = '';
        if (productCodes.size() > 0) {
            SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.PIM_IMAGES_ENDPOINT);
            proxy.setQueryString('ids=' + String.join(productCodes, ','));
            proxy.setMethod('GET');
            try {
                response = proxy.callCPI();
                if (proxy.isSuccess()) {
                    this.logger.addInfo('Se han leído con éxito ' + productCodes.size() + ' productos del DAW' );
                } else {                    
                    this.logger.addError('Se ha recibido un error al leer del PIM. El status es ' + proxy.getResponseCode() + '.');
                    this.logger.addError('Response is: ' + response);
                }
            } catch (HttpException hex) {
                this.logger.addError(hex);
            }        
        }
        return response;
    } 

    /*
     * Process the data received from the DAW
     */
    private void processDAWData(String dawData) {
        if (String.isBlank(dawData)) {
            this.logger.addWarning('Empty DAW payload received.');
            return;
        }

        PIMProductImage__c[] toInsert = new List<PIMProductImage__c>();
        Set<String> processedImageKeys = new Set<String>();
        List<Object> root = (List<Object>) JSON.deserializeUntyped(dawData);

        for (Object prodObj : root) {
            Map<String,Object> prod = (Map<String,Object>) prodObj;

            String sku = getString(prod, 'id');
            if (String.isBlank(sku)) {
                continue;
            }

            List<Object> imgs = (List<Object>) prod.get('images');
            if (imgs == null || imgs.isEmpty()) {
                continue;
            }

            this.totalProductsWithImages++;

            for (Object imgObj : imgs) {
                Map<String,Object> img = (Map<String,Object>) imgObj;
                String imageId = getStringAny(img, 'id');
                String imageKey = sku + '|' + imageId;

                if (processedImageKeys.contains(imageKey)) {
                    continue;
                }
                processedImageKeys.add(imageKey);

                PIMProductImage__c rec = new PIMProductImage__c();

                // === Mapea campos base ===
                rec.StockKeepingUnit__c = sku;
                rec.ImageId__c = imageId;
                rec.Name__c = getString(img, 'name');
                rec.ImageType__c = getString(img, 'imageType');
                rec.PageUrl__c = getString(img, 'page_url');
                rec.ElementUrl__c = getString(img, 'element_url');
                rec.DownloadUrl__c = getString(img, 'download_url');

                rec.Width__c = getInteger(img, 'width');
                rec.Height__c = getInteger(img, 'height');
                rec.IsFavorite__c = getBoolean(img, 'is_Favorite');

                // === URLs de tamaños ===
                rec.Square__c = getString(img, 'square');
                rec.Thumb__c = getString(img, 'thumb');
                rec.XXSmall__c = getString(img, '2small');
                rec.Xsmall__c = getString(img, 'xsmall');
                rec.Small__c = getString(img, 'small');
                rec.Medium__c = getString(img, 'medium');
                rec.Large__c = getString(img, 'large');
                rec.Xlarge__c = getString(img, 'xlarge');
                rec.Xxlarge__c = getString(img, 'xxlarge');

                toInsert.add(rec);
                if (toInsert.size() == 200) {
                    this.logger.addInfo('Inserting a block of ' + toInsert.size() + ' images');
                    insert toInsert;
                    this.totalInserts += toInsert.size();
                    toInsert.clear();
                }
            }
        }

        if (toInsert.size() > 0) {
            this.logger.addInfo('Inserting a block of ' + toInsert.size() + ' images');
            insert toInsert;
            this.totalInserts += toInsert.size();
            toInsert.clear();
        }
    }

    /**
     * Reads the existing image recoirds (per product)
     */
    private void deleteExistingImages(Set<String> productSkus) {
        if (productSkus == null || productSkus.isEmpty()) {
            this.logger.addInfo('No existing images to delete because the SKU set is empty.');
            return;
        }

        PIMProductImage__c[] images = [
            SELECT Id, StockKeepingUnit__c
            FROM PIMProductImage__c
            WHERE StockKeepingUnit__c IN :productSkus
        ];
        this.logger.addInfo('Se han identificado ' + images.size() + ' imágenes a borrar');

        PIMProductImage__c[] toDelete = new List<PIMProductImage__c>();
        Integer index = 0;
        for (PIMProductImage__c image : images) {
            index++;
            toDelete.add(image);
            if (toDelete.size() == 200 || index == images.size()) {
                delete toDelete;
                this.totalDeletes += toDelete.size();
                toDelete.clear();
            }
        }
    }

    private static String getString(Map<String,Object> m, String k) {
        Object v = m.get(k);
        return v == null ? null : String.valueOf(v);
    }

    // Igual que getString, pero permite numéricos y booleans sin lanzar
    private static String getStringAny(Map<String,Object> m, String k) {
        return getString(m, k);
    }

    private static Integer getInteger(Map<String,Object> m, String k) {
        Integer result;
        Object v = m.get(k);
        if (v == null) return null;
        if (v instanceof Integer) {
            result = (Integer)v;
        } else if (v instanceof Long) {
            result = Integer.valueOf(String.valueOf(v));
        } else if (v instanceof Decimal) {
            result = ((Decimal)v).intValue();
        } else if (v instanceof String) {
            result = Integer.valueOf((String)v);
        } else {
            result = null;
        }
        return result;
    }

    private static Boolean getBoolean(Map<String,Object> m, String k) {
        Object v = m.get(k);
        if (v == null) return null;
        if (v instanceof Boolean) return (Boolean)v;
        return 'true'.equalsIgnoreCase(String.valueOf(v));
    }
}