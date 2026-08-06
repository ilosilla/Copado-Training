@isTest public class NB2B_StockCallOutManagerTest{



    @TestSetup
	static public void setupData(){
        
        List<Account> acclist = new List<Account>();
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        acclist.add(acc);
        insert acclist;  

        Sales_Org__c s = new Sales_Org__c (
            Name = 'TestSalesOrg',
            SalesOrg__c = '777'
        );
        insert s;
        
        Product2 pro = new Product2 (
	    		Name = 'TestProduct1',
	    		IsActive = true, 
                StockKeepingUnit = '1234567'
	    	);
        insert pro;       
    }
  
  @isTest public static void testCallout() {
        MultiStaticResourceCalloutMock multimock= new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:SAP/api/customers/ping', 'NB2BStockCallout');
        multimock.setStaticResource('callout:SAP/api/stock/sales-org/777/1234567', 'NB2BStockCallout');
        multimock.setStatusCode(200);
        multimock.setHeader('x-csrf-token', 'testToken');
        multimock.setHeader('set-cookie', 'testCookie');
        multimock.setHeader('Content-Type', 'application/json');

        List <Product2> productList = [SELECT Id,Name,StockKeepingUnit FROM Product2];
        List <Sales_Org__c> salesOrganizationList = [SELECT Id,Name,SalesOrg__c FROM Sales_Org__c];
        List <NB2B_StockCallOut.NB2B_StockCallOutResponse> response;
        

        

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, multimock);
        NB2B_StockCallOutManager manager = new NB2B_StockCallOutManager(productList[0].StockKeepingUnit, salesOrganizationList[0].SalesOrg__c);
        response=manager.getCallout();
        system.debug('pasa por aqui');
        system.debug('response'+response);
        /*System.assertEquals(27189.000, response.availstk);
        System.assertEquals('FERROKER ALUMINIO 44X66(A)', response.name);
        System.assertEquals('000000000100026606', response.product);
        System.assertEquals('502', response.salesorg);
        System.assertEquals(44863.000, response.totalstk);
        System.assertEquals('PZS', response.umb);
        System.assertEquals('PZS', response.umbEn);*/
        Test.stopTest();

  }
    @isTest public static void testWrapper() {
        NB2B_StockCallOutResponseWrapper responWrapper = new NB2B_StockCallOutResponseWrapper(0, 'Test', 'Test', 'Test', 0, 'Test', 'Test');
    }
    
    @isTest public static void testCalloutError() {
        List <Product2> productList = [SELECT Id,Name,StockKeepingUnit FROM Product2];
        List <Sales_Org__c> salesOrganizationList = [SELECT Id,Name,SalesOrg__c FROM Sales_Org__c];
        List <NB2B_StockCallOut.NB2B_StockCallOutResponse> response;

        Test.startTest();
        NB2B_StockCallOutManager manager = new NB2B_StockCallOutManager(productList[0].StockKeepingUnit, salesOrganizationList[0].SalesOrg__c);
        response=manager.getCallout();
        Test.stopTest();

  }

}