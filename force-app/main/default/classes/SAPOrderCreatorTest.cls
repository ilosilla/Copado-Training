@isTest public class SAPOrderCreatorTest {

    public static SAPOrderCreator runCreator(Boolean forceError) {
        
        // Set up mock HTTP callout
        SAPOrderCreatorTest.SAPProxyMockTest mocker = new SAPOrderCreatorTest.SAPProxyMockTest();
        mocker.testError = forceError;
        Test.setMock(HttpCalloutMock.class, mocker);
        
        // Instantiate the class to test
        SAPProxy instance = new SAPProxy(SAPProxy.ORDERS_V2_SERVICE);
        instance.resourceId = '123456';
        instance.queryString = '';
        

        SAPOrderCreator creator = new SAPOrderCreator();
        creator.isCredit = true;
        creator.sapCustomer = '1000111';
        creator.sapInvoice = '1002393060';
        creator.orderReason = 'E1';
        creator.DeliveryDate = System.today();
        
        SAPOrderCreator.OrderItem it1 = new SAPOrderCreator.OrderItem();
        it1.lineReference = 10;
        it1.productCode = '1000123';
        it1.unitCode = 'UN';
        it1.quantity = 5;
        creator.items.add(it1);

        SAPOrderCreator.OrderItem it2 = new SAPOrderCreator.OrderItem();
        it2.lineReference = 20;
        it2.productCode = '1000122';
        it2.unitCode = 'UN';
        it2.quantity = 2;
        creator.items.add(it2);        

        Test.startTest();
        creator.create();
        Test.stopTest();

        return creator;
    }

    @isTest public static void testCreateCredit() {
        SAPOrderCreator creator = runCreator(false);
        Assert.isNotNull(creator.jsonString, 'A JSON should have been generated');
    }

    @isTest public static void testCreateCreditWithError() {
        try {
            runCreator(true);
        } catch(ErrorListException exl) {
            Assert.areNotEqual('', exl.getMessage());
        }
    }

    public class SAPProxyMockTest implements HttpCalloutMock {
        
        public Boolean testError = false;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response    
            SAPOrderCreator.SAPResponse response = new SAPOrderCreator.SAPResponse();
            response.index = 0;
            response.success = true;
            response.orderNumber = '25';
            String js = '[' + JSON.serialize(response) + ']';
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setHeader('x-csrf-token', 'toctoctoc');
            mockResponse.setHeader('set-cookie', 'cooookie');
            if (this.testError) {
                String errorJson = '[{"ERROR":{"ID":"016","TYPE":"E","MESSAGE":"&Referred invoice is from another customer&."},"INDEX":1,"SUCCESS":false},{"ERROR":{"ID":"030","TYPE":"E","MESSAGE":"Missing sales organisation or distribution channel"},"INDEX":1,"SUCCESS":false}]';
                mockResponse.setStatusCode(400);
                mockResponse.setBody(errorJson);
            } else {
                mockResponse.setStatusCode(200);
                mockResponse.setBody(js);
            }
            return mockResponse;
        }
    }

}