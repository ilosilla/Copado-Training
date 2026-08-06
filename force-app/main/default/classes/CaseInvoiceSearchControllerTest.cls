@IsTest(IsParallel=false) public class CaseInvoiceSearchControllerTest {

    @testSetup private static void testSetup() {
        DataFactoryAccount.createBusinessAccounts(1);
        DataFactoryProduct.ignoreStandardPriceBook = true;
        DataFactoryProduct.createProducts();
        DataFactoryCase.createCollections(1);
    }

    @isTest private static void test001() {        
        Case c = [select Id from Case limit 1];
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        

        Test.startTest();
        CaseInvoiceSearchController.InvoiceDTO dto = CaseInvoiceSearchController.readInvoiceData('123', c.Id);
        Test.stopTest();
        Assert.isNotNull(dto, 'An object should have been received');
    }

    @isTest private static void test001a() {      
        DataFactoryOrganization.createData();
        User usr = [select Id, Sales_Org__c, Distribution_channel__c, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c from User where Id = :UserInfo.getUserId() limit 1];
        usr.Sales_Org__c = OrganizationCommons.ORG_PIDF;
        usr.Distribution_channel__c = '60';
        usr.Default_Sales_Organization__c = usr.Sales_Org__c;
        usr.Distribution_channel_default__c = usr.Distribution_channel__c;
        usr.Sales_Office__c = '3035';
        update usr;
        Case c = [select Id from Case limit 1];
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        

        Boolean exc = false;
        Test.startTest();
        try {
            CaseInvoiceSearchController.readInvoiceData('123', c.Id);
        } catch (Exception ex) {
            exc = true;
        }
        Test.stopTest();
        Assert.isTrue(exc, 'An exception should have been received');
    }


    @isTest private static void test002() {        
        String rtid = CaseInvoiceSearchController.readInitialValues();
        Assert.isNotNull(rtid, 'The record type should not be null');
    }

} // class