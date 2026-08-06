/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 20-11-2023
 * @group        :
 * @see          :
**/
@IsTest
public class NBK_selectWarehouseHandlerUK_Test {
     @TestSetup
    public static void makeData(){
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        ware.NBK_Address__CountryCode__s = 'GB';
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
            result = NBK_selectWarehouseHandlerUK.getAddressPosition(37.7749, -122.4194, 'UK');
        Test.stopTest();

        System.assert(result != null, 'OK');

    }

    @isTest
    static void testSearchAllStoresFromCountry() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerUK.searchAllStoresFromCountry('GB');
            System.debug('result:'+result);
        Test.stopTest();
    }

    @isTest
    static void testSearchStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock3());
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_selectWarehouseHandlerUK.searchStores('San Francisco','San Francisco', '94105', 'California', 'UK');
        Test.stopTest();

    }

    @isTest
    static void testGetInitialStores() {
        Test.setMock(HttpCalloutMock.class, new OpenStreetMapAPIMock2());
        Test.startTest();
        List<AddressStoreWRP> result = NBK_selectWarehouseHandlerUK.getInitialStores(37.7749, -122.4194, 'UK');
        Test.stopTest();
    }

    @isTest
    static void testFindURLimage() {
        Test.startTest();
        	NBK_selectWarehouseHandlerUK.findURLimage('<img width="22%" alt="Doral_Showroom.jpg" src="https://www.porcelanosa-usa.com/wp-content/uploads/2014/09/manhattan_thumb.jpg"></img>	');
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

    public class OpenStreetMapAPIMock2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Crear una instancia de HTTPResponse para simular la respuesta
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"place_id":274010846,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"relation","osm_id":65606,"lat":"51.5073359","lon":"-0.12765","class":"place","type":"country","place_rank":16,"importance":0.8307827616237295,"addresstype":"country","name":"London","display_name":"London, Greater London, England, United Kingdom","boundingbox":["51.2867601","51.6918741","-0.5103751","0.3340155"]}]');
            res.setStatusCode(200);


            return res;
        }
    }

    public class OpenStreetMapAPIMock3 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Crear una instancia de HTTPResponse para simular la respuesta
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"place_id":274010846,"licence":"Data © OpenStreetMap contributors, ODbL 1.0. http://osm.org/copyright","osm_type":"relation","osm_id":65606,"lat":"51.5073359","lon":"-0.12765","class":"place","type":"city","place_rank":16,"importance":0.8307827616237295,"addresstype":"city","name":"London","display_name":"London, Greater London, England, United Kingdom","boundingbox":["51.2867601","51.6918741","-0.5103751","0.3340155"]}]');
            res.setStatusCode(200);


            return res;
        }
    }
}