/**
 * @author         Ramón Prades
 * @date           March 2026
 * @group          CMS
 *
 * Class: CMS_ProductOrchestratorBatch
 *
 * Purpose:
 *   Launches the CMS product media orchestration for all products in a catalog.
 *
 * Notes:
 *   - Scope size must remain 1 to avoid mixed callout/DML processing across SKUs.
 *   - Product selection is centralized here through ProductCatalogProduct.
 */
global class CMS_ProductOrchestratorBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts, Schedulable {

    private static final Integer BATCH_SIZE = 1;
    private static final String LOG_SCENARIO = 'PIM';

    private Id workspaceId;
    private Id catalogId;
    private Integer maxProducts;
    private Boolean autoPublish = true;
    private String skuFilter;
    private Boolean extendedLog = false;
    private String mode = CMS_ProductOrchestrator.MODE_REPLACE_EXISTING;
    private SystemLog logger;

    private Integer totalProductsRead = 0;
    private Integer totalProductsFound = 0;
    private Integer totalListUploads = 0;
    private Integer totalDetailUploads = 0;
    private Integer totalAttachmentUploads = 0;
    private Integer totalListSkipped = 0;
    private Integer totalDetailSkipped = 0;
    private Integer totalAttachmentSkipped = 0;
    private Integer totalErrors = 0;

    @TestVisible private List<String> testSkus;

    /* ========================================================= */
    /* PUBLIC API                                                */
    /* ========================================================= */

    global static void executeBatch(Id workspaceId, Id catalogId) {
        Database.executeBatch(new CMS_ProductOrchestratorBatch(workspaceId, catalogId), BATCH_SIZE);
    }

    global static void executeBatch(Id workspaceId, Id catalogId, Integer maxProducts) {
        Database.executeBatch(new CMS_ProductOrchestratorBatch(workspaceId, catalogId, maxProducts), BATCH_SIZE);
    }

    global static void executeBatch(Id workspaceId, Id catalogId, Integer maxProducts, String skuFilter, Boolean extendedLog) {
        Database.executeBatch(
            new CMS_ProductOrchestratorBatch(
                workspaceId,
                catalogId,
                maxProducts,
                skuFilter,
                extendedLog,
                CMS_ProductOrchestrator.MODE_REPLACE_EXISTING
            ),
            BATCH_SIZE
        );
    }

    global static void executeBatch(Id workspaceId, Id catalogId, Integer maxProducts, String skuFilter, Boolean extendedLog, String mode) {
        Database.executeBatch(new CMS_ProductOrchestratorBatch(workspaceId, catalogId, maxProducts, skuFilter, extendedLog, mode), BATCH_SIZE);
    }

    global CMS_ProductOrchestratorBatch(Id workspaceId, Id catalogId) {
        this(workspaceId, catalogId, null);
    }

    global CMS_ProductOrchestratorBatch(Id workspaceId, Id catalogId, Integer maxProducts) {
        this(workspaceId, catalogId, maxProducts, null, false, CMS_ProductOrchestrator.MODE_REPLACE_EXISTING);
    }

    global CMS_ProductOrchestratorBatch(Id workspaceId, Id catalogId, Integer maxProducts, String skuFilter, Boolean extendedLog, String mode) {
        this.workspaceId = workspaceId;
        this.catalogId = catalogId;
        this.maxProducts = maxProducts;
        this.skuFilter = skuFilter;
        this.extendedLog = extendedLog;
        if (String.isNotBlank(mode)) {
            this.mode = mode.trim().toUpperCase();
        }
        this.logger = new SystemLog(LOG_SCENARIO);
        this.logger.setTag('CMS-MEDIA');
        this.logger.addInfo('Starting CMS product orchestrator batch');
        this.logger.addInfo('WorkspaceId = ' + workspaceId);
        this.logger.addInfo('CatalogId = ' + catalogId);
        this.logger.addInfo('MaxProducts = ' + maxProducts);
        this.logger.addInfo('SkuFilter = ' + skuFilter);
        this.logger.addInfo('ExtendedLog = ' + extendedLog);
        this.logger.addInfo('Mode = ' + this.mode);
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    global Iterable<String> start(Database.BatchableContext bc) {
        List<String> skus = this.getSkuList();
        this.logger.addInfo('Selected ' + skus.size() + ' products to process');
        return skus;
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        for (String sku : scope) {
            this.totalProductsRead++;

            try {
                CMS_ProductOrchestrator service = new CMS_ProductOrchestrator(sku, this.workspaceId);
                service.setAutoPublish(this.autoPublish);
                service.setExtendedLog(this.extendedLog);
                service.setMode(this.mode);
                CMS_ProductOrchestrator.ResultDTO result = service.execute();

                this.logger.addDebug(this.formatResultLog(result));
                if (this.extendedLog) {
                    for (String line : result.debugLines) {
                        this.logger.addDebug(' - ' + line);
                    }
                }

                if (result.productFound) {
                    this.totalProductsFound++;
                }

                this.totalListUploads += result.listUploads;
                this.totalDetailUploads += result.detailUploads;
                this.totalAttachmentUploads += result.attachmentUploads;

                if (result.listImageSkipped) {
                    this.totalListSkipped++;
                }
                if (result.detailImagesSkipped) {
                    this.totalDetailSkipped++;
                }
                if (result.attachmentsSkipped) {
                    this.totalAttachmentSkipped++;
                }

                if (!result.errors.isEmpty()) {
                    this.totalErrors += result.errors.size();
                    for (String error : result.errors) {
                        this.logger.addError(error);
                    }
                }
            } catch (Exception ex) {
                this.totalErrors++;
                this.logger.addError(ex);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        this.logger.addSection('Summary');
        this.logger.addInfo('Products read: ' + this.totalProductsRead);
        this.logger.addInfo('Products found: ' + this.totalProductsFound);
        this.logger.addInfo('List queued: ' + this.totalListUploads);
        this.logger.addInfo('Detail queued: ' + this.totalDetailUploads);
        this.logger.addInfo('Attachment queued: ' + this.totalAttachmentUploads);
        this.logger.addInfo('List skipped: ' + this.totalListSkipped);
        this.logger.addInfo('Detail skipped: ' + this.totalDetailSkipped);
        this.logger.addInfo('Attachment skipped: ' + this.totalAttachmentSkipped);
        this.logger.addInfo('Errors: ' + this.totalErrors);

        String summary = 'CMS media sync. Products: ' + this.totalProductsRead + ', errors: ' + this.totalErrors;
        if (this.logger.hasErrors()) {
            summary = 'ERRORS: ' + summary;
        }
        this.logger.setSummary(summary);
        this.logger.saveLog(true);
    }

    public void setAutoPublish(Boolean value) {
        this.autoPublish = value;
    }

    @TestVisible
    public void setTestSkus(List<String> skus) {
        this.testSkus = skus;
    }

    /* ========================================================= */
    /* PRIVATE HELPERS                                           */
    /* ========================================================= */

    private List<String> getSkuList() {
        List<String> skus;
        if (Test.isRunningTest() && this.testSkus != null) {
            skus = new List<String>(this.testSkus);
        } else if (String.isNotBlank(this.skuFilter)) {
            skus = this.parseSkuFilter();
        } else {
            Set<String> uniqueSkus = new Set<String>();
            for (ProductCategoryProduct link : [
                SELECT Product.StockKeepingUnit
                FROM ProductCategoryProduct
                WHERE CatalogId = :this.catalogId
                  AND Product.StockKeepingUnit != null
            ]) {
                uniqueSkus.add(link.Product.StockKeepingUnit);
            }
            skus = new List<String>(uniqueSkus);
        }

        skus.sort();

        if (this.maxProducts != null && this.maxProducts > 0 && skus.size() > this.maxProducts) {
            List<String> limitedSkus = new List<String>();
            for (Integer i = 0; i < this.maxProducts; i++) {
                limitedSkus.add(skus[i]);
            }
            skus = limitedSkus;
        }

        return skus;
    }

    private List<String> parseSkuFilter() {
        String normalized = this.skuFilter.replace(';', ',').replace('\n', ',').replace('\r', ',');
        Set<String> uniqueSkus = new Set<String>();

        for (String sku : normalized.split(',')) {
            String trimmedSku = sku == null ? null : sku.trim();
            if (String.isNotBlank(trimmedSku)) {
                uniqueSkus.add(trimmedSku);
            }
        }

        return new List<String>(uniqueSkus);
    }

    private String formatResultLog(CMS_ProductOrchestrator.ResultDTO result) {
        if (!result.productFound) {
            return 'SKU ' + result.sku + ' - PLP: NO - PDP: 0 - OTHER: 0 - Product not found';
        }

        if (result.listImageSkipped && result.detailImagesSkipped && result.attachmentsSkipped) {
            return 'SKU ' + result.sku + ' - Skipped';
        }

        String plpValue = 'NO';
        if (!result.listImageSkipped && String.isNotBlank(result.selectedListUrl)) {
            plpValue = 'YES';
            if (result.selectedListUrl.toUpperCase().contains('.AMB.')) {
                plpValue += ' (AMB)';
            }
        }

        Integer pdpCount = result.detailImagesSkipped ? 0 : result.selectedDetailUrls.size();
        Integer otherCount = result.attachmentsSkipped ? 0 : result.selectedAttachmentUrls.size();

        return 'SKU ' + result.sku
            + ' - PLP: ' + plpValue
            + ' - PDP: ' + pdpCount
            + ' - OTHER: ' + otherCount;
    }
}