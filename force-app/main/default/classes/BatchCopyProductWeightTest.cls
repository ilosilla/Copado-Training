@isTest
public class BatchCopyProductWeightTest {

    @testSetup
    private static void setupData() {
        DataFactoryProduct.skipPriceBooks = true;
        DataFactoryProduct.createProducts(null);
        DataFactoryProduct.skipPriceBooks = false;
    }

    @isTest
    static void testWrapperDelegatesMethods() {
        String validUnit = getValidShippingUnit();
        List<Product2> products = [
            SELECT Id, PesoUMV__c, UMV__c, ShippingWeight, ShippingWeightUnitOfMeasure
            FROM Product2
            ORDER BY Id
            LIMIT 2
        ];

        products[0].PesoUMV__c = 12.5;
        products[0].UMV__c = validUnit;
        products[1].PesoUMV__c = 8;
        products[1].UMV__c = validUnit;
        update products;

        BatchCopyProductWeight batch = new BatchCopyProductWeight();
        Database.QueryLocator locator = batch.start(null);

        List<SObject> scope = new List<SObject>();
        scope.addAll(products);

        Test.startTest();
            batch.execute(null, scope);
            batch.finish(null);
        Test.stopTest();

        System.assertNotEquals(null, batch, 'The compatibility wrapper should be instantiable');
        System.assertNotEquals(null, locator, 'The wrapper should delegate start()');

        Map<Id, Product2> refreshedById = new Map<Id, Product2>([
            SELECT Id, ShippingWeight, ShippingWeightUnitOfMeasure
            FROM Product2
            WHERE Id IN :new Map<Id, Product2>(products).keySet()
        ]);

        System.assertEquals(12.5, refreshedById.get(products[0].Id).ShippingWeight, 'The wrapper should delegate execute()');
        System.assertEquals(validUnit, refreshedById.get(products[0].Id).ShippingWeightUnitOfMeasure, 'The wrapper should delegate execute()');
    }

    private static String getValidShippingUnit() {
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
}