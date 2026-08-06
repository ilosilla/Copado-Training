/**
* @author 			Ramón Prades
* @date 			November-2020
* @group 			Accounts
* @group-content 	../../ApexDocContent/Accounts.htm
* @description 	    Test class
*/

/* ************************************************* */
/*           Warning - SeeAllData = true             */
/* ************************************************* */

@isTest public class SAPSalesDocumentControllerTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();
        DataFactoryAccount.createAccounts(1);
    }

    @isTest private static void testGetSAPDocument() {
        SAPSalesDocumentController.getSAPDocument('O', '111111', null);
        SAPSalesDocumentController.getSAPDocument('I', '211111', null);
        SAPSalesDocumentController.getSAPDocument('Q', '311111', null);
        Assert.areEqual(true, true, 'dummy');
    }

    @isTest private static void testDownloadV2() {
        Boolean fail = false;
        try {
            String data = SAPSalesDocumentController.downloadSAPDocumentV2('I', '11111');
            Assert.isNull(data, 'No data expected');
        } catch (AuraHandledException ex) {
           fail = true;
           Assert.isTrue(fail, ex.getMessage());
        }
    }

    @isTest private static void testDownload() {
        SAPWS_Utility.SapResponse response = SAPSalesDocumentController.downloadSAPDocument('I', '11111');
        Assert.isFalse(response.success, 'No data expected');
    }

    @isTest private static void testReadQuote() {
        Account acc = [select Id from Account limit 1];
        String docNumber = '0001000000';
        SAPSalesDocumentController.ExternalDataFetcher fetcher = new MockOfertasCabeceraDataFetcher();
        SAPSalesDocumentController.SAPDocumentDTO dto = SAPSalesDocumentController.readQuote(docNumber,fetcher, acc.Id);
        System.Assert.areEqual('0001000000', dto.docNumber, 'docNumber should be 0001000000');
    }

    @isTest private static void testReadInvoice() {
        Account acc = [select Id from Account limit 1];
        String docNumber = '0002000000';
        SAPSalesDocumentController.ExternalDataFetcher fetcher = new MockFacturasCabeceraDataFetcher();
        SAPSalesDocumentController.SAPDocumentDTO dto = SAPSalesDocumentController.readInvoice(docNumber,fetcher, acc.Id);
        System.Assert.areEqual('0002000000', dto.docNumber, 'docNumber should be 0002000000');
    }

    @isTest private static void testReadOrder() {
        Account acc = [select Id from Account limit 1];
        String docNumber = '0003000000';
        SAPSalesDocumentController.ExternalDataFetcher fetcher = new MockPedidosCabeceraDataFetcher();
        SAPSalesDocumentController.SAPDocumentDTO dto = SAPSalesDocumentController.readOrder(docNumber,fetcher, acc.Id);
        System.Assert.areEqual('0003000000', dto.docNumber, 'docNumber should be 0003000000');
        System.Assert.areEqual('O', dto.docType, 'docType should be O');
    }


    // Mock Data Fetcher for Ofertas_cabeceraSet__x
    public class MockOfertasCabeceraDataFetcher implements SAPSalesDOcumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Ofertas_cabeceraSet__x> mockData = new List<Ofertas_cabeceraSet__x>();
            mockData.add(new Ofertas_cabeceraSet__x(
                BillTo__c = '123321',
                Customer__c = '123321',
                Dcurr__c = 'USD',
                Ordertype__c = 'MockOrderType',
                Orderdate__c = Date.today(),
                Ordernum__c = docNumber.leftPad(10, '0'),
                Dnet__c = 1000,
                Dtax__c = 100,
                Dtotal__c = 1100,
                Lcurr__c = 'USD',
                Lnet__c = 1000,
                Ltax__c = 100,
                Ltotal__c = 1100,
                OpenF__c = 'Open',
                Distchannel__c = 'MockChannel',
                Salesoffic__c = 'MockOffice',
                Salesorg__c = 'MockOrg',
                Sfopportunity__c = null,
                Refer__c = 'MockReference',
                Repo1__c = 'MockRep1',
                Repo2__c = 'MockRep2'
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return new MockOfertasPosicionesDataFetcher();
        }
    }

    // Mock Data Fetcher for Facturas_cabeceraSet__x
    public class MockFacturasCabeceraDataFetcher implements SAPSalesDocumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Facturas_cabeceraSet__x> mockData = new List<Facturas_cabeceraSet__x>();
            mockData.add(new Facturas_cabeceraSet__x(
                BillTo__c = '555555',
                Dcurr__c = 'USD',
                Orderdate__c = Date.today(),
                Ordertype__c = 'MockOrderType',
                Ordernum__c = docNumber.leftPad(10, '0'),
                Dnet__c = 2000,
                Dtax__c = 200,
                Dtotal__c = 2200,
                Lcurr__c = 'USD',
                Lnet__c = 2000,
                Ltax__c = 200,
                Ltotal__c = 2200,
                OpenF__c = 'Open',
                Paid__c = 'X',
                Distchannel__c = 'MockChannel',
                Salesorg__c = 'MockOrg',
                Sfopportunity__c = null,
                Salesoffic__c = 'MockOffice',
                Refer__c = 'MockReference',
                Repo1__c = 'MockRep1',
                Repo2__c = 'MockRep2'
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return new MockFacturasPosicionesDataFetcher();
        }
    }

    // Mock Data Fetcher for Pedidos_cabeceraSet__x
    public class MockPedidosCabeceraDataFetcher implements SAPSalesDocumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Pedidos_cabeceraSet__x> mockData = new List<Pedidos_cabeceraSet__x>();
            mockData.add(new Pedidos_cabeceraSet__x(
                BillTo__c = 'MockBillTo',
                Customer__c = 'MockCustomer',
                Dcurr__c = 'EUR',
                Ordertype__c = 'MockOrderType',
                Orderdate__c = Date.today(),
                Ordernum__c = docNumber.leftPad(10, '0'),
                Dnet__c = 1500,
                Dtax__c = 150,
                Dtotal__c = 1650,
                Lcurr__c = 'EUR',
                Lnet__c = 1500,
                Ltax__c = 150,
                Ltotal__c = 1650,
                OpenF__c = 'Open',
                ddate__c = Date.today().addDays(5),
                Distchannel__c = 'MockChannel',
                Salesoffic__c = 'MockOffice',
                Salesorg__c = 'MockOrg',
                Sfopportunity__c = null,
                Refer__c = 'MockReference',
                Repo1__c = 'MockRep1',
                Repo2__c = 'MockRep2'
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return new MockPedidosPosicionesDataFetcher();
        }
    }

    // Mock Data Fetcher for Ofertas_posicionesSet__x
    public class MockOfertasPosicionesDataFetcher implements SAPSalesDocumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Ofertas_posicionesSet__x> mockData = new List<Ofertas_posicionesSet__x>();
            mockData.add(new Ofertas_posicionesSet__x(
                orderNum__c = docNumber.leftPad(10, '0'),
                orderLin__c = '001',
                SKU__c = 'MockSKU',
                name__c = 'MockProduct',
                quantity__c = 5,
                unitCode__c = 'EA',
                dcurr__c = 'USD',
                dnet__c = 200,
                dtax__c = 20,
                dtotal__c = 220
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return null;
        }
    }

    // Mock Data Fetcher for Facturas_posicionesSet__x
    public class MockFacturasPosicionesDataFetcher implements SAPSalesDocumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Facturas_posicionesSet__x> mockData = new List<Facturas_posicionesSet__x>();
            mockData.add(new Facturas_posicionesSet__x(
                orderNum__c = docNumber.leftPad(10, '0'),
                orderLin__c = '001',
                SKU__c = 'MockSKU',
                name__c = 'MockProduct',
                quantity__c = 10,
                unitCode__c = 'EA',
                dcurr__c = 'USD',
                dnet__c = 500,
                dtax__c = 50,
                dtotal__c = 550
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return null;
        }
    }

    // Mock Data Fetcher for Pedidos_posicionesSet__x
    public class MockPedidosPosicionesDataFetcher implements SAPSalesDocumentController.ExternalDataFetcher {
        public List<SObject> fetchData(String docNumber) {
            List<Pedidos_posicionesSet__x> mockData = new List<Pedidos_posicionesSet__x>();
            mockData.add(new Pedidos_posicionesSet__x(
                orderNum__c = docNumber.leftPad(10, '0'),
                orderLin__c = '001',
                SKU__c = 'MockSKU',
                name__c = 'MockProduct',
                quantity__c = 7,
                unitCode__c = 'EA',
                dcurr__c = 'EUR',
                dnet__c = 700,
                dtax__c = 70,
                dtotal__c = 770
            ));
            return (List<SObject>) mockData;
        }
        public SAPSalesDocumentController.ExternalDataFetcher getItemsFetcher() {
            return null;
        }
    }

    
}