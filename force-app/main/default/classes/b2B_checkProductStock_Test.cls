@isTest
public class b2B_checkProductStock_Test {

    @TestSetup
	static public void setupData(){
        
        Sales_Org__c s = new Sales_Org__c (
            Name = 'TestSalesOrg',
            SalesOrg__c = '777'
        );
        insert s;
        
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        insert acc;  
        System.debug('execution : ' + [select id from Execution_Context__mdt ]);
        System.debug('execution : ' + [select Execution_Context__c  from User ]);
        Order ord = new Order(
            AccountId = acc.Id, 
            Status = 'Draft', 
            EffectiveDate = Date.today(),
            Sap_Id__c = '1234567',
            RecordTypeId=Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('NBK_rt_samples').getRecordTypeId()
        );
        insert ord;
        
        Product2 pro = new Product2 (
	    		Name = 'TestProduct1',
	    		IsActive = true, 
                StockKeepingUnit = '1234567',
            	ProductCode = '111111111'
	    	);
        insert pro;
        
        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId  = ord.Id;
        orderItemObj.Product2Id  = pro.Id;
        orderItemObj.ListPrice = 0;
        orderItemObj.UnitPrice = 0;
        orderItemObj.TotalLineAmount = 0;
        orderItemObj.Quantity = 2;
        insert orderItemObj;
    }
    
    @isTest 
    static void test_getProductsByOrder() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<String> products = b2B_checkProductStock.getProductsByOrder(o.id);
    }
    @isTest 
    static void test_getProductsByOrderNull() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<String> products = b2B_checkProductStock.getProductsByOrder(null);
    }
    
    @isTest
    static void test_checkProductStockCallout() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<Product2> productCodeList = [SELECT ProductCode FROM Product2];
        List<String> productCodes = new List<String>(); 
        for(Product2 pro : productCodeList){
            productCodes.add(pro.ProductCode);
        }
        
        List<NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse> response = b2B_checkProductStock.checkProductStockCallout(o.Id, productCodes);
    }
    
    @isTest
    static void test_deleteOrderItemUncheked() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<Product2> productCodeList = [SELECT ProductCode FROM Product2];
        List<String> productCodes = new List<String>(); 
        for(Product2 pro : productCodeList){
            productCodes.add(pro.ProductCode);
        }
        
        String response = b2B_checkProductStock.deleteOrderItemUncheked(o.Id, productCodes);
    }
    @isTest
    static void test_deleteOrderItemUnchekedFail() {
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<Product2> productCodeList = [SELECT ProductCode FROM Product2];
        List<String> productCodes = new List<String>(); 
        Sales_Org__c sales = [Select id from Sales_Org__c Limit 1];
        for(Product2 pro : productCodeList){
            productCodes.add(pro.ProductCode);
        }
        
        String response = b2B_checkProductStock.deleteOrderItemUncheked(sales.Id, productCodes);
    }

    @isTest
    static void test_deleteOrderItemUnchekedCatch() {
        Sales_Org__c sales = [Select id from Sales_Org__c Limit 1];
        
        String response = b2B_checkProductStock.deleteOrderItemUncheked(sales.Id, null);
    }
    
    @isTest
    static void test_activateOrder(){
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
    	multimock.setStaticResource('callout:SAP/api/customers/ping', 'mockTest');
        multimock.setStaticResource('callout:SAP/porsa/orders/b2b', 'NB2B_OrderMock');
    	multimock.setStatusCode(200);
    	multimock.setHeader('x-csrf-token', 'testToken');
        multimock.setHeader('set-cookie', 'testCookie');
        multimock.setHeader('Content-Type', 'application/json');
        Order o = [SELECT Id FROM Order LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multimock);
        String response = b2B_checkProductStock.activateOrder(o.Id);
        Test.stopTest();
    }
    @isTest
    static void test_validateData(){
        Order o = [SELECT Id FROM Order LIMIT 1];
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }
    @isTest
    static void test_validateDataWithDeliveryMethod1(){
        Order o = [SELECT Id, NBK_Warehouse_Address__c, NB2B_Delivery_Method__c, SalesOrg__c, SalesOffice__c FROM Order LIMIT 1];
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = 'test';
        ware.NBK_isWarehouse__c = true;
        ware.NBK_isActive__c = true;
        insert ware;
        o.NBK_Warehouse_Address__c = ware.Id;
        o.NB2B_Delivery_Method__c = '1';
        o.SalesOrg__c = null;
        o.SalesOffice__c = null;
        update o;
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }
    @isTest
    static void test_validateDataWithDeliveryMethod2(){
        Order o = [SELECT Id FROM Order LIMIT 1];
        o.NB2B_Delivery_Method__c = '2';
        update o;
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }
    @isTest
    static void test_validateDataWithDeliveryMethod3(){
        Order o = [SELECT Id FROM Order LIMIT 1];
        o.NB2B_Delivery_Method__c = '3';
        update o;
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }
    @isTest
    static void test_validateDataSalesOrg(){
        Order o = [SELECT Id, SalesOrg__c FROM Order LIMIT 1];
        o.SalesOrg__c = null;
        update o;
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }
    @isTest
    static void test_validateDataSalesOffice(){
        Order o = [SELECT Id, SalesOffice__c FROM Order LIMIT 1];
        o.SalesOffice__c = null;
        update o;
        List<String> response = b2B_checkProductStock.validateData(o.Id);
    }

    @isTest
    static void test_checkOrder(){
        Order o = [SELECT Id FROM Order LIMIT 1];
        Boolean response = b2B_checkProductStock.checkOrder(o.Id);
    }
    @isTest
    static void test_checkOrder2(){
        Sales_Org__c sales = [Select id from Sales_Org__c Limit 1];
        Boolean response = b2B_checkProductStock.checkOrder(sales.Id);
    }
    
}