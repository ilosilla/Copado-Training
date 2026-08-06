@isTest public class SAPStockServiceTest {

    @testSetup public static void testSetup() {
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    public static void setMocker() {
        Test.setMock(HttpCalloutMock.class, new Mocker());
    }

    @isTest private static void test001() {        
        SAPStockServiceTest.setMocker();
        Test.startTest();
        SAPStockService.StockResultDTO resultDTO = SAPStockService.retrieveStockInSalesOrg('213', '502');
        Test.stopTest();
        Assert.isTrue(resultDTO.StockTotal > 0, 'Expected stock greater than zero');
    }

    @isTest private static void test002() {
        String message = null;
        Mocker m = new Mocker();
        m.raiseException = true;
        Test.setMock(HttpCalloutMock.class, m);
        Test.startTest();
            try {
                SAPStockService.retrieveStockInSalesOrg('213', '502');
            } catch (HttpException ex) {
                message = ex.getMessage();
            }
        Test.stopTest();
        Assert.isTrue(message != null, 'Expected an HTTP exception message');
    }

    private static List<SAPStockService.PlantInput> testPlants() {
        SAPStockService.PlantInput plant = new SAPStockService.PlantInput();
        plant.plant = '605';
        plant.warehouses = new List<String>{ '0001' };
        return new List<SAPStockService.PlantInput>{ plant };
    }

    @isTest static void testGetStockTotal_returnsAggregatedRow() {
        Mocker m = new Mocker();
        m.json = '{"data":[{"product":"000000000100000121","name":"CREMA","plant":"605","warehouse":"","availstk":50.000,"totalstk":80.000,"intransit":0,"umb":"PZS","umb_en":"PZS","lote":""}],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, m);

        Test.startTest();
        SAPStockService.StockRowResult result = SAPStockService.getStockTotal(testPlants(), '100000121', true);
        Test.stopTest();

        Assert.areEqual(50, result.availableQty, 'Available quantity mismatch');
        Assert.areEqual(80, result.totalQty, 'Total quantity mismatch');
        Assert.isTrue(String.isBlank(result.lote), 'Aggregated row should have no lote');
    }

    @isTest static void testGetStockTotal_noData_returnsZeroRow() {
        Mocker m = new Mocker();
        m.json = '{"data":[],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, m);

        Test.startTest();
        SAPStockService.StockRowResult result = SAPStockService.getStockTotal(testPlants(), '100000121', true);
        Test.stopTest();

        Assert.areEqual(0, result.availableQty, 'Available quantity should default to 0');
        Assert.areEqual(0, result.totalQty, 'Total quantity should default to 0');
        Assert.areEqual(0, result.inTransitQty, 'In-transit quantity should default to 0');
    }

    @isTest static void testGetStockByLote_returnsOneRowPerLote() {
        Mocker m = new Mocker();
        m.json = '{"data":['
            + '{"product":"000000000100000121","name":"CREMA","plant":"605","warehouse":"0001","availstk":10.000,"totalstk":10.000,"intransit":0,"umb":"PZS","umb_en":"PZS","lote":"101C2"},'
            + '{"product":"000000000100000121","name":"CREMA","plant":"605","warehouse":"0001","availstk":20.000,"totalstk":20.000,"intransit":0,"umb":"PZS","umb_en":"PZS","lote":"102C2"}'
            + '],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, m);

        Test.startTest();
        List<SAPStockService.StockRowResult> results = SAPStockService.getStockByLote(testPlants(), '100000121', false);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Expected one row per lote');
        Assert.areEqual('101C2', results[0].lote, 'First lote mismatch');
        Assert.areEqual('102C2', results[1].lote, 'Second lote mismatch');
    }

    @isTest static void testGetStockByLote_noData_returnsEmptyList() {
        Mocker m = new Mocker();
        m.json = '{"data":[],"errors":[],"status":"OK"}';
        Test.setMock(HttpCalloutMock.class, m);

        Test.startTest();
        List<SAPStockService.StockRowResult> results = SAPStockService.getStockByLote(testPlants(), '100000121', false);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Expected empty list when there is no stock in any lote');
    }

    @isTest static void testGetStockTotal_statusError_throwsStockQueryException() {
        Mocker m = new Mocker();
        m.json = '{"data":[],"errors":["Product 100000121 is not a valid product"],"status":"ERROR"}';
        Test.setMock(HttpCalloutMock.class, m);

        String message = null;
        Test.startTest();
        try {
            SAPStockService.getStockTotal(testPlants(), '100000121', true);
        } catch (SAPStockService.StockQueryException ex) {
            message = ex.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(message != null && message.contains('not a valid product'), 'Expected StockQueryException with the SAP error message');
    }


    public class Mocker implements HttpCalloutMock {        
        public Boolean testError = false;
        public String defaultJson = '[{"availstk":999.000,"name":"CREMA ITALIA ANTICATO BPT 10X30X1,2","product":"000000000100000121","salesorg":"502","totalstk":1159.000,"umb":"PZS","umbEn":"PZS"}]';
        public String json = this.defaultJson;
        public Boolean raiseException = false;

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response            
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            if (this.raiseException) {
                throw new HttpException('Simulated http exception');
            }
            if (this.testError) {
                mockResponse.setStatusCode(400);
                mockResponse.setBody('Generic Error');
            } else {
                mockResponse.setStatusCode(200);
                mockResponse.setBody(json);
            }
            return mockResponse;
        }
    }
}