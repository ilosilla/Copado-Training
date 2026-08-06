@IsTest
private class PorsaMarketAccountTest {

    private class MockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[' +
                '{' +
                '"Id": "12345",' +
                '"Name": "Test Account",' +
                '"Street": "123 Main St",' +
                '"Street2": "Suite 100",' +
                '"State": "CA",' +
                '"PostCode": "90210",' +
                '"CountryCode": "FR",' +
                '"City": "Paris",' +
                '"Phone": "123456789",' +
                '"Email": "test@example.com",' +
                '"VAT": "FR123456789",' +
                '"VAT2": "FR987654321"' +
                '}' +
            ']');
            return res;
        }
    }

    private class MockError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    @IsTest
    static void testGetDataAndToAccount() {
        Test.setMock(HttpCalloutMock.class, new MockSuccess());

        PorsaMarketAccount acc = new PorsaMarketAccount();
        acc.accountId = 'ACC123';
        acc.pmService = 'FR';
        acc.type = 'ACCOUNT';

        acc.getData();

        System.assertNotEquals(null, acc.data);
        System.assertEquals('test account', acc.data.Name);

        Account sfdcAcc = acc.toAccount();
        System.assertNotEquals(null, sfdcAcc);
        System.assertEquals('test account', sfdcAcc.Name);
    }

    @IsTest
    static void testGetDataErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new MockError());

        PorsaMarketAccount acc = new PorsaMarketAccount();
        acc.accountId = 'ACC123';
        acc.pmService = 'FR';
        acc.type = 'LOT';

        try {
            acc.getData();
            System.assert(false, 'Exception should have been thrown');
        } catch (PorsaMarketAccount.PorsamarketAccountException e) {
            System.assertEquals('Error al recabar datos de porsamarket', e.getMessage());
        }
    }

    @isTest
    static void testReadLot() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<String> csv = new List<String>{'FR', 'Lots', '-1', '-1', '-1', '88032475100036', '-1', 'silvestre@test.es', '2025-04-01'};
        PorsaMarketAccount lot = PorsaMarketAccount.readLot(csv);
        Assert.areEqual('test account', lot.data.Name, 'Get data no funciona');
    }

    @isTest
    static void testReadAccount() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<String> csv = new List<String>{'FR', 'Accounts', '-1', '-1', '-1', '88032475100036', '-1', 'silvestre@test.es', '2025-04-01'};
        PorsaMarketAccount acc = PorsaMarketAccount.readAccount(csv);
        Assert.areEqual('test account', acc.data.Name, 'Get data no funciona');
    }
}