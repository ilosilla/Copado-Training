@SuppressWarnings('PMD')
@isTest 
public class NB2B_OrderControllerTest {
    @TestSetup
	static public void setupData(){
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();

        List<Account> acclist = new List<Account>();
        Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        acclist.add(acc);

        Account acc2 = new Account();
        acc2 = Account_TestDataFactory.createCustomer();
        acclist.add(acc2);

        insert acclist;  

        Product2 pro = new Product2 (
	    		Name = 'TestProduct1',
	    		IsActive = true
	    	);
        insert pro;  
    }

    @isTest 
    public static void beforeInsertTest() {
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
    	multimock.setStaticResource('callout:SAP/api/customers/ping', 'mockTest');
        multimock.setStaticResource('callout:SAP/porsa/orders/b2b', 'NB2B_OrderMock');        
    	multimock.setStatusCode(200);
    	multimock.setHeader('x-csrf-token', 'testToken');
        multimock.setHeader('set-cookie', 'testCookie');
        multimock.setHeader('Content-Type', 'application/json');

        List<Account> account = [Select Id from Account];
        List<Product2> proList = [Select Id from Product2];
        List<Order> listOrders = new List<Order>();

        Order ord = new Order(
            AccountId = account[0].Id, 
            Status = 'Draft', 
            EffectiveDate = Date.today(),
            Sap_Id__c = '1234567'
        );

        listOrders.add(ord);

        Order ord2 = new Order(
            AccountId = account[0].Id, 
            recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('NBK_rt_samples').getRecordTypeId(),
            Status = 'Draft', 
            EffectiveDate = Date.today(),
            NB2B_Delivery_Method__c = '1'
        );

        listOrders.add(ord2);
        insert listOrders;

        OrderItem ordIt = new OrderItem(
        	Product2Id = proList[0].Id,
            OrderId = ord.Id
        );

        //List<Opportunity> oppList = [select Id from Opportunity where AccountId =: account[1].Id];
        //delete oppList[0];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multimock);
        NB2B_OrderTransactionHandler.Response result = NB2B_OrderController.saveOrder(ord.Id);
        NB2B_OrderTransactionHandler.Response result2 = NB2B_OrderController.saveOrder(ord2.Id);
        Test.stopTest();
    }

    @isTest 
    public static void test_runSfValidation() {
    	NB2B_OrderTransactionHandler.Response resultRunSfValidation;

        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
    	multimock.setStaticResource('callout:SAP/api/customers/ping', 'mockTest');
        multimock.setStaticResource('callout:SAP/porsa/orders/b2b', 'NB2B_OrderMock');        
    	multimock.setStatusCode(200);
    	multimock.setHeader('x-csrf-token', 'testToken');
        multimock.setHeader('set-cookie', 'testCookie');
        multimock.setHeader('Content-Type', 'application/json');
        Test.startTest();

		String orderWrapperJSON = '{"order_id": "DES-12009159",  "opportunity_id": "","created_at": "2021-12-30 19:00","state": "new",  "reference": "New building", "payment_method": "",  "currency": "GBP", "carrier_code": "tablerate",  "shipping_method": "bestway", "store_pickup": false,"shipping_incl_tax": "0.0000","shipping_tax_amount": "0.0000","total_incl_tax": "2408.5000","total_tax_amount": "401.4200","discount": "0.0000", "sales_organization": "502",  "sales_office": "2552","distribution_channel": "60","delivery_date": "2021-07-10","coupon_code": null,"delivery_instructions": "These are the delivery instructions","comments": "This is a comment","customer": { "customer_id": "76328", "salesforce_id": "","sap_id": "0001087111" },"order_lines_number": "3","order_lines": [{"line_number": 1,"order_item_id": "54711","product_sku": "100124185","is_sample": false,"quantity": 6,"quantity_unit": "BOX","original_price": "7.55","price_unit": "BOX","row_total_incl_tax": "54.81","row_total_tax_amount": "9.51","discount": "0.0000"}]}';

        resultRunSfValidation = NB2B_OrderTransactionHandler.runSfValidation(orderWrapperJSON);

        Test.stopTest();

        System.debug('resultRunSfValidation: ' + resultRunSfValidation);
    }
}