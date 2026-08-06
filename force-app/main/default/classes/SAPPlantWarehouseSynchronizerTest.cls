@IsTest
private class SAPPlantWarehouseSynchronizerTest {

    @IsTest
    static void testExecuteNow_emptySourcesShouldComplete() {
        SAPPlantWarehouseSynchronizer.mockedPlants = new List<SAP_Plants__x>();
        SAPPlantWarehouseSynchronizer.mockedWarehouses = new List<SAP_Warehouses__x>();

        Test.startTest();
        SAPPlantWarehouseSynchronizer.executeNow();
        Test.stopTest();

        System.assertEquals(true, true, 'Synchronous execution should complete');
    }

    @IsTest
    static void testSynchronizerExecution() {
        // Crea plantas destino existentes
        insert new SAPPlant__c(
            Plant__c = '1000',
            Name = 'Viejo Nombre',
            Country__c = 'ES',
            Province__c = 'OLD',
            Postcode__c = '00000',
            Street__c = 'Old Street',
            SalesOrg__c = '502',
            PurchaseOrg__c = '0000',
            IsDeleted__c = true
        );

        insert new SAPPlant__c(
            Plant__c = '9999',
            Name = 'Planta Antigua',
            Country__c = 'ES',
            Province__c = 'OLD',
            Postcode__c = '99999',
            Street__c = 'Ancient Street',
            SalesOrg__c = '502',
            PurchaseOrg__c = '0000',
            IsDeleted__c = false
        );

        // Crea almacenes destino existentes
        Id oldPlantId = [
            SELECT Id
            FROM SAPPlant__c
            WHERE Plant__c = '9999'
            LIMIT 1
        ].Id;

        insert new SAPWarehouse__c(
            Plant__c = oldPlantId,
            Warehouse__c = 'X1',
            Name = 'Antiguo Almacén',
            WarehouseKey__c = '9999-X1',
            IsDeleted__c = false
        );

        // Simula datos externos usando valores conocidos válidos en la org
        List<SAP_Plants__x> mockPlants = new List<SAP_Plants__x>{
            new SAP_Plants__x(
                Plant__c = '1000',
                Name1__c = 'Planta Valencia',
                Land1__c = 'ES',
                Regio__c = 'VLC',
                Pstlz__c = '46000',
                Stras__c = 'Calle Uno',
                Vkorg__c = '514',
                Ekorg__c = 'E514'
            ),
            new SAP_Plants__x(
                Plant__c = '2000',
                Name1__c = 'Planta Vila-real',
                Land1__c = 'ES',
                Regio__c = 'CAS',
                Pstlz__c = '12540',
                Stras__c = 'Calle Dos',
                Vkorg__c = '517',
                Ekorg__c = 'E517'
            )
        };

        List<SAP_Warehouses__x> mockWarehouses = new List<SAP_Warehouses__x>{
            new SAP_Warehouses__x(
                Plant__c = '1000',
                Warehouse__c = 'A1',
                Name__c = 'Almacén A1'
            ),
            new SAP_Warehouses__x(
                Plant__c = '2000',
                Warehouse__c = 'B2',
                Name__c = 'Almacén B2'
            )
        };

        // Inyecta mocks
        SAPPlantWarehouseSynchronizer.mockedPlants = mockPlants;
        SAPPlantWarehouseSynchronizer.mockedWarehouses = mockWarehouses;

        Test.startTest();
        SAPPlantWarehouseSynchronizer.executeNow();
        Test.stopTest();

        // Validaciones de plantas
        Map<String, SAPPlant__c> plants = new Map<String, SAPPlant__c>();

        for (SAPPlant__c plant : [
            SELECT Plant__c,
                   Name,
                   Country__c,
                   Province__c,
                   Postcode__c,
                   Street__c,
                   SalesOrg__c,
                   PurchaseOrg__c,
                   IsDeleted__c
            FROM SAPPlant__c
        ]) {
            plants.put(plant.Plant__c, plant);
        }

        System.assertEquals(true, plants.containsKey('1000'), 'Plant 1000 should exist');
        System.assertEquals(true, plants.containsKey('2000'), 'Plant 2000 should exist');
        System.assertEquals(true, plants.containsKey('9999'), 'Plant 9999 should still exist');

        System.assertEquals('Planta Valencia', plants.get('1000').Name);
        System.assertEquals('ES', plants.get('1000').Country__c);
        System.assertEquals('VLC', plants.get('1000').Province__c);
        System.assertEquals('46000', plants.get('1000').Postcode__c);
        System.assertEquals('Calle Uno', plants.get('1000').Street__c);
        System.assertEquals('514', plants.get('1000').SalesOrg__c);
        System.assertEquals('E514', plants.get('1000').PurchaseOrg__c);
        System.assertEquals(false, plants.get('1000').IsDeleted__c);

        System.assertEquals('Planta Vila-real', plants.get('2000').Name);
        System.assertEquals('ES', plants.get('2000').Country__c);
        System.assertEquals('CAS', plants.get('2000').Province__c);
        System.assertEquals('12540', plants.get('2000').Postcode__c);
        System.assertEquals('Calle Dos', plants.get('2000').Street__c);
        System.assertEquals('517', plants.get('2000').SalesOrg__c);
        System.assertEquals('E517', plants.get('2000').PurchaseOrg__c);
        System.assertEquals(false, plants.get('2000').IsDeleted__c);

        System.assertEquals(true, plants.get('9999').IsDeleted__c);

        // Validaciones de almacenes
        List<SAPWarehouse__c> warehouses = [
            SELECT WarehouseKey__c,
                   Warehouse__c,
                   Name,
                   IsDeleted__c,
                   Plant__c
            FROM SAPWarehouse__c
        ];

        Map<String, SAPWarehouse__c> whMap = new Map<String, SAPWarehouse__c>();

        for (SAPWarehouse__c warehouse : warehouses) {
            whMap.put(warehouse.WarehouseKey__c, warehouse);
        }

        System.assertEquals(true, whMap.containsKey('1000-A1'), 'Warehouse 1000-A1 should exist');
        System.assertEquals(true, whMap.containsKey('2000-B2'), 'Warehouse 2000-B2 should exist');
        System.assertEquals(true, whMap.containsKey('9999-X1'), 'Warehouse 9999-X1 should still exist');

        System.assertEquals('Almacén A1', whMap.get('1000-A1').Name);
        System.assertEquals('A1', whMap.get('1000-A1').Warehouse__c);
        System.assertEquals(false, whMap.get('1000-A1').IsDeleted__c);
        System.assertEquals(plants.get('1000').Id, whMap.get('1000-A1').Plant__c);

        System.assertEquals('Almacén B2', whMap.get('2000-B2').Name);
        System.assertEquals('B2', whMap.get('2000-B2').Warehouse__c);
        System.assertEquals(false, whMap.get('2000-B2').IsDeleted__c);
        System.assertEquals(plants.get('2000').Id, whMap.get('2000-B2').Plant__c);

        System.assertEquals(true, whMap.get('9999-X1').IsDeleted__c);
    }
}