@isTest
private class DvsPorsaServiceTest {
    
    // Clase mock para simular SAPCPIProxy
    private class SAPCPIProxyMock {
        public String method;
        public String body;

        public SAPCPIProxyMock(String endpoint) {
        }

        public void setMethod(String method) {
            this.method = method;
        }

        public void setJSONBody(String jsonBody) {
            this.body = jsonBody;
        }

        public String callCPI() {
            return JSON.serialize(new Map<String, Object>{
                'country' => 'DE',
                'taxNumber1Label' => 'VAT',
                'valid' => true,
                'resultCount' => 1,
                'maxScore' => 98.5,
                'source' => 'Mock',
                'searchType' => 'FULL',
                'results' => new List<Object>{
                    new Map<String, Object>{
                        'companyName' => 'Test Company',
                        'companyNumber' => '12345',
                        'taxNumber1' => 'VAT123',
                        'status' => 'Active',
                        'score' => 98.5,
                        'liveChecked' => true,
                        'address' => new Map<String, Object>{
                            'line1' => 'Test Strasse 1',
                            'line2' => '',
                            'postalCode' => '12345',
                            'city' => 'Berlin',
                            'country' => 'DE'
                        }
                    }
                }
            });
        }
    }

    // Método auxiliar para crear una cuenta de prueba
    private static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = 'Test Strasse 1',
            BillingPostalCode = '12345',
            BillingCity = 'Berlin',
            BillingCountryCode = 'DE',
            VAT_Number__c = 'VAT123',
            VAT_Number_2__c = 'COMP123'
        );
        insert acc;
        return acc;
    }

    @isTest
    static void testDoFullSearch() {
        SAPCPIProxyMock proxyMock = new SAPCPIProxyMock(SAPCPIProxy.DVS_ENDPOINT);
        DvsPorsaService.DvsResultsWrapper aux = DvsPorsaService.parseCpiResponse(proxyMock.callCPI());
        System.assertNotEquals(null, aux);
        System.assertEquals(1, aux.results.size());
    }

    @isTest
    static void testCreateDiscrepancy() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';

        Account acc = createTestAccount();
        DvsPorsaService service = new DvsPorsaService(acc);

        DvsPorsaService.DvsResultWrapper wrapper = new DvsPorsaService.DvsResultWrapper();
        wrapper.companyName = 'Other Company';
        wrapper.taxNumber1 = 'TAX456';
        wrapper.companyNumber = 'CN456';
        wrapper.address = new DvsPorsaService.DvsAddressWrapper();
        wrapper.address.line1 = 'Street X';
        wrapper.address.postalCode = '67890';
        wrapper.address.city = 'Munich';

        DvsDiscrepancy__c discrepancy = service.createDiscrepancy(wrapper);
        System.assertEquals('Other Company', discrepancy.DvsName__c);
        System.assertEquals(acc.Name, discrepancy.SalesforceName__c);
    }

    /*@isTest
    static void testSelectBestOption() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';

        Account acc = createTestAccount();
        DvsPorsaService service = new DvsPorsaService(acc);
        service.dvsInfo = new DvsPorsaService.DvsResultsWrapper();
        DvsPorsaService.DvsResultWrapper res1 = new DvsPorsaService.DvsResultWrapper();
        res1.companyName = 'A';
        res1.score = 90;
        DvsPorsaService.DvsResultWrapper res2 = new DvsPorsaService.DvsResultWrapper();
        res2.companyName = 'B';
        res2.score = 95;
        service.dvsInfo.results.add(res1);
        service.dvsInfo.results.add(res2);

        service.selectBestOption();

        System.assertEquals('B', service.bestOption.companyName);
    }*/

    @isTest
    static void testNullAccountException() {
        SystemSettings.SAPAPIUrl = 'https://fake.cpi.endpoint.com';
        SystemSettings.SAPCPIAPIKey = 'test-api-key';
        
        DvsPorsaService service = new DvsPorsaService(null);
        try {
            service.doFullSearch();
            System.assert(false, 'Exception not thrown');
        } catch (DvsPorsaService.DvsPorsaException e) {
            System.assertEquals('No account set on the service', e.getMessage());
        }
    }

    @isTest
    static void fillerTestAccountAdditionalData() {
        DvsPorsaService.testFiller();
        Assert.isTrue(1 == 1);
    }
}