@isTest
private class SAPOrdersHelperTest {

    @testSetup static void makeData() {
        DataFactoryOrganization.createData();
        DataFactoryOrder.createOrders(5);
    }

    @isTest static void testValidateOrderForSAP() {
        Order o = (Order) new OrdersSelector().selectAll()[0];
        o.SalesOrg__c = '502';
        o.Distribution_channel__c = '70';
        o.Status = OrdersDomain.STATUS_ACTIVATED;
        
        Sales_Org__c sa = new SalesOrgsSelector().selectBySAPId(new Set<String>{o.SalesOrg__c})[0];
        o.CurrencyIsoCode = sa.CurrencyIsoCode;

        Account acc = new Account();
        acc.Id = o.AccountId;
        acc.SAP_Id__c = '123321';
        update acc;

        Test.startTest();
        List<String> errors = SAPOrdersHelper.validateOrderForSAP(o, sa);
        Assert.areEqual(0, errors.size(), 'No errors expected');

        o.Version__c = OrdersDomain.VERSION2;
        errors = SAPOrdersHelper.validateOrderForSAP(o, sa);
        Assert.areEqual(0, errors.size(), 'No errors expected');
        Test.stopTest();

    }

    @isTest static void testValidateOrderForSAP_2() {
        Order o = (Order) new OrdersSelector().selectAll()[0];
        o.Version__c = OrdersDomain.VERSION2;
        o.SalesOrg__c = null;
        o.Distribution_channel__c = null;
        o.Status = OrdersDomain.STATUS_DRAFT;
        
        Sales_Org__c sa = new SalesOrgsSelector().selectBySAPId(new Set<String>{'502'})[0];
        o.CurrencyIsoCode = 'CAD';

        Account acc = new Account();
        acc.Id = o.AccountId;
        acc.SAP_Id__c = '';
        update acc;

        Test.startTest();
        List<String> errors = SAPOrdersHelper.validateOrderForSAP(o, sa);
        Assert.areNotEqual(0, errors.size(), 'Errors expected');
        Test.stopTest();
    }
}