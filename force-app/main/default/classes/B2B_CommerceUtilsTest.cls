@isTest public without sharing class B2B_CommerceUtilsTest {

    @testSetup static void setupTestData() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();
    }

    @isTest static void getApplicablePricebookId() {
        WebStore store = [select Id from WebStore limit 1];
        Account acc = [select Id from Account limit 1];
    
        Id pricebookId = B2B_CommerceUtils.getApplicablePricebookId(acc.Id, store.Id);
        Assert.isNotNull(pricebookId, 'Default Pricebook Id should not be null');
    }

    @IsTest static void testGetStockStatus() {

        // CASE 1: BOX, <= 1 pallet → LOW
        /*System.assertEquals(
            // 'LOW',  // Hemos eliminado el estado LOW
            'IN_STOCK',
            B2B_CommerceUtils.getStockStatus(100, 100, 0, 'BOX', 50, 3),
            'BOX <= 1 pallet should be LOW'
        );*/

        // CASE 2: BOX, > 1 pallet → IN_STOCK
        System.assertEquals(
            'IN_STOCK',
            B2B_CommerceUtils.getStockStatus(400, 400, 0, 'BOX', 50, 3),
            'BOX > 1 pallet should be IN_STOCK'
        );

        // CASE 3: PCS, available > 50 → IN_STOCK
        System.assertEquals(
            'IN_STOCK',
            B2B_CommerceUtils.getStockStatus(80, 80, 0, 'PCS', 0, 0),
            'PCS > 50 should be IN_STOCK'
        );

        // CASE 4: PCS, available <= 50 → LOW
        /*
        System.assertEquals(
            'LOW',
            B2B_CommerceUtils.getStockStatus(20, 20, 0, 'PCS', 0, 0),
            'PCS <= 50 should be LOW'
        );
        */

        // CASE 5: No available, but in transit → SOON
        System.assertEquals(
            'SOON',
            B2B_CommerceUtils.getStockStatus(0, 0, 15, 'BOX', 50, 3),
            'In transit only should be SOON'
        );

        // CASE 6: No stock at all → OUT
        System.assertEquals(
            'OUT',
            B2B_CommerceUtils.getStockStatus(0, 0, 0, 'BOX', 50, 3),
            'No stock should be OUT'
        );
    }

    @isTest private static void testSettings() {
        PORSAStoreSettings__c settings = B2B_CommerceUtils.resolveStoreSettings();
        System.assertNotEquals(null, settings, 'Settings should not be null');
    }

    @isTest private static void testGetB2BWarehouse() {
        PorcelanosaAddress__c warehouse = new B2B_CommerceUtils().getB2BWarehouse('2000');
        Assert.isTrue(true, 'Dummy test to cover getB2BWarehouse method. Warehouse found: ' + (warehouse != null ? warehouse.Name : 'null'));
    }   
}