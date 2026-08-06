@isTest public with sharing class PEVSAPDeliveryTriggerHandlerTest {

    @testSetup public static void testSetup()  {
        Case c = DataFactoryCase.createCollections(1)[0];
        c.SAPOrderNumber__c = '001231231';
        update c;
        Order o = DataFactoryOrder.createOrders(1)[0];
        o.Sap_Id__c = '901';
        update o;
    }

    @isTest private static void test001() {
        SAP_SD_Delivery__e e = new SAP_SD_Delivery__e();
        e.Action__c = 'CREATE';
        e.DeliveryNumber__c = '008123123';
        e.OrderNumber__c = '001231231';
        e.Status__c = 'NA';
        e.GoodsPosted__c = false;
        e.SalesOrg__c = '502';
        e.isCollection__c = true;
        e.isSample__c = false;
        
        // Publish test event
        Test.startTest();        
        Database.SaveResult sr = EventBus.publish(e);            
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess(), JSON.serialize(sr.errors));

        Case c = [select Id, Status, SAPDeliveryNumber__c, SAPDeliveryStatus__c from Case][0] ;
        Assert.areEqual('008123123', c.SAPDeliveryNumber__c, 'Delivery Note does not match');
        
    }

    @isTest private static void test002() {
        SAP_SD_Delivery__e e = new SAP_SD_Delivery__e();
        e.Action__c = 'CREATE';
        e.DeliveryNumber__c = '008123123';
        e.OrderNumber__c = '001231231';
        e.Status__c = 'NA';
        e.GoodsPosted__c = false;
        e.SalesOrg__c = '502';
        e.data__c = 'Malformed JSON';
        e.isCollection__c = true;
        e.isSample__c = false;
        
        // Publish test event
        Test.startTest();        
        Database.SaveResult sr = EventBus.publish(e);            
        Test.stopTest();

        // Testeamos para que pase por el inner catch
        System.assertEquals(true, sr.isSuccess(), JSON.serialize(sr.errors));
        
    }

    @isTest public static void testSamples() {
        SAP_SD_Delivery__e e = new SAP_SD_Delivery__e();
        e.Action__c = 'CREATE';
        e.DeliveryNumber__c = '008123123';
        e.OrderNumber__c = '901';
        e.Status__c = 'NA';
        e.GoodsPosted__c = false;
        e.SalesOrg__c = '502';
        e.isCollection__c = false;
        e.isSample__c = true;
        
        // Publish test event
        Test.startTest();        
        Database.SaveResult sr = EventBus.publish(e);            
        Test.stopTest();
        System.assertEquals(true, sr.isSuccess(), JSON.serialize(sr.errors));

        Order o = [select Id, SAPDeliveryNumber__c, NB2B_DeliveryStatus__c from Order][0] ;
        Assert.areEqual('008123123', o.SAPDeliveryNumber__c, 'Delivery Note does not match');
        
    }


    
}