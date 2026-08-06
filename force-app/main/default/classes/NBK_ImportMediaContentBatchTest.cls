/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-27-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class NBK_ImportMediaContentBatchTest {
    @TestSetup
    static void setupData(){
        //NBK_setupTestData.generateProduct();
        Product2 product = new Product2();
        product.Name = 'Producto de prueba';
        product.ExternalId = '100000833';
        product.StockKeepingUnit = '123456789';
        //product.Material__c ='123456789';
        product.ProductCode = '123456789';
        product.URL_Photo_1__c='http://google.com';
		insert product;
    }

    @IsTest
    static void importMediaContentOk(){
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/sobjects/ContentVersion', 'B2BContentVersion');
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/commerce/management/webstores/0ZE5r000000LGNuGAO/product-import', 'B2BJobOk');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Test.startTest();
            NBK_ImportMediaContentBatch batch = new NBK_ImportMediaContentBatch();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    @IsTest
    static void importMediaContentKO1(){
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/sobjects/ContentVersion', 'B2BContentVersion');
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/commerce/management/webstores/0ZE5r000000LGNuGAO/product-import', 'B2BJobOk');
        multimock.setStatusCode(400);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Test.startTest();
            NBK_ImportMediaContentBatch batch = new NBK_ImportMediaContentBatch();
            Database.executeBatch(batch);
        Test.stopTest();
    }

    @IsTest
    static void importMediaContentKO2(){
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/sobjects/ContentVersion', 'B2BContentVersion');
        multimock.setStaticResource('callout:Porcelanosa_B2B'+'/services/data/v54.0/commerce/management/webstores/0ZE5r000000LGNuGAO/product-import', 'B2BJobKO');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Test.startTest();
            NBK_ImportMediaContentBatch batch = new NBK_ImportMediaContentBatch();
            Database.executeBatch(batch);
        Test.stopTest();
    }
}