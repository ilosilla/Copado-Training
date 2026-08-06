@IsTest public class PEVSAPInvoicesTriggerHandlerTest {
    @testSetup private static void testSetup()  {
        Case c = DataFactoryCase.createCollections(1)[0];
        c.SAPOrderNumber__c = '001231231';
        c.SAPDeliveryNumber__c = '008123123';
        update c;
    }

    @isTest private static void test002() {
        SAP_SD_Invoices__e e = new SAP_SD_Invoices__e();
        e.Action__c = 'CREATE';
        e.DeliveryNumber__c = '008123123';
        e.OrderNumber__c = '001231231';
        e.InvoiceNumber__c = '0999999999';
        e.IsCollection__c = true;
        e.IsCredit__c = true;
        e.IsReversal__c = false;
        e.SalesOrg__c = '502';
        
        // Publish test event
        Test.startTest();        
        Database.SaveResult sr = EventBus.publish(e);            
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess(), JSON.serialize(sr.errors));

        Case c = [select Id, Status, SAPCreditNote__c, SAPDeliveryStatus__c from Case][0] ;
        Assert.areEqual('0999999999', c.SAPCreditNote__c, 'Credit Note does not match');            
    }    

}