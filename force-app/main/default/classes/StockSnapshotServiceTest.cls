@isTest public with sharing class StockSnapshotServiceTest {

    private static List<SAP_StockSnapshots__x> getMockData() {
        List<SAP_StockSnapshots__x> data = new List<SAP_StockSnapshots__x>();
        data.add(new SAP_StockSnapshots__x(
            StockKeepingUnit__c = 'SKU1',
            StockUnit__c = 'EA',
            AvailableStock__c = 10,
            OnHandStock__c = 15,
            InTransitStock__c = 5
        ));
        data.add(new SAP_StockSnapshots__x(
            StockKeepingUnit__c = 'SKU1',
            StockUnit__c = 'EA',
            AvailableStock__c = 5,
            OnHandStock__c = 10,
            InTransitStock__c = 2
        ));
        data.add(new SAP_StockSnapshots__x(
            StockKeepingUnit__c = 'SKU2',
            StockUnit__c = 'EA',
            AvailableStock__c = 20,
            OnHandStock__c = 25,
            InTransitStock__c = 0
        ));
        return data;
    }

    @isTest private static void testGetStockBySku() {
        Map<String, StockSnapshotService.StockSnapshotDTO> result1;
        result1 = StockSnapshotService.getStockBySku(null, new List<String>(), new List<String>());  
        Assert.areEqual(0, result1.size(), 'Result should be empty when plant is null/empty');

        result1 = StockSnapshotService.getStockBySku('605', new List<String>(), new List<String>());  
        Assert.areEqual(0, result1.size(), 'Result should be empty when warehouses is null/empty');

        result1 = StockSnapshotService.getStockBySku('605', new List<String>{'0001'}, new List<String>());  
        Assert.areEqual(0, result1.size(), 'Result should be empty when skus is null/empty');

        result1 = StockSnapshotService.getStockBySku('605', new List<String>{'0001'}, new List<String>{'1001001', '1001002'});  
        Assert.areEqual(0, result1.size(), 'Result should be empty anyway since there is no data in the org');
    }

    @isTest private static void testGetMockStockBySku() {
        List<SAP_StockSnapshots__x> mockData = getMockData();
        List<String> skus = new List<String>{'SKU1', 'SKU2', 'SKU3'};
        String plant = '1000';
        List<String> warehouses = new List<String>{'WH1', 'WH2'};

        Map<String, StockSnapshotService.StockSnapshotDTO> stockMap =
            StockSnapshotService.getMockStockBySku(plant, warehouses, skus, mockData);

        System.assertEquals(2, stockMap.size(), 'Should have 2 SKUs in the result');

        StockSnapshotService.StockSnapshotDTO sku1Stock = stockMap.get('SKU1');
        System.assertNotEquals(null, sku1Stock, 'SKU1 should be present');
        System.assertEquals(15, sku1Stock.availableStock, 'SKU1 available stock should be 15');
        System.assertEquals(25, sku1Stock.onHandStock, 'SKU1 on-hand stock should be 25');
        System.assertEquals(7, sku1Stock.inTransitStock, 'SKU1 in-transit stock should be 7');

        StockSnapshotService.StockSnapshotDTO sku2Stock = stockMap.get('SKU2');
        System.assertNotEquals(null, sku2Stock, 'SKU2 should be present');
        System.assertEquals(20, sku2Stock.availableStock, 'SKU2 available stock should be 20');
        System.assertEquals(25, sku2Stock.onHandStock, 'SKU2 on-hand stock should be 25');
        System.assertEquals(0, sku2Stock.inTransitStock, 'SKU2 in-transit stock should be 0');

        System.assertEquals(null, stockMap.get('SKU3'), 'SKU3 should not be present');
    }

}