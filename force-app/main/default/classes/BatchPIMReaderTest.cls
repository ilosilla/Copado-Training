@isTest public  class BatchPIMReaderTest {
    
    @testSetup private static void testSetup() {
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();
        
        WebStore store = [select Id from WebStore limit 1];        
        Assert.isNotNull(store);

        PORSAStoreSettings__c settings0 = new PORSAStoreSettings__c();
        settings0.StoreId__c = store.Id;
        settings0.Name = 'TEST SETTINGS';
        settings0.EnablePIMSync__c = true;
        insert settings0;

    }

    @isTest private static void testPimReader() {
        Product2 existing = [select Id, StockKeepingUnit from Product2 limit 1];
        Assert.isNotNull(existing);
        String productCode = existing.StockKeepingUnit;
        setMocker(productCode);
        Test.startTest();
        BatchPIMReader.executeBatch();
        Test.stopTest();

        PIMProduct__c[] pims = [select Id, StockKeepingUnit__c from PIMProduct__c];
        Assert.isTrue(pims.size() > 0, 'There should be at least a product in tghe PIM object');
    }
    
    private static void setMocker(String productCode) {        
        String json = '{"status":"success","date":"2025-10-02 10:53:29","data":[{"code":"' + productCode + '","type":"Baldosas Cerámicas","typeCode":1,"typology":"CERAMICA","typology_code":"012","description":"BOTTEGA CALIZA ANT.(20MM) 120X120(A)",'
                    + '"standardDescription":"BOTTEGA CALIZA ANT.","standardFormat":"(2CM) 120X120CM","standardFormatUSA":"(101/128\\") 47 31/128\\"X47 31/128\\"","aproximatedFormatUSA":null,"brand":"P","status":"Z1",'
                    + '"priceGroup":"390","markets":["AUS","ES","FRA","INT","MEX","PT","UK","USA"],"url":"https://productfinder.porcelanosagrupo.com/en/ceramic_tiles/bottega_caliza_ant_20mm_120x120.html","brandUrl":null,'
                    + '"imagen":"https://productfinder.porcelanosagrupo.com/resources/imgcom/high/100349692.jpg","attributes":[{"code":"PESONETO","id":582,"materialSapCode":"100349692","description":"NET WEIGHT","type":"N",'
                    + '"value":"1108.83","unit":"LB/SQF","normative":"","rawValue":46.726176,"informative":false},{"code":"PESOBRUTO","id":776,"materialSapCode":"100349692","description":"GROSS WEIGHT","type":"N","value":"1150.44",'
                    + '"unit":"LB/SQF","normative":"","rawValue":48.479536,"informative":false},{"code":"GROSOR","id":196,"materialSapCode":"100349692","description":"THICKNESS","type":"N","value":"13/16\\"","unit":"approx","normative":"",'
                    + '"rawValue":20,"informative":true},{"code":"LARGO_NOM","id":110,"materialSapCode":"100349692","description":"LENGTH","type":"N","value":"47 1/4\\"","unit":"approx","normative":"","rawValue":1200,"informative":false},'
                    + '{"code":"ANCHO_NOM","id":109,"materialSapCode":"100349692","description":"WIDTH","type":"N","value":"47 1/4\\"","unit":"approx","normative":"","rawValue":1200,"informative":false},{"code":"RELIEVE","id":104,'
                    + '"materialSapCode":"100349692","description":"RELIEF","type":"B","value":false,"unit":"-","normative":null,"rawValue":0,"informative":true},{"code":"RECTIFICADO","id":103,"materialSapCode":"100349692","description":"RECTIFIED",'
                    + '"type":"B","value":true,"unit":"-","normative":null,"rawValue":1,"informative":true},{"code":"FAMILIA","id":199,"materialSapCode":"100349692","description":"FAMILY","type":"C","value":"BOTTEGA","unit":"-",'
                    + '"normative":"","rawValue":"BOTTEGA","informative":true},{"code":"SITUACIONEMPRESA","id":724,"materialSapCode":"100349692","description":"STATUS","type":"C","value":"ACTIVE","unit":"-","normative":"","rawValue":"ACTIVO",'
                    + '"informative":false},{"code":"APLICACION","id":758,"materialSapCode":"100349692","description":"INSTALLATION","type":"C","value":"FLOOR TILES","unit":"-","normative":"","rawValue":"PAVIMENTO","informative":false},'
                    + '{"code":"CLASCOMERCIAL","id":1243,"materialSapCode":"100349692","description":"PRODUCT TYPE - A","type":"C","value":"PORCELAIN","unit":"-","normative":"","rawValue":"PORCELANICO","informative":true},{"code":"ACABADO2",'
                    + '"id":101,"materialSapCode":"100349692","description":"FINISH","type":"C","value":"MATTE","unit":"-","normative":"","rawValue":"MATE","informative":true},{"code":"ACABADO1","id":100,"materialSapCode":"100349692",'
                    + '"description":"FINISH","type":"C","value":"NON-SLIP","unit":"-","normative":"","rawValue":"ANTIDESLIZANTE","informative":true},{"code":"ASPECTO","id":3,"materialSapCode":"100349692","description":"ASPECT","type":"C",'
                    + '"value":"CONCRETE EFFECT","unit":"-","normative":"","rawValue":"CEMENTO","informative":true},{"code":"USO","id":2,"materialSapCode":"100349692","description":"USE","type":"C","value":"INTENSE-EXTERNAL ACCESS",'
                    + '"unit":"-","normative":"","rawValue":"INTENSO-ACCESO EXTERIOR","informative":true},{"code":"UBICACION","id":1,"materialSapCode":"100349692","description":"LOCATION","type":"C","value":"EXTERNAL FLOOR","unit":"-",'
                    + '"normative":"","rawValue":"SUELO EXTERIOR","informative":true},{"code":"TAMANYO","id":5,"materialSapCode":"100349692","description":"SIZE","type":"C","value":"SQUARED, 70-130 CM","unit":"approx","normative":"",'
                    + '"rawValue":"CUAD. [70CM,130CM]","informative":false},{"code":"TIPOPRODUCTO","id":200,"materialSapCode":"100349692","description":"PRODUCT TYPE","type":"C","value":"BASE","unit":"approx","normative":"",'
                    + '"rawValue":"BASE","informative":false},{"code":"MATJUNTA_ZONAHUMEDA","id":2094,"materialSapCode":"100349692","description":"RECOMMENDED JOINT (WET AREA)","type":"C","value":["100331788","100275760"],"unit":"-",'
                    + '"normative":null,"rawValue":["{JUN}100331788","{JUN}100275760"],"informative":false},{"code":"DESTONIFICADO","id":102,"materialSapCode":"100349692","description":"TONE VARIATIONS","type":"C","value":"V3","unit":"-",'
                    + '"normative":"","rawValue":"V3","informative":true},{"code":"COLORCOMERCIAL","id":1867,"materialSapCode":"100349692","description":"COLOUR","type":"C","value":"BOTTEGA CALIZA","unit":"-","normative":"","rawValue":"BOTTEGA CALIZA",'
                    + '"informative":true},{"code":"MATADHESIVO_ZONAHUMEDA","id":2080,"materialSapCode":"100349692","description":"RECOMMENDED ADHESIVE (WET AREA)","type":"C","value":["100142757"],"unit":"-","normative":null,'
                    + '"rawValue":"{ADH}100142757","informative":false},{"code":"MATJUNTA","id":1049,"materialSapCode":"100349692","description":"RECOMMENDED JOINT","type":"C","value":["100275760","100331788"],"unit":"-","normative":null,'
                    + '"rawValue":["{JUN}100275760","{JUN}100331788"],"informative":false},{"code":"FORMATO","id":195,"materialSapCode":"100349692","description":"SIZE","type":"C","value":"(2CM) 120X120CM","unit":"approx","normative":"",'
                    + '"rawValue":"(2CM) 120X120CM","informative":true}]}],"message":"OK"}';
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = json;
        Test.setMock(HttpCalloutMock.class, mocker);
    }

}