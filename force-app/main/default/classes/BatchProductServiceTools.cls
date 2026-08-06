/**
* @author       Codex
* @date         March 2026
* @group        Products
* @description  Product batch tools runner. Supports utility operations over Product2
*               and related product objects without creating one batch class per task.
*
* @execution    Database.executeBatch(BatchProductServiceTools.forWeightCopy(), 200);
*               Database.executeBatch(BatchProductServiceTools.forWeightCopy(10), 200);
*               Database.executeBatch(BatchProductServiceTools.forTranslations('US', 'en_US'), 200);
*               Database.executeBatch(BatchProductServiceTools.forTranslations('US', 'en_US', 10), 200);
*/
global class BatchProductServiceTools implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    global enum Operation {
        COPY_WEIGHT,
        SYNC_TRANSLATIONS
    }

    global static final Integer DEFAULT_BATCH_SIZE = 200;

    private Operation operation;
    private String sourceCountry;
    private String targetLanguage;
    private Integer maxItems = 0;
    private Integer requestedMaxItems = 0;
    private Boolean hasMaxItemsLimit = false;
    private List<String> notificationEmails = new List<String>();

    @TestVisible private Integer processedRecords = 0;
    @TestVisible private Integer insertedRecords = 0;
    @TestVisible private Integer updatedRecords = 0;
    @TestVisible private Integer failedRecords = 0;
    @TestVisible private Integer ignoredRecords = 0;
    @TestVisible private List<String> errorMessages = new List<String>();
    @TestVisible private List<String> affectedProductsSample = new List<String>();
    @TestVisible private String executionSummary = '';
    @TestVisible private String lastEmailSubject = '';
    @TestVisible private String lastEmailBody = '';
    @TestVisible private Id forcedFailedRecordIdForTest;
    @TestVisible private Set<Id> restrictedProductIdsForTest;
    @TestVisible private List<ZSFMatPais__x> translationRowsForTest;

    private BatchProductServiceTools(Operation operationValue) {
        this.operation = operationValue;
        this.initializeNotificationEmails();
    }

    private BatchProductServiceTools(Operation operationValue, String sourceCountryValue, String targetLanguageValue) {
        this.operation = operationValue;
        this.sourceCountry = normalizeValue(sourceCountryValue);
        this.targetLanguage = normalizeValue(targetLanguageValue);
        this.initializeNotificationEmails();

        if (String.isBlank(this.sourceCountry)) {
            throw new IllegalArgumentException('sourceCountry is required for translation sync');
        }
        if (String.isBlank(this.targetLanguage)) {
            throw new IllegalArgumentException('targetLanguage is required for translation sync');
        }
    }

    global static BatchProductServiceTools forWeightCopy() {
        return new BatchProductServiceTools(Operation.COPY_WEIGHT);
    }

    global static BatchProductServiceTools forWeightCopy(Integer maxItems) {
        BatchProductServiceTools job = new BatchProductServiceTools(Operation.COPY_WEIGHT);
        job.setMaxItems(maxItems);
        return job;
    }

    global static BatchProductServiceTools forTranslations(String sourceCountry, String targetLanguage) {
        return new BatchProductServiceTools(Operation.SYNC_TRANSLATIONS, sourceCountry, targetLanguage);
    }

    global static BatchProductServiceTools forTranslations(String sourceCountry, String targetLanguage, Integer maxItems) {
        BatchProductServiceTools job = new BatchProductServiceTools(Operation.SYNC_TRANSLATIONS, sourceCountry, targetLanguage);
        job.setMaxItems(maxItems);
        return job;
    }

    global void setNotificationEmails(List<String> emails) {
        this.notificationEmails = new List<String>();
        if (emails == null) {
            return;
        }
        for (String email : emails) {
            String normalizedEmail = normalizeValue(email);
            if (String.isNotBlank(normalizedEmail)) {
                this.notificationEmails.add(normalizedEmail);
            }
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        switch on this.operation {
            when COPY_WEIGHT {
                return this.startWeightCopy();
            }
            when SYNC_TRANSLATIONS {
                return this.startTranslations();
            }
        }
        throw new IllegalArgumentException('Unsupported operation: ' + String.valueOf(this.operation));
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            switch on this.operation {
                when COPY_WEIGHT {
                    this.executeWeightCopy(scope);
                }
                when SYNC_TRANSLATIONS {
                    this.executeTranslations(scope);
                }
            }
        } catch (Exception ex) {
            this.failedRecords++;
            this.errorMessages.add(
                'Unhandled exception in operation ' + String.valueOf(this.operation) +
                ' | Type=' + ex.getTypeName() +
                ' | Message=' + ex.getMessage()
            );
            this.errorMessages.add(ex.getStackTraceString());
        }
    }

    global void finish(Database.BatchableContext bc) {
        this.executionSummary =
            'Operation=' + String.valueOf(this.operation) +
            ' | Processed=' + this.processedRecords +
            ' | Inserted=' + this.insertedRecords +
            ' | Updated=' + this.updatedRecords +
            ' | Failed=' + this.failedRecords +
            ' | Ignored=' + this.ignoredRecords;

        String body = this.executionSummary;
        if (!this.errorMessages.isEmpty()) {
            body += '\n' + String.join(this.errorMessages, '\n');
        }

        System.debug(
            LoggingLevel.INFO,
            '===================================================\n' +
            'RESULTADO DE EJECUCION\n' +
            body + '\n' +
            '==================================================='
        );

        this.sendExecutionSummaryEmail();
    }

    public void setRestrictedProductIdsForTest(Set<Id> ids) {
        this.restrictedProductIdsForTest = ids;
    }

    public void setForcedFailedRecordIdForTest(Id recordId) {
        this.forcedFailedRecordIdForTest = recordId;
    }

    @TestVisible
    public void setTranslationRowsForTest(List<ZSFMatPais__x> rows) {
        this.translationRowsForTest = rows;
    }

    @TestVisible
    private void setMaxItems(Integer value) {
        if (value == null || value <= 0) {
            this.maxItems = 0;
            this.requestedMaxItems = 0;
            this.hasMaxItemsLimit = false;
            return;
        }

        this.maxItems = value;
        this.requestedMaxItems = value;
        this.hasMaxItemsLimit = true;
    }

    private Database.QueryLocator startWeightCopy() {
        if (Test.isRunningTest() && this.restrictedProductIdsForTest != null && !this.restrictedProductIdsForTest.isEmpty()) {
            Set<Id> restrictedIds = this.restrictedProductIdsForTest;
            if (this.maxItems > 0) {
                Integer queryLimit = this.maxItems;
                return Database.getQueryLocator([
                    SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
                    FROM Product2
                    WHERE Id IN :restrictedIds
                    ORDER BY Id
                    LIMIT :queryLimit
                ]);
            }
            return Database.getQueryLocator([
                SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
                FROM Product2
                WHERE Id IN :restrictedIds
                ORDER BY Id
            ]);
        }

        if (this.maxItems > 0) {
            Integer queryLimit = this.maxItems;
            return Database.getQueryLocator([
                SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
                FROM Product2
                WHERE PesoUMV__c != NULL
                   OR UMV__c != NULL
                   OR ShippingWeight != NULL
                   OR ShippingWeightUnitOfMeasure != NULL
                ORDER BY Id
                LIMIT :queryLimit
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
            FROM Product2
            WHERE PesoUMV__c != NULL
               OR UMV__c != NULL
               OR ShippingWeight != NULL
               OR ShippingWeightUnitOfMeasure != NULL
            ORDER BY Id
        ]);
    }

    private Database.QueryLocator startTranslations() {
        if (this.maxItems > 0) {
            Integer queryLimit = this.maxItems;
            return Database.getQueryLocator([
                SELECT Id, ProductCode, StockKeepingUnit
                FROM Product2
                WHERE StockKeepingUnit != NULL
                ORDER BY Id
                LIMIT :queryLimit
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id, ProductCode, StockKeepingUnit
            FROM Product2
            WHERE StockKeepingUnit != NULL
            ORDER BY Id
        ]);
    }

    private void executeWeightCopy(List<SObject> scope) {
        List<Product2> productsToUpdate = new List<Product2>();
        Map<Id, String> productCodesById = new Map<Id, String>();

        for (Product2 product : (List<Product2>) scope) {
            this.processedRecords++;

            Boolean weightChanged = product.PesoUMV__c != product.ShippingWeight;
            Boolean unitChanged = product.UMV__c != product.ShippingWeightUnitOfMeasure;

            if (!weightChanged && !unitChanged) {
                continue;
            }

            productsToUpdate.add(new Product2(
                Id = product.Id,
                ShippingWeight = product.PesoUMV__c,
                ShippingWeightUnitOfMeasure = product.UMV__c
            ));
            productCodesById.put(product.Id, this.safeReadString(product, 'ProductCode'));
        }

        if (Test.isRunningTest() && this.forcedFailedRecordIdForTest != null) {
            productsToUpdate.add(new Product2(
                Id = this.forcedFailedRecordIdForTest,
                ShippingWeight = 1
            ));
            this.forcedFailedRecordIdForTest = null;
        }

        if (productsToUpdate.isEmpty()) {
            return;
        }

        Database.SaveResult[] results = Database.update(productsToUpdate, false);
        this.parseWeightResults(results, productsToUpdate, productCodesById);
    }

    private void executeTranslations(List<SObject> scope) {
        List<Product2> productsScope = (List<Product2>) scope;
        if (productsScope.isEmpty()) {
            return;
        }

        Set<String> scopeSkus = new Set<String>();
        Map<String, Product2> productsBySku = new Map<String, Product2>();
        for (Product2 product : productsScope) {
            this.processedRecords++;
            String sku = normalizeValue(product.StockKeepingUnit);
            if (String.isBlank(sku)) {
                this.ignoredRecords++;
                continue;
            }
            scopeSkus.add(sku);
            productsBySku.put(sku, product);
        }

        if (scopeSkus.isEmpty()) {
            return;
        }

        List<ZSFMatPais__x> translationRows;
        if (Test.isRunningTest() && this.translationRowsForTest != null) {
            translationRows = new List<ZSFMatPais__x>();
            for (ZSFMatPais__x row : this.translationRowsForTest) {
                if (row != null &&
                    normalizeValue(row.Pais__c) == this.sourceCountry &&
                    scopeSkus.contains(normalizeValue(row.Material__c))) {
                    translationRows.add(row);
                }
            }
        } else {
            translationRows = [
                SELECT ExternalId, Material__c, Pais__c, Denominacion__c
                FROM ZSFMatPais__x
                WHERE Pais__c = :this.sourceCountry
                  AND Material__c IN :scopeSkus
            ];
        }

        Map<String, ZSFMatPais__x> rowByMaterial = new Map<String, ZSFMatPais__x>();
        Integer duplicateRows = 0;

        for (ZSFMatPais__x translationRow : translationRows) {
            String material = normalizeValue(translationRow.Material__c);
            String country = normalizeValue(translationRow.Pais__c);
            String translatedName = normalizeValue(translationRow.Denominacion__c);

            if (country != this.sourceCountry) {
                this.ignoredRecords++;
                continue;
            }
            if (String.isBlank(material) || String.isBlank(translatedName)) {
                this.ignoredRecords++;
                this.errorMessages.add(
                    'ZSFMATPAIS ignored | Material=' + String.valueOf(material) +
                    ' | Country=' + String.valueOf(country) +
                    ' | Reason=Missing Material__c or Denominacion__c'
                );
                continue;
            }

            if (rowByMaterial.containsKey(material)) {
                duplicateRows++;
            }
            rowByMaterial.put(material, translationRow);
        }

        if (duplicateRows > 0) {
            this.errorMessages.add(
                'Duplicate ZSFMatPais__x rows detected for country ' + this.sourceCountry +
                '. Last row per Material__c was used. Count=' + duplicateRows
            );
        }

        if (rowByMaterial.isEmpty()) {
            this.ignoredRecords += productsBySku.size();
            return;
        }

        Set<Id> productIds = new Set<Id>();
        for (String material : rowByMaterial.keySet()) {
            Product2 product = productsBySku.get(material);
            if (product != null) {
                productIds.add(product.Id);
            }
        }

        Map<Id, Product2DataTranslation> existingTranslationsByParent = new Map<Id, Product2DataTranslation>();
        if (!productIds.isEmpty()) {
            for (Product2DataTranslation translation : [
                SELECT Id, ParentId, Language, Name
                FROM Product2DataTranslation
                WHERE ParentId IN :productIds
                  AND Language = :this.targetLanguage
            ]) {
                existingTranslationsByParent.put(translation.ParentId, translation);
            }
        }

        List<Product2DataTranslation> translationsToInsert = new List<Product2DataTranslation>();
        List<Product2DataTranslation> translationsToUpdate = new List<Product2DataTranslation>();
        Map<Id, String> skuByParentId = new Map<Id, String>();
        Map<Id, Id> translationParentByTranslationId = new Map<Id, Id>();

        for (String material : rowByMaterial.keySet()) {
            ZSFMatPais__x row = rowByMaterial.get(material);
            Product2 product = productsBySku.get(material);

            if (product == null) {
                continue;
            }

            skuByParentId.put(product.Id, product.StockKeepingUnit);
            String translatedName = normalizeValue(row.Denominacion__c);
            Product2DataTranslation existingTranslation = existingTranslationsByParent.get(product.Id);

            if (existingTranslation == null) {
                translationsToInsert.add(new Product2DataTranslation(
                    ParentId = product.Id,
                    Language = this.targetLanguage,
                    Name = translatedName
                ));
            } else if (existingTranslation.Name != translatedName) {
                translationParentByTranslationId.put(existingTranslation.Id, product.Id);
                translationsToUpdate.add(new Product2DataTranslation(
                    Id = existingTranslation.Id,
                    Name = translatedName
                ));
            } else {
                this.ignoredRecords++;
            }
        }

        Integer productsWithoutTranslation = productsBySku.size() - rowByMaterial.size();
        if (productsWithoutTranslation > 0) {
            this.ignoredRecords += productsWithoutTranslation;
        }

        if (Test.isRunningTest() && this.forcedFailedRecordIdForTest != null) {
            translationsToInsert.add(new Product2DataTranslation(
                ParentId = this.forcedFailedRecordIdForTest,
                Language = this.targetLanguage,
                Name = 'FORCED FAILURE'
            ));
            this.forcedFailedRecordIdForTest = null;
        }

        if (!translationsToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(translationsToInsert, false);
            this.parseTranslationInsertResults(insertResults, translationsToInsert, skuByParentId);
        }

        if (!translationsToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(translationsToUpdate, false);
            this.parseTranslationUpdateResults(updateResults, translationsToUpdate, translationParentByTranslationId, skuByParentId);
        }
    }

    private void parseWeightResults(
        Database.SaveResult[] results,
        List<Product2> productsToUpdate,
        Map<Id, String> productCodesById
    ) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                this.updatedRecords++;
                this.addAffectedSample(
                    'UPDATE_WEIGHT | Product2Id=' + productsToUpdate[i].Id +
                    ' | ProductCode=' + String.valueOf(productCodesById.get(productsToUpdate[i].Id))
                );
                continue;
            }

            this.failedRecords++;
            for (Database.Error err : results[i].getErrors()) {
                this.errorMessages.add(
                    'Product2 Id=' + productsToUpdate[i].Id +
                    ' | ProductCode=' + String.valueOf(productCodesById.get(productsToUpdate[i].Id)) +
                    ' | StatusCode=' + String.valueOf(err.getStatusCode()) +
                    ' | Message=' + err.getMessage()
                );
            }
        }
    }

    private void parseTranslationInsertResults(
        Database.SaveResult[] results,
        List<Product2DataTranslation> translations,
        Map<Id, String> skuByParentId
    ) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                this.insertedRecords++;
                this.addAffectedSample(
                    'INSERT_TRANSLATION | ParentId=' + translations[i].ParentId +
                    ' | SKU=' + String.valueOf(skuByParentId.get(translations[i].ParentId)) +
                    ' | Language=' + this.targetLanguage +
                    ' | Name=' + translations[i].Name
                );
                continue;
            }

            this.failedRecords++;
            for (Database.Error err : results[i].getErrors()) {
                this.errorMessages.add(
                    'Product2DataTranslation INSERT' +
                    ' | ParentId=' + String.valueOf(translations[i].ParentId) +
                    ' | SKU=' + String.valueOf(skuByParentId.get(translations[i].ParentId)) +
                    ' | Language=' + this.targetLanguage +
                    ' | StatusCode=' + String.valueOf(err.getStatusCode()) +
                    ' | Message=' + err.getMessage()
                );
            }
        }
    }

    private void parseTranslationUpdateResults(
        Database.SaveResult[] results,
        List<Product2DataTranslation> translations,
        Map<Id, Id> translationParentByTranslationId,
        Map<Id, String> skuByParentId
    ) {
        for (Integer i = 0; i < results.size(); i++) {
            Id parentId = translationParentByTranslationId.get(translations[i].Id);
            if (results[i].isSuccess()) {
                this.updatedRecords++;
                this.addAffectedSample(
                    'UPDATE_TRANSLATION | ParentId=' + String.valueOf(parentId) +
                    ' | SKU=' + String.valueOf(skuByParentId.get(parentId)) +
                    ' | Language=' + this.targetLanguage +
                    ' | Name=' + translations[i].Name
                );
                continue;
            }

            this.failedRecords++;
            for (Database.Error err : results[i].getErrors()) {
                this.errorMessages.add(
                    'Product2DataTranslation UPDATE' +
                    ' | ParentId=' + String.valueOf(parentId) +
                    ' | SKU=' + String.valueOf(skuByParentId.get(parentId)) +
                    ' | Language=' + this.targetLanguage +
                    ' | StatusCode=' + String.valueOf(err.getStatusCode()) +
                    ' | Message=' + err.getMessage()
                );
            }
        }
    }

    private void initializeNotificationEmails() {
        String currentUserEmail = normalizeValue(UserInfo.getUserEmail());
        if (String.isNotBlank(currentUserEmail)) {
            this.notificationEmails.add(currentUserEmail);
        }
    }

    private void addAffectedSample(String value) {
        if (this.affectedProductsSample.size() < 10) {
            this.affectedProductsSample.add(value);
        }
    }

    private void sendExecutionSummaryEmail() {
        this.lastEmailSubject =
            'BatchProductServiceTools ' + String.valueOf(this.operation) +
            ' | Processed=' + this.processedRecords +
            ' | Inserted=' + this.insertedRecords +
            ' | Updated=' + this.updatedRecords +
            ' | Failed=' + this.failedRecords;
        this.lastEmailBody = this.buildEmailBody();

        if (this.notificationEmails.isEmpty() || Test.isRunningTest()) {
            return;
        }

        Mail mail = new Mail();
        mail.setGeneric();
        mail.setTo(this.notificationEmails);
        mail.setSubject(this.lastEmailSubject);
        mail.setHtml(this.lastEmailBody);
        mail.send();
    }

    private String buildEmailBody() {
        String html =
            '<html><body>' +
            '<h3>BatchProductServiceTools</h3>' +
            '<p>Operation: ' + String.valueOf(this.operation) + '</p>' +
            '<p>Processed rows: ' + this.processedRecords + '</p>' +
            '<p>Inserted: ' + this.insertedRecords + '</p>' +
            '<p>Updated: ' + this.updatedRecords + '</p>' +
            '<p>Failed: ' + this.failedRecords + '</p>' +
            '<p>Ignored: ' + this.ignoredRecords + '</p>';

        if (this.hasMaxItemsLimit) {
            html += '<p>Execution limit: ' + this.requestedMaxItems + '</p>';
        }

        html += '<h4>First affected products</h4><ul>';
        if (this.affectedProductsSample.isEmpty()) {
            html += '<li>No successful inserts/updates in this execution.</li>';
        } else {
            for (String item : this.affectedProductsSample) {
                html += '<li>' + item.escapeHtml4() + '</li>';
            }
        }
        html += '</ul>';

        if (!this.errorMessages.isEmpty()) {
            html += '<h4>First errors</h4><ul>';
            Integer maxErrors = Math.min(this.errorMessages.size(), 10);
            for (Integer i = 0; i < maxErrors; i++) {
                html += '<li>' + this.errorMessages[i].escapeHtml4() + '</li>';
            }
            html += '</ul>';
        }

        html += '</body></html>';
        return html;
    }

    private static String normalizeValue(String value) {
        return value == null ? null : value.trim();
    }

    private String safeReadString(SObject record, String fieldName) {
        try {
            return (String) record.get(fieldName);
        } catch (SObjectException ex) {
            return null;
        }
    }
}