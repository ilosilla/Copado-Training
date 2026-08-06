@isTest public class BatchPIMImageReaderTest {

    static String productCode = '100202546';
    
    @testSetup private static void testSetup() {  
        
        SystemSettings.getSystemSettings();
        DataFactoryProduct.ignoreStandardPriceBook = true;
        Product2 p = DataFactoryProduct.createProducts()[0];
        p.StockKeepingUnit = productCode;
        // update p;

        PIMProduct__c pim = new PIMProduct__c();
        pim.StockKeepingUnit__c = productCode;
        pim.Product__c = p.Id;
        pim.Name = p.Name;
        insert pim;
    }

    @isTest private static void testPimReader() {
        setMocker(false);
        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        PIMProductImage__c[] images = [select Id from PIMProductImage__c];
        Assert.isTrue(images.size() > 0, 'There should be at least a image in the PIM Image object');
    }

    @isTest private static void testPimReaderWithError() {
        setMocker(true);
        Test.startTest();
        BatchPIMImageReader.executeBatch();
        Test.stopTest();

        PIMProductImage__c[] images = [select Id from PIMProductImage__c];
        Assert.isTrue(images.size() == 0, 'There should be no images in the PIM Image object');
    }

    @isTest private static void testBatchWithBlankSKU() {
        PIMProduct__c pim = new PIMProduct__c();
        pim.StockKeepingUnit__c = '';
        pim.Name = 'BLANK SKU PRODUCT';
        insert pim;

        setMocker(false);
        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        // El producto sin SKU no debe generar imágenes
        PIMProductImage__c[] images = [SELECT Id FROM PIMProductImage__c WHERE StockKeepingUnit__c = ''];
        Assert.areEqual(0, images.size(), 'No images should be created for blank SKU products');
    }

    @isTest private static void testDuplicateImageKey() {
        String json = '[{"id":"' + productCode + '","numImages":2,"images":['
            + '{"is_Favorite":false,"id":999,"width":100,"height":100,"imageType":"CATALOG",'
            + '"name":"TEST IMG","page_url":"http://test.com","element_url":"http://test.com","download_url":"http://test.com",'
            + '"square":"","thumb":"","2small":"","xsmall":"","small":"","medium":"","large":"","xlarge":"","xxlarge":""},'
            + '{"is_Favorite":true,"id":999,"width":200,"height":200,"imageType":"SETTING",'
            + '"name":"TEST IMG DUPE","page_url":"http://test2.com","element_url":"http://test2.com","download_url":"http://test2.com",'
            + '"square":"","thumb":"","2small":"","xsmall":"","small":"","medium":"","large":"","xlarge":"","xxlarge":""}'
            + ']}]';

        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = json;
        mocker.testError = false;
        Test.setMock(HttpCalloutMock.class, mocker);

        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        // Solo debe insertarse una imagen — el duplicado se filtra
        PIMProductImage__c[] images = [SELECT Id FROM PIMProductImage__c WHERE StockKeepingUnit__c = :productCode];
        Assert.areEqual(1, images.size(), 'Duplicate image (same SKU + imageId) should be filtered out');
    }

    
    @isTest private static void testProductWithNoImages() {
        String json = '[{"id":"' + productCode + '","numImages":0,"images":[]}]';

        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = json;
        mocker.testError = false;
        Test.setMock(HttpCalloutMock.class, mocker);

        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        PIMProductImage__c[] images = [SELECT Id FROM PIMProductImage__c];
        Assert.areEqual(0, images.size(), 'No images should be created when PIWIGO returns empty images array');
    }

    @isTest private static void testDeleteWithEmptySKUSet() {
        // Borrar el PIMProduct del setup y dejar solo uno con SKU en blanco
        // para que allProductSkusInScope quede vacío y se ejecute el early return
        delete [SELECT Id FROM PIMProduct__c];
        PIMProduct__c pim = new PIMProduct__c();
        pim.StockKeepingUnit__c = '';
        pim.Name = 'BLANK SKU';
        insert pim;

        setMocker(false);
        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM PIMProductImage__c], 'No images should be created when all SKUs are blank');
    }

    @isTest private static void testGetIntegerAndBooleanEdgeCases() {
        // width como Long (> Integer.MAX_VALUE), height como Decimal, is_Favorite como String
        String json = '[{"id":"' + productCode + '","numImages":1,"images":['
            + '{"is_Favorite":"true","id":1,"width":100,"height":100.5,"imageType":"CATALOG",'
            + '"name":"TEST EDGE","page_url":"http://test.com","element_url":"http://test.com","download_url":"http://test.com",'
            + '"square":"","thumb":"","2small":"","xsmall":"","small":"","medium":"","large":"","xlarge":"","xxlarge":""}'
            + ']}]';

        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = json;
        mocker.testError = false;
        Test.setMock(HttpCalloutMock.class, mocker);

        Test.startTest();
        BatchPIMImageReader.executeBatch(true);
        Test.stopTest();

        PIMProductImage__c[] images = [SELECT Id, IsFavorite__c FROM PIMProductImage__c WHERE StockKeepingUnit__c = :productCode];
        Assert.areEqual(1, images.size(), 'One image should be created');
        Assert.isTrue(images[0].IsFavorite__c, 'IsFavorite should be true when parsed from string');
    }

    private static void setMocker(Boolean withError) {        
        String json = '[{"id":"100202546","numImages":6,"images":[{"is_Favorite":false,"id":137659,"width":1417,"height":531,"hit":9'
                    + ',"file":"100202546_ImgTec.jpg","name":"CAPRI STONE 45X120 (A)","date_Creation":"2021-04-16 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/137659"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=137659&part=e&download","imageType":"CATALOG"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Articulos/En Catalogo/Baldosas Ceramicas/Capri/100202546_ImgTec.jpg"}'
                    + ',{"is_Favorite":false,"id":134736,"width":4000,"height":3000,"hit":32'
                    + ',"file":"P.AMB.000470.jpg","name":"P.AMB.000470 - REVESTIMIENTO RECTIFICADO CAPRI","date_Creation":"2021-04-21 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/134736"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=134736&part=e&download","imageType":"SETTING"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000470-xx.jpg"}'
                    + ',{"is_Favorite":false,"id":134737,"width":4000,"height":3000,"hit":33'
                    + ',"file":"P.AMB.000471.jpg","name":"P.AMB.000471 - REVESTIMIENTO RECTIFICADO CAPRI","date_Creation":"2021-04-21 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/134737"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=134737&part=e&download","imageType":"SETTING"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000471-xx.jpg"}'
                    + ',{"is_Favorite":false,"id":134738,"width":3000,"height":4000,"hit":29'
                    + ',"file":"P.AMB.000472.jpg","name":"P.AMB.000472 - REVESTIMIENTO RECTIFICADO CAPRI","date_Creation":"2021-04-21 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/134738"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=134738&part=e&download","imageType":"SETTING"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000472-xx.jpg"}'
                    + ',{"is_Favorite":false,"id":134811,"width":4000,"height":3000,"hit":28'
                    + ',"file":"P.AMB.000890.jpg","name":"P.AMB.000890 - REVESTIMIENTO RECTIFICADO CAPRI","date_Creation":"2021-04-21 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/134811"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=134811&part=e&download","imageType":"SETTING"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.000890-xx.jpg"}'
                    + ',{"is_Favorite":false,"id":134989,"width":3000,"height":4000,"hit":25'
                    + ',"file":"P.AMB.001298.jpg","name":"P.AMB.001298 - REVESTIMIENTO RECTIFICADO CAPRI","date_Creation":"2021-04-21 00:00:00"'
                    + ',"page_url":"https://dmagenes.porcelanosagrupo.com/picture.php?/134989"'
                    + ',"element_url":"https://dmagenes.porcelanosagrupo.com/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298.jpg"'
                    + ',"download_url":"https://dmagenes.porcelanosagrupo.com/action.php?id=134989&part=e&download","imageType":"SETTING"'
                    + ',"square":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-sq.jpg"'
                    + ',"thumb":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-th.jpg"'
                    + ',"2small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-2s.jpg"'
                    + ',"xsmall":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-xs.jpg"'
                    + ',"small":"https://dmagenes.porcelanosagrupo.com/i.php?/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-sm.jpg"'
                    + ',"medium":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-me.jpg"'
                    + ',"large":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-la.jpg"'
                    + ',"xlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-xl.jpg"'
                    + ',"xxlarge":"https://dmagenes.porcelanosagrupo.com/_data/i/galleries/Porcelanosa/Ambientes/Activos/P.AMB.001298-xx.jpg"}]}]}]';
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        if (!withError) {
            mocker.customResponse = json;
        }
        mocker.testError = withError;
        Test.setMock(HttpCalloutMock.class, mocker);
    }

}