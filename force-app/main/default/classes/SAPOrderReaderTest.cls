@isTest public with sharing class SAPOrderReaderTest {

    public static final String TEST_CUSTOMER_CODE = '1000123';

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
    public class StubbedSAPOrderReader implements System.StubProvider {
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object proxy, String methodName, System.Type returnType,
                                       List<System.Type> parameterTypes, List<String> parameterNames,
                                       List<Object> args) {                
            if (methodName == 'readOrder') {
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

    /* =========================================================
     * TEST METHODS
     * ========================================================= */ 

    @isTest static void testReadOrder() {
        B2BSalesDocContracts.OrderHeaderDTO header = SAPOrderReader.readHeader('0000000010');
        Assert.isNull(header, 'Expected null for non-existing order');        
    }

    @isTest static void testReadOrderItems() {
        B2BSalesDocContracts.OrderItemDTO[] items = SAPOrderReader.readItems('0000000010');
        Assert.areEqual(0, items.size(), 'Expected no items');
    }

    @isTest static void testMapHeader() {
        Pedidos_cabeceraSet__x header = mockSAPOrderHeader('0000000010');
        B2BSalesDocContracts.OrderHeaderDTO  dto = SAPOrderReader.mapHeader(header);
        Assert.isNotNull(dto, 'Expected non-null DTO');
        Assert.areEqual(header.Ordernum__c, dto.orderNumber, 'Order number mismatch');
    }

    @isTest static void testMapItem() {
        Pedidos_posicionesSet__x item = mockSAPOrderItems('0000000010')[0];
        B2BSalesDocContracts.OrderItemDTO  dto = SAPOrderReader.mapItem(item);
        Assert.isNotNull(dto, 'Expected non-null DTO');
        Assert.areEqual(Integer.valueOf(item.Orderlin__c), dto.lineNumber, 'Order line number mismatch');
    }   

    public static Pedidos_cabeceraSet__x mockSAPOrderHeader(String orderNumber) {
        return new Pedidos_cabeceraSet__x(
            BillTo__c = TEST_CUSTOMER_CODE,
            Customer__c = TEST_CUSTOMER_CODE,
            Dcurr__c = 'USD',
            Ordertype__c = 'ZW04',
            Orderdate__c = Date.today(),
            Ordernum__c = orderNumber,
            Dnet__c = 100,
            Dtax__c = 10,
            Dtotal__c = 110,
            Lcurr__c = 'USD',
            Lnet__c = 100,
            Ltax__c = 10,
            Ltotal__c = 110,
            OpenF__c = 'Open',
            ddate__c = Date.today().addDays(5),
            Distchannel__c = '60',
            Salesoffic__c = '2552',
            Salesorg__c = '502',
            Sfopportunity__c = null,
            Refer__c = 'PO-TEST1',
            DestinoMerc__c = TEST_CUSTOMER_CODE
        );
    }

    public static Pedidos_posicionesSet__x[] mockSAPOrderItems(String orderNumber) {
        Pedidos_posicionesSet__x[] lines = new List<Pedidos_posicionesSet__x>();

        lines.add(new Pedidos_posicionesSet__x(
            Ordernum__c  = orderNumber,
            Orderlin__c  = '10',
            Sku__c       = 'SKU-TEST-001',
            Name__c      = 'Sample item 1',
            Quantity__c  = 2,
            Vrkme__c     = 'PCS',
            Netpr__c     = 50,
            Kmein__c     = 'PCS',
            Dcurr__c     = 'USD',
            Dnet__c      = 100,
            Dtax__c      = 10,
            Dtotal__c    = 110,
            Sqmetres__c  = 1.25,
            Status__c    = '10',
            OpenF__c     = 'A'
        ));
        lines.add(new Pedidos_posicionesSet__x(
            Ordernum__c  = orderNumber,
            Orderlin__c  = '20',
            Sku__c       = 'SKU-TEST-002',
            Name__c      = 'Sample item 2',
            Quantity__c  = 1,
            Vrkme__c     = 'PCS',
            Netpr__c     = 80,
            Kmein__c     = 'PCS',
            Dcurr__c     = 'USD',
            Dnet__c      = 80,
            Dtax__c      = 8,
            Dtotal__c    = 88,
            Sqmetres__c  = 0.80,
            Status__c    = '11',
            OpenF__c     = 'B'
        ));
        return lines;
    }    
}