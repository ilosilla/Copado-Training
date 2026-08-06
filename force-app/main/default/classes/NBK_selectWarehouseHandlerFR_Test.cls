/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 20-11-2023
 * @group        :
 * @see          :
**/
@IsTest
public class NBK_selectWarehouseHandlerFR_Test {
     @TestSetup
    public static void makeData(){
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        ware.NBK_Address__CountryCode__s = 'FR';
        ware.NBK_Address__Latitude__s = 36.8746177;
        ware.NBK_Address__Longitude__s = -94.877374;
				ware.NBK_OnlineAppointment__c = true;
        insert ware;
    }

    @isTest
    static void testGetAddressPosition() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock());
        String result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerFR.getAddressPosition(37.7749, -122.4194, 'FR');
        Test.stopTest();

        System.assert(result != null, 'OK');

    }

    @isTest
    static void testSearchAllStoresFromCountry() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerFR.searchAllStoresFromCountry('FR');
            System.debug('result:'+result);
        Test.stopTest();
    }
     @isTest
    static void testSearchAllStoresFromCountry2() {
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerUS.searchAllStoresFromCountry('FR');
            NBK_selectWarehouseHandlerUS.findURLimage('<img width="22%" alt="Doral_Showroom.jpg" src="https://www.porcelanosa-usa.com/wp-content/uploads/2021/09/Doral_Showroom.jpg"></img>	');
        Test.stopTest();
    }

    @isTest
    static void testSearchStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock3());
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerFR.searchStores('San Francisco','San Francisco', '94105', 'California', 'FR');
        Test.stopTest();

    }

    @isTest
    static void testGetInitialStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        Test.startTest();
        List<AddressStoreWRP> result = NBK_selectWarehouseHandlerFR.getInitialStores(37.7749, -122.4194, 'FR');
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

    @IsTest
    public static void testimage(){

        Test.startTest();
            NBK_selectWarehouseHandlerFR.findURLimage('<img width="22%" alt="Doral_Showroom.jpg" src="https://www.porcelanosa-usa.com/wp-content/uploads/2021/09/Doral_Showroom.jpg"></img>');
        Test.stopTest();

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

    public class OpenStreetMapAPIMock3 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Crear una instancia de HTTPResponse para simular la respuesta
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"place_id":115350921,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"relation","osm_id":7444,"lat":"48.8588897","lon":"2.3200410217200766","class":"boundary","type":"administrative","place_rank":15,"importance":0.8317101715588673,"addresstype":"suburb","name":"Paris","display_name":"Paris, Île-de-France, France métropolitaine, France","boundingbox":["48.8155755","48.9021560","2.2241220","2.4697602"]},{"place_id":114827617,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"relation","osm_id":71525,"lat":"48.8534951","lon":"2.3483915","class":"boundary","type":"administrative","place_rank":12,"importance":0.8317101715588673,"addresstype":"city","name":"Paris","display_name":"Paris, Île-de-France, France métropolitaine, France","boundingbox":["48.8155755","48.9021560","2.2241220","2.4697602"]}]');
            res.setStatusCode(200);


            return res;
        }
    }

    @IsTest
    static void testGetAssociates() {

        Test.startTest();

        List<PorcelanosaAddress__c> result =
            NBK_selectWarehouseHandlerFR.getAssociates();

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
    }

    @IsTest
    static void testGetInitialAssociates() {

        Test.startTest();

        List<AddressStoreWRP> result =
            NBK_selectWarehouseHandlerFR.getInitialAssociates(
                48.8566,
                2.3522,
                'FR'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assert(result.size() > 0);
    }

    @IsTest
    static void testSearchAssociates() {

        Test.setMock(
            HttpCalloutMock.class,
            new OpenStreetMapAPIMock3()
        );

        Test.startTest();

        List<AddressStoreWRP> result =
            NBK_selectWarehouseHandlerFR.searchAssociates(
                'Paris',
                'Paris',
                '75001',
                'Ile-de-France',
                'FR'
            );

        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}