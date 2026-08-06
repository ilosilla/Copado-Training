@isTest public with sharing class B2BOrdersReaderTest {

    /* ====================================================
     * PUBLIC STUB PROVIDER
     * --------------------
     * Use it in classes that use SAPOrderReader as:
     * 
     * Test.createStub(
     *    SAPOrderReader.class, 
     *    new SAPOrderReader.StubbedSAPOrderReader()
     * );
     * 
     * ==================================================== */
    /*
    public class StubbedSAPOrderReader implements System.StubProvider {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object proxy, String methodName, System.Type returnType,
                                       List<System.Type> parameterTypes, List<String> parameterNames,
                                       List<Object> args) {                
            if (methodName == 'selectSAPOrders') {
                Pedidos_cabeceraSet__x mockHeader = SAPOrderReaderTest.mockSAPOrderHeader(args[0]);
                return new List<Pedidos_cabeceraSet__x>{ mockHeader };
            } else if (methodName == 'readHeader') {
                Pedidos_cabeceraSet__x mockHeader = SAPOrderReaderTest.mockSAPOrderHeader((String) args[0]);
                B2BSalesDocContracts.OrderHeaderDTO dto = SAPOrderReader.mapHeader(mockHeader);
                Pedidos_posicionesSet__x[] mockItems = SAPOrderReaderTest.mockSAPOrderItems((String) args[0]);
                dto.items = new List<B2BSalesDocContracts.OrderItemDTO>();
                for (Pedidos_posicionesSet__x item : mockItems) {
                    dto.items.add(SAPOrderReader.mapItem(item)); 
                }
                return dto;
            }
            return null;
        }
    }
    */
    /* =========================================================
     * TEST METHODS
     * ========================================================= */

    @isTest public static void test001() {
        B2BOrdersReader.OrderDTO[] data = B2BOrdersReader.selectSAPOrders('123123', '605', 'THIS_MONTH', null, null, true, 50);
        Assert.areEqual(0, data.size(), 'Expected no orders for non-existing customer');
    }

    @isTest public static void test002() {
        Pedidos_cabeceraSet__x mockData = SAPOrderReaderTest.mockSAPOrderHeader('1000000');
        B2BOrdersReader.mockData = new List<Pedidos_cabeceraSet__x>{ mockData };
        List<B2BOrdersReader.OrderDTO> data = B2BOrdersReader.selectSAPOrders('123123', '605', 'THIS_MONTH', null, null, true, 50);
        Assert.areEqual(1, data.size(), 'Expected one order from stub');
    }

    @isTest public static void test003() {
        Order[] orders = DataFactoryOrder.createOrders(10);
        Set<String> sapIds = new Set<String>();
        Integer i = 0;
        for (Order o : orders) {
            o.SAP_Id__c = String.valueOf(1000000 + i++);
            sapIds.add(o.SAP_Id__c);
        }
        update orders;
        Assert.areEqual(10, sapIds.size(), 'Expected 10 unique SAP IDs');   
        Test.startTest();
        Map<String, SObject> ordersMap = B2BOrdersReader.selectOrdersBySAPId(sapIds);
        Test.stopTest();
        Assert.areEqual(10, ordersMap.size(), 'Expected 10 orders returned');
    }

    @isTest private static void test004() {
        Order[] orders = DataFactoryOrder.createOrders(5);        
        Id accountId = orders[0].AccountId;
        String SalesOrg = orders[0].SalesOrg__c;
        Assert.isNotNull(salesOrg, 'Sales org should not be null');
        for (Order o: orders) {
            o.Origin__c = 'B2B';
        }
        update orders;

        Test.startTest();
        B2BOrdersReader.OrderDTO[] result = B2BOrdersReader.selectSFOpenOrders(accountId, salesOrg, 10);
        Test.stopTest();
        Assert.areEqual(orders.size(), result.size(), 'All orders should have been read');
    }

    @isTest public static void test005() {
        Order[] orders = DataFactoryOrder.createOrders(5);     
        Id accountId = orders[0].AccountId;
        String salesOrg = orders[0].SalesOrg__c;
        Assert.isNotNull(salesOrg, 'Sales org should not be null');
        for (Order o: orders) {
            o.Origin__c = 'B2B';
        }
        update orders;

        // And set sap orders as mock data
        Pedidos_cabeceraSet__x mockData = SAPOrderReaderTest.mockSAPOrderHeader('1000000');
        B2BOrdersReader.mockData = new List<Pedidos_cabeceraSet__x>{ mockData };

        Account acc = [SELECT Id, SAP_Id__c FROM Account WHERE Id = :accountId LIMIT 1];
        acc.SAP_Id__c = mockData.Customer__c;
        update acc;

        Test.startTest();
        List<B2BOrdersReader.OrderDTO> data = B2BOrdersReader.selectOpenOrders(accountId, salesOrg, 50);
        Test.stopTest();
        Assert.isTrue(data.size() > 0, 'Expected at least one order from stub');        
    }

}