@isTest
public class BatchProductServiceToolsTest {

    @testSetup
    private static void setupData() {
        DataFactoryProduct.skipPriceBooks = true;
        DataFactoryProduct.createProducts(null);
        DataFactoryProduct.skipPriceBooks = false;
    }

    @isTest
    static void testWeightCopyKeepsProcessingWhenOneUpdateFails() {
        String validUnit = getValidShippingUnit();
        List<Product2> products = [
            SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
            FROM Product2
            ORDER BY ProductCode
            LIMIT 2
        ];

        products[0].PesoUMV__c = 20;
        products[0].UMV__c = validUnit;
        products[1].PesoUMV__c = 30;
        products[1].UMV__c = validUnit;
        update products;

        BatchProductServiceTools batch = BatchProductServiceTools.forWeightCopy();
        batch.setForcedFailedRecordIdForTest(Id.valueOf('01t000000000000AAA'));

        List<SObject> scope = new List<SObject>();
        scope.addAll(products);

        Test.startTest();
            batch.execute(null, scope);
            batch.finish(null);
        Test.stopTest();

        Map<Id, Product2> refreshedById = new Map<Id, Product2>([
            SELECT Id, ShippingWeight, ShippingWeightUnitOfMeasure
            FROM Product2
            WHERE Id IN :new Map<Id, Product2>(products).keySet()
        ]);

        System.assertEquals(20, refreshedById.get(products[0].Id).ShippingWeight, 'A valid record should still be updated');
        System.assertEquals(validUnit, refreshedById.get(products[0].Id).ShippingWeightUnitOfMeasure, 'A valid record should still copy the UOM');
        System.assertEquals(30, refreshedById.get(products[1].Id).ShippingWeight, 'The second valid record should still be updated');
        System.assertEquals(validUnit, refreshedById.get(products[1].Id).ShippingWeightUnitOfMeasure, 'The second valid record should still copy the UOM');

        System.assertEquals(1, batch.failedRecords, 'Only the forced invalid record should fail');
        System.assert(batch.errorMessages.size() > 0, 'The batch should keep the error detail');
        System.assert(batch.executionSummary.contains('Failed=1'), 'The summary should include the failed record count');
        System.assert(batch.lastEmailSubject.contains('COPY_WEIGHT'), 'The email subject should mention the operation');
        System.assert(batch.lastEmailBody.contains('First affected products'), 'The email body should include the affected-products section');
    }

    @isTest
    static void testTranslationSyncInsertsNames() {
        String targetLanguage = getValidTranslationLanguage();
        List<Product2> products = [
            SELECT Id, StockKeepingUnit
            FROM Product2
            ORDER BY ProductCode
            LIMIT 2
        ];

        List<SObject> scope = new List<SObject>();
        scope.addAll(products);

        BatchProductServiceTools batch = BatchProductServiceTools.forTranslations('US', targetLanguage);
        batch.setTranslationRowsForTest(new List<ZSFMatPais__x>{
            new ZSFMatPais__x(Material__c = products[0].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'Translated Product 1'),
            new ZSFMatPais__x(Material__c = products[1].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'Translated Product 2')
        });

        Test.startTest();
            batch.execute(null, scope);
            batch.finish(null);
        Test.stopTest();

        Map<Id, Product2DataTranslation> translationsByParentId = new Map<Id, Product2DataTranslation>();
        for (Product2DataTranslation translation : [
            SELECT Id, ParentId, Language, Name
            FROM Product2DataTranslation
            WHERE ParentId IN :new Map<Id, Product2>(products).keySet()
              AND Language = :targetLanguage
        ]) {
            translationsByParentId.put(translation.ParentId, translation);
        }

        System.assertEquals(2, translationsByParentId.size(), 'Two product translations should have been created');
        System.assertEquals('Translated Product 1', translationsByParentId.get(products[0].Id).Name, 'The first translated name should be inserted');
        System.assertEquals('Translated Product 2', translationsByParentId.get(products[1].Id).Name, 'The second translated name should be inserted');
        System.assertEquals(2, batch.insertedRecords, 'Two translations should have been inserted');
        System.assert(batch.lastEmailBody.contains('INSERT_TRANSLATION'), 'The email body should include inserted translations');
    }

    @isTest
    static void testTranslationSyncUpdatesAndKeepsProcessingWhenOneInsertFails() {
        String targetLanguage = getValidTranslationLanguage();
        List<Product2> products = [
            SELECT Id, StockKeepingUnit
            FROM Product2
            ORDER BY ProductCode
            LIMIT 2
        ];

        insert new Product2DataTranslation(
            ParentId = products[0].Id,
            Language = targetLanguage,
            Name = 'Old name'
        );

        List<SObject> scope = new List<SObject>();
        scope.addAll(products);

        BatchProductServiceTools batch = BatchProductServiceTools.forTranslations('US', targetLanguage);
        batch.setForcedFailedRecordIdForTest(Id.valueOf('01t000000000000AAA'));
        batch.setTranslationRowsForTest(new List<ZSFMatPais__x>{
            new ZSFMatPais__x(Material__c = products[0].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'Updated name'),
            new ZSFMatPais__x(Material__c = products[1].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'Inserted name')
        });

        Test.startTest();
            batch.execute(null, scope);
            batch.finish(null);
        Test.stopTest();

        Map<Id, Product2DataTranslation> translationsByParentId = new Map<Id, Product2DataTranslation>();
        for (Product2DataTranslation translation : [
            SELECT Id, ParentId, Language, Name
            FROM Product2DataTranslation
            WHERE ParentId IN :new Map<Id, Product2>(products).keySet()
              AND Language = :targetLanguage
        ]) {
            translationsByParentId.put(translation.ParentId, translation);
        }

        System.assertEquals('Updated name', translationsByParentId.get(products[0].Id).Name, 'The existing translation should be updated');
        System.assertEquals('Inserted name', translationsByParentId.get(products[1].Id).Name, 'A valid new translation should still be inserted');
        System.assertEquals(1, batch.updatedRecords, 'One translation should have been updated');
        System.assertEquals(1, batch.insertedRecords, 'One translation should have been inserted');
        System.assertEquals(1, batch.failedRecords, 'Only the forced invalid translation should fail');
        System.assert(batch.errorMessages.size() > 0, 'The translation error detail should be captured');
    }

    @isTest
    static void testTranslationSyncIgnoresMissingProductAndLogsDuplicates() {
        String targetLanguage = getValidTranslationLanguage();
        List<Product2> products = [
            SELECT Id, StockKeepingUnit
            FROM Product2
            ORDER BY Id
            LIMIT 2
        ];

        BatchProductServiceTools batch = BatchProductServiceTools.forTranslations('US', targetLanguage);
        batch.setNotificationEmails(new List<String>{'qa@example.com'});
        batch.setTranslationRowsForTest(new List<ZSFMatPais__x>{
            new ZSFMatPais__x(Material__c = products[0].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'First Name'),
            new ZSFMatPais__x(Material__c = products[0].StockKeepingUnit, Pais__c = 'US', Denominacion__c = 'Final Name')
        });

        List<SObject> scope = new List<SObject>();
        scope.addAll(products);

        Test.startTest();
            batch.execute(null, scope);
            batch.finish(null);
        Test.stopTest();

        Product2DataTranslation translation = [
            SELECT Id, ParentId, Language, Name
            FROM Product2DataTranslation
            WHERE ParentId = :products[0].Id
              AND Language = :targetLanguage
            LIMIT 1
        ];

        System.assertEquals('Final Name', translation.Name, 'The last duplicate row should win for the same material');
        System.assertEquals(1, batch.insertedRecords, 'Only one translation should be inserted');
        System.assertEquals(1, batch.ignoredRecords, 'The product without a matching external row should be ignored');
        System.assert(batch.errorMessages[0].contains('Duplicate ZSFMatPais__x rows detected'), 'Duplicate rows should be reported');
        System.assert(batch.lastEmailBody.contains('Final Name'), 'The email body should include the affected translation sample');
    }

    @isTest
    static void testWeightCopyHonorsMaxItemsInStart() {
        String validUnit = getValidShippingUnit();
        List<Product2> products = [
            SELECT Id, ProductCode, PesoUMV__c, UMV__c, ShippingWeight
            FROM Product2
            ORDER BY Id
            LIMIT 3
        ];

        for (Product2 product : products) {
            product.PesoUMV__c = 5;
            product.UMV__c = validUnit;
            product.ShippingWeight = null;
        }
        update products;

        BatchProductServiceTools batch = BatchProductServiceTools.forWeightCopy(1);
        batch.setRestrictedProductIdsForTest(new Map<Id, Product2>(products).keySet());

        Test.startTest();
            Id jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'The limited batch job should be created');

        List<Product2> refreshedProducts = [
            SELECT Id, ShippingWeight
            FROM Product2
            WHERE Id IN :new Map<Id, Product2>(products).keySet()
            ORDER BY Id
        ];

        Integer updatedCount = 0;
        for (Product2 product : refreshedProducts) {
            if (product.ShippingWeight == 5) {
                updatedCount++;
            }
        }

        System.assertEquals(1, updatedCount, 'Only one product should be updated when maxItems=1');
    }

    @isTest
    static void testTranslationFactoryValidatesRequiredParameters() {
        try {
            BatchProductServiceTools.forTranslations(null, 'en_US');
            System.assert(false, 'An exception should be thrown when sourceCountry is missing');
        } catch (IllegalArgumentException ex) {
            System.assert(ex.getMessage().contains('sourceCountry is required'), 'The error should mention sourceCountry');
        }

        try {
            BatchProductServiceTools.forTranslations('US', '   ');
            System.assert(false, 'An exception should be thrown when targetLanguage is missing');
        } catch (IllegalArgumentException ex) {
            System.assert(ex.getMessage().contains('targetLanguage is required'), 'The error should mention targetLanguage');
        }
    }

    @isTest
    static void testFactoryOverloadsAndStartMethods() {
        BatchProductServiceTools weightBatch = BatchProductServiceTools.forWeightCopy(2);
        weightBatch.setNotificationEmails(null);
        System.assertNotEquals(null, weightBatch.start(null), 'The weight-copy start should return a query locator');

        BatchProductServiceTools translationBatch = BatchProductServiceTools.forTranslations('US', getValidTranslationLanguage(), 1);
        translationBatch.setNotificationEmails(new List<String>{'  qa@example.com  ', null});
        System.assertNotEquals(null, translationBatch.start(null), 'The translation start should return a query locator');
    }

    static String getValidShippingUnit() {
        List<Schema.PicklistEntry> shippingUnits = Product2.ShippingWeightUnitOfMeasure.getDescribe().getPicklistValues();
        Schema.DescribeFieldResult umvDescribe = Product2.UMV__c.getDescribe();
        Schema.DisplayType umvType = umvDescribe.getType();
        Boolean umvIsPicklist = umvType == Schema.DisplayType.Picklist || umvType == Schema.DisplayType.MultiPicklist;
        Set<String> validUmvValues = new Set<String>();

        if (umvIsPicklist) {
            for (Schema.PicklistEntry umvValue : umvDescribe.getPicklistValues()) {
                if (umvValue.isActive()) {
                    validUmvValues.add(umvValue.getValue());
                }
            }
        }

        for (Schema.PicklistEntry shippingUnit : shippingUnits) {
            if (shippingUnit.isActive() && (!umvIsPicklist || validUmvValues.contains(shippingUnit.getValue()))) {
                return shippingUnit.getValue();
            }
        }

        System.assert(false, 'No compatible active value was found between UMV__c and ShippingWeightUnitOfMeasure');
        return null;
    }

    private static String getValidTranslationLanguage() {
        Schema.DescribeFieldResult languageDescribe = Product2DataTranslation.Language.getDescribe();
        Schema.DisplayType languageType = languageDescribe.getType();

        if (languageType == Schema.DisplayType.Picklist || languageType == Schema.DisplayType.MultiPicklist) {
            for (Schema.PicklistEntry languageValue : languageDescribe.getPicklistValues()) {
                if (languageValue.isActive()) {
                    return languageValue.getValue();
                }
            }
        }

        return UserInfo.getLanguage();
    }
}