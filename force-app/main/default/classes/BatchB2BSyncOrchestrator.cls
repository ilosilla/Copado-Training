/**
 * BatchB2BSyncOrchestrator
 *
 * @author          Ramón Prades
 * @date            June 2026
 * @description
 *
 * Orchestrates the full B2B product media synchronization chain:
 *
 *   1. BatchPIMReader      — reads product attributes from SAP IS / PIM
 *   2. BatchPIMImageReader — reads product images from SAP IS / PIWIGO (incremental, last 30 days)
 *   3. CMS_ProductOrchestratorBatch — publishes images to Salesforce CMS and links them to products
 *
 * Each step is launched from the finish() of the previous one. Each step generates
 * its own log — this orchestrator does not log independently.
 *
 * Configuration is read from PORSAStoreSettings__c (first record with EnablePIMSync__c = true):
 *   - WorkspaceId__c  — CMS workspace for product media. If blank, the CMS step is skipped.
 *   - StoreId__c      — used to derive the catalog via WebStoreCatalog
 *
 * Restriction: a single CMS workspace for product media is assumed. Multi-workspace
 * support is out of scope.
 *
 * *Usage
 *
 *   BatchB2BSyncOrchestrator.executeBatch();
 *
 * To schedule:
 *
 *   System.schedule('B2B Sync', '0 0 2 * * ?', new BatchB2BSyncOrchestrator());
 *
 */
global class BatchB2BSyncOrchestrator implements Database.Batchable<SObject>, Schedulable {

    // ---------------------- STATIC RUNNERS ---------------------------

    global static void executeBatch() {
        Database.executeBatch(new BatchB2BSyncOrchestrator());
    }

    // ----------------------- SCHEDULABLE -----------------------------

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this);
    }

    // ----------------------- BATCH METHODS ---------------------------

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM User LIMIT 1');
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global void execute(Database.BatchableContext bc, List<User> scope) {
        // No pre-work needed — chain is launched from finish()
    }

    global void finish(Database.BatchableContext bc) {
        PORSAStoreSettings__c[] activeSettings = [
            SELECT Id, StoreId__c, WorkspaceId__c
            FROM PORSAStoreSettings__c
            WHERE EnablePIMSync__c = true
            LIMIT 1
        ];

        if (activeSettings.isEmpty()) {
            return;
        }

        PORSAStoreSettings__c setting = activeSettings[0];
        Boolean chainCMS = String.isNotBlank(setting.WorkspaceId__c);

        Id workspaceId;
        Id catalogId;

        if (chainCMS) {
            WebStoreCatalog[] catalogs = [
                SELECT ProductCatalogId
                FROM WebStoreCatalog
                WHERE SalesStoreId = :setting.StoreId__c
                LIMIT 1
            ];

            if (catalogs.isEmpty()) {
                chainCMS = false;
            } else {
                workspaceId = (Id) setting.WorkspaceId__c;
                catalogId   = catalogs[0].ProductCatalogId;
            }
        }

        BatchPIMReader reader = new BatchPIMReader();
        reader.setChainToImages(true);
        reader.setWorkspaceId(workspaceId);
        reader.setCatalogId(catalogId);
        Database.executeBatch(reader, 100);
    }
}