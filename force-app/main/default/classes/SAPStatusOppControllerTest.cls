@isTest public class SAPStatusOppControllerTest {

    /*
     * We give access to all data to this test class and we'll test quotes, orders and invoices in
     * separate tests to avoid searching for a customer with all quotes, orders and invoices.
     */
    @TestSetup
    static void makeData(){
    }

    @isTest private static void getComponentData() {
        String id = TestUtils.getFakeId(Opportunity.getSObjectType());
        setMockQuotes();        
        setMockOrders();    
        setMockInvoices();    
        SAPStatusOppController.ComponentDTO dto = SAPStatusOppController.getComponentData(id);
        System.assertEquals(2, dto.numQuotes, 'Unexpected number of quotes');
        System.assertEquals(2, dto.numOrders, 'Unexpected number of orders');
        System.assertEquals(2, dto.numInvoices, 'Unexpected number of invoices');
        System.assertEquals(36, dto.quotesTotal, 'Unexpected quotes total');
        System.assertEquals(360, dto.ordersTotal, 'Unexpected orders total');
        System.assertEquals(3600, dto.invoicesTotal, 'Unexpected invoices total');

    }
    
    private static void setMockQuotes() {
        Ofertas_cabeceraSet__x o1 = new Ofertas_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 10, lTax__c = 2, OpenF__c = 'A',  Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        Ofertas_cabeceraSet__x o2 = new Ofertas_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 20, lTax__c = 4, OpenF__c = 'C',  Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        SAPStatusOppController.mockQuotes.add(o1);
        SAPStatusOppController.mockQuotes.add(o2);        
    }

    private static void setMockOrders() {
        Pedidos_cabeceraSet__x o1 = new Pedidos_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 100, lTax__c = 20, OpenF__c = 'A', Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        Pedidos_cabeceraSet__x o2 = new Pedidos_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 200, lTax__c = 40,OpenF__c = 'A',  Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        SAPStatusOppController.mockOrders.add(o1);
        SAPStatusOppController.mockOrders.add(o2);        
    }

    private static void setMockInvoices() {
        Facturas_cabeceraSet__x o1 = new Facturas_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 1000, lTax__c = 200,  Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        Facturas_cabeceraSet__x o2 = new Facturas_cabeceraSet__x(
            OrderDate__c = System.today(), Lcurr__c = 'EUR', lNet__c = 2000, lTax__c = 400,  Salesorg__c = OrganizationCommons.ORG_SOUTH_EAST
        );
        SAPStatusOppController.mockInvoices.add(o1);
        SAPStatusOppController.mockInvoices.add(o2);        
    }


}