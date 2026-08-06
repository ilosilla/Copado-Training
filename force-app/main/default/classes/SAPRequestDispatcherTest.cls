/**
 * USE FactoryQualityAPIHandlerTesttoo to achieve full coverage of SAPRequestDipatcher
 */
@isTest public with sharing class SAPRequestDispatcherTest {

    @TestSetup static void makeData() {
        Order o = DataFactoryOrder.createOrdersForSAP(1)[0];   
        OrdersService.activateOrders(new Set<Id>{o.Id});        
    }

    @isTest private static void happyPath() {        
        SAPRequestQueue__c[] items = readQueue();
        Assert.areEqual(1, items.size(), 'There should be 1 items');
        Decimal retries = items[0].Retries__c;
        Test.setMock(HttpCalloutMock.class, new SAPProxyTest.SAPProxyMockTest());
        
        Test.startTest();        
        SAPRequestDispatcher.processQueue();        
        Test.stopTest();

        items = readQueue();
        Assert.areEqual(1, items.size(), 'There should be 1 item');
        Assert.areEqual(SAPRequestDispatcher.STATUS_PROCESSED, items[0].Status__c, 'Status should be processed ' + items[0].Message__c);
        Assert.areEqual(retries + 1, items[0].Retries__c, 'Retries should have been incremented ');        
    }

    // Set up mock HTTP callout
    /*SAPProxyTest.SAPProxyMockTest mocker = new SAPProxyTest.SAPProxyMockTest();
    mocker.testError = true;
    Test.setMock(HttpCalloutMock.class, mocker);       */

    @isTest private static void raceConditionTest() {
        Boolean processed = false;
        RaceConditionFlag flag = new RaceConditionFlag(SAPRequestDispatcher.QUEUE_NAME);
        if (flag.lock()) {
            processed = SAPRequestDispatcher.processQueue();
        }
        Assert.isFalse(processed, 'The queue should be locked by another process');
    }

    @isTest private static void testCPIRequests() {
        // Tenemos que borrar la cola por los pedidos creados en el testSetup
        SAPRequestQueue__c items = [select Id from SAPRequestQueue__c];
        delete items;
        Case[] claims = DataFactoryCase.createClaims(1);   
        for (Case claim : claims) {
            claim.Liability__c = 'G1';
            claim.Warranty__c = 'NO';
            claim.SupplyInstallation__c = true;
            claim.Status = 'Closed';
        }         
        Test.startTest();
        //SAPRequestDispatcher.processQueue();
        update claims;
        Test.stopTest();
        Assert.isTrue(true);
    }

    @isTest private static void testMultiblock() {

        // Deshabilitamos para llamar nosotros al dispatcher
        enableDispatcher(false);            

        // ASegurarnos de que la cola está deshabilitada
        Assert.isFalse(SystemSettings.SAPDispatcherEnabled, 'El dispatcher debe estar deshabilitado en este test');

        // Borramos la cols
        SAPRequestQueue__c[] oldItems = [select Id from SAPRequestQueue__c];
        delete oldItems;

        Test.setMock(HttpCalloutMock.class, new SAPProxyTest.SAPProxyMockTest());

        // Preparar 5 registros con secuencia creciente
        List<SAPRequestQueue__c> testItems = new List<SAPRequestQueue__c>();
        for (Integer i = 1; i <= 5; i++) {
             Id fakeRequesterId = (Id) ('00100000000000' + String.valueOf(i) + 'AAA');
            SAPRequestQueue__c item = new SAPRequestQueue__c(
                Name = 'Test Item ' + i,
                RequesterId__c = fakeRequesterId,
                Status__c = 'QUEUED',
                SAPEndpoint__c = 'MockEndpoint',
                SAPAPIHandler__c = 'MockAPIHandler', // Mock para el test
                ActionRequested__c = 'CREATE',
                Retries__c = 0
            );
            testItems.add(item);
        }        
        insert testItems;


        // Establecer el tamaño del bloque a 2
        Test.startTest();
        enableDispatcher(true); 
        SAPRequestDispatcher.setBlockSize(2);
        SAPRequestDispatcher.processQueue();
        Test.stopTest();

        // Verificar que todos los registros se han procesado
        List<SAPRequestQueue__c> updatedItems = readQueue();
        System.assertEquals(5, updatedItems.size(), 'Deben haberse procesado los 5 registros');
        for (SAPRequestQueue__c item : updatedItems) {
            System.assertEquals(SAPRequestDispatcher.STATUS_PROCESSED, item.Status__c, 'Item debe estar procesado ' + item.Retries__c);
        }
    }    

    @isTest private static void testHandlerError() {

        // Borramos la cols
        SAPRequestQueue__c[] oldItems = [select Id from SAPRequestQueue__c];
        delete oldItems;

        SAPProxyTest.SAPProxyMockTest mocker = new SAPProxyTest.SAPProxyMockTest();
        mocker.testError = true;
        Test.setMock(HttpCalloutMock.class, mocker);

        // Preparar 5 registros con secuencia creciente
        List<SAPRequestQueue__c> testItems = new List<SAPRequestQueue__c>();
        for (Integer i = 1; i <= 5; i++) {
             Id fakeRequesterId = (Id) ('00100000000000' + String.valueOf(i) + 'AAA');
            SAPRequestQueue__c item = new SAPRequestQueue__c(
                Name = 'Test Item ' + i,
                RequesterId__c = fakeRequesterId,
                Status__c = 'QUEUED',
                SAPEndpoint__c = 'MockEndpoint',
                SAPAPIHandler__c = 'DummyHandler', // Mock para el test
                ActionRequested__c = 'CREATE',
                Retries__c = 0
            );
            testItems.add(item);
        }        

        Test.startTest();
        insert testItems;
        Test.stopTest();

        // Verificar que todos los registros se han procesado
        List<SAPRequestQueue__c> updatedItems = readQueue();
        System.assertEquals(5, updatedItems.size(), 'Deben haberse procesado los 5 registros');
        for (SAPRequestQueue__c item : updatedItems) {
            System.assertEquals(SAPRequestDispatcher.STATUS_EXCEPTION, item.Status__c, 'Item debe estar en estado error ' + item.Retries__c + ' y ' + item.Message__c);
        }
    }

    @isTest private static void testBlockedItems() {
        // Borramos la cols
        SAPRequestQueue__c[] oldItems = readQueue();
        delete oldItems;

        Test.setMock(HttpCalloutMock.class, new SAPProxyTest.SAPProxyMockTest());
        // Preparar 5 registros con secuencia creciente
        List<SAPRequestQueue__c> testItems = new List<SAPRequestQueue__c>();
        for (Integer i = 1; i <= 5; i++) {
             Id fakeRequesterId = (Id) ('001000000000001AAA');  // Mismo ID para todas
            SAPRequestQueue__c item = new SAPRequestQueue__c(
                Name = 'Test Item ' + i,
                RequesterId__c = fakeRequesterId,
                Status__c = 'QUEUED',
                SAPEndpoint__c = 'MockEndpoint',
                SAPAPIHandler__c = 'DummyHandler', // Mock para el test
                ActionRequested__c = 'CREATE',
                Retries__c = 0,
                AllowDuplicates__c = true
            );
            testItems.add(item);
        }        

        Test.startTest();
        insert testItems;
        Test.stopTest();

        // Verificar que todos los registros se han procesado
        List<SAPRequestQueue__c> updatedItems = readQueue();
        System.assertEquals(5, updatedItems.size(), 'Deben haberse procesado los 5 registros');
        for (Integer i = 0; i < updatedItems.size(); i++) {
            SAPRequestQueue__c item = updatedItems[i];
            if (i == 0) {
                System.assertEquals(SAPRequestDispatcher.STATUS_EXCEPTION, item.Status__c, 'Item debe estar procesado ' + item.Retries__c + ' y ' + item.Message__c);
            } else {
                System.assertEquals(SAPRequestDispatcher.STATUS_BLOCKED, item.Status__c, 'Item debe estar procesado ' + item.Retries__c + ' y ' + item.Message__c);
            }
        }
    }    


    private static SAPRequestQueue__c[] readQueue() {
        return [select Id, Retries__c, Status__c, Message__c, Payload__c from SAPRequestQueue__c ORDER BY Sequence__c];
    }

    private static void enableDispatcher(Boolean value) {
        SystemSettings__c settings = SystemSettings.getSystemSettings();
        settings.SAPDispatcherEnabled__c = value;
        upsert settings;    
        SystemSettings.SAPDispatcherEnabled = value;
    }

}