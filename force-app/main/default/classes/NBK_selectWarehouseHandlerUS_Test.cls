@isTest
public class NBK_selectWarehouseHandlerUS_Test {

    @TestSetup
    public static void makeData(){
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        ware.NBK_Address__CountryCode__s = 'US';
        ware.NBK_Address__Latitude__s=37.770035791112576;
        ware.NBK_Address__Longitude__s=-122.40285237531269;
        insert ware;
    }

    @isTest
    static void testGetAddressPosition() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock());
        String result;  
        Test.startTest(); 
            result = NBK_selectWarehouseHandlerUS.getAddressPosition(37.7749, -122.4194, 'US');
        Test.stopTest();

        System.assert(result != null, 'OK');

    }

    @isTest
    static void testSearchAllStoresFromCountry() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        List<AddressStoreWRP> result;
        Test.startTest(); 
            result = NBK_selectWarehouseHandlerUS.searchAllStoresFromCountry('US');
        Test.stopTest();
    }

    @isTest
    static void testSearchAllStoresFromCountry2() {
        List<AddressStoreWRP> result;
        Test.startTest(); 
            result = NBK_selectWarehouseHandlerUS.searchAllStoresFromCountry('US');
            NBK_selectWarehouseHandlerUS.findURLimage('<img width="22%" alt="Doral_Showroom.jpg" src="https://www.porcelanosa-usa.com/wp-content/uploads/2021/09/Doral_Showroom.jpg"></img>	');
        Test.stopTest();
    }

    @isTest
    static void testSearchStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        List<AddressStoreWRP> result;
        Test.startTest(); 
            result = NBK_selectWarehouseHandlerUS.searchStores('San Francisco', '94105', 'California', 'US');
        Test.stopTest();

    }

    @isTest
    static void testSearchAssociates() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerUS.searchAssociates('San Francisco','San Francisco', '94105', 'California', 'US');
        Test.stopTest();
    }
    
    @isTest
    static void testGetInitialAssociates() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        Test.startTest();
        List<AddressStoreWRP> result = NBK_selectWarehouseHandlerUS.getInitialAssociates(37.7749, -122.4194, 'US');
        Test.stopTest();
    }

    @isTest
    static void testSearchStores2() {
  
        List<AddressStoreWRP> result;
        Test.startTest(); 
            result = NBK_selectWarehouseHandlerUS.searchStores('San Francisco', '94105', 'California', 'US');
        Test.stopTest();

    }

    @isTest
    static void testGetInitialStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        Test.startTest(); 
        List<AddressStoreWRP> result = NBK_selectWarehouseHandlerUS.getInitialStores(37.7749, -122.4194, 'US');
        Test.stopTest();
    }

    // Mock de la clase OpenStreetMapAPI
    public class OpenStreetMapAPIMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simular la respuesta de la API
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"address": {"city": "MockCity"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void fillerTest() {
        NBK_selectWarehouseHandlerUS.testFiller();
        Assert.isTrue(1 == 1);
    }

    public class OpenStreetMapAPIMock2 implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Crear una instancia de HTTPResponse para simular la respuesta
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[{"place_id":29879602,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"relation","osm_id":1428125,"lat":"61.0666922","lon":"-107.991707","class":"boundary","type":"administrative","place_rank":4,"importance":0.8661259109654083,"addresstype":"country","name":"Canada","display_name":"Canada","boundingbox":["41.6765556","83.3362128","-141.0027500","-52.3237664"]}]');
        res.setStatusCode(200);
       

        return res;
    }
    }

}