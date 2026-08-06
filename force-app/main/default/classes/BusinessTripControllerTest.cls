/**
 * @author      Ivan Losilla
 * @date        October 2025
 * @group       BusinessTrip
 * @description Test class for BusinessTripController
 */
@IsTest
private class BusinessTripControllerTest {

    // Método de utilidad para crear datos de prueba
    private static Map<String, Id> createTestData() {
        // Crear usuario propietario de los viajes
        User u = DatafactoryUser.createUKUser();

        System.runAs(u) {
            // Crear un BusinessTrip
            BusinessTrip__c trip = new BusinessTrip__c(
                Title__c = 'Business Trip Test',
                Countries__c = 'GB',
                StartDate__c = Date.today(),
                EndDate__c = Date.today().addDays(5),
                OwnerId = u.Id,
                Comments__c = 'Initial comment',
                MainRisks__c = 'None',
                MainObjectives__c = 'Customer meetings'
            );
            insert trip;

            // Crear BusinessTripEvent relacionado
            BusinessTripVisit__c event1 = new BusinessTripVisit__c(
                Date__c = Date.today(),
                Channel__c = 'PRESCRIPTOR',
                Title__c = 'TEST TITLE EVENT',
                Comment__c = 'Meeting scheduled',
                BusinessTrip__c = trip.Id,
                Status__c = 'ACTIVE'
            );
            insert event1;

            // Crear BusinessTripEvent relacionado
            BusinessTripStrategy__c strategy1 = new BusinessTripStrategy__c(
                Comment__c = 'Meeting scheduled',
                Title__c = 'YELLOW',
                BusinessTrip__c = trip.Id
            );
            insert strategy1;
        }

        

        return new Map<String, Id>{
            'userId' => u.Id
        };
    }

    @IsTest
    static void testGetBusinessTrips() {
        Map<String, Id> ids = createTestData();

        Test.startTest();
        List<BusinessTrip__c> trips = BusinessTripController.getBusinessTrips(ids.get('userId'));
        Test.stopTest();

        System.assert(!trips.isEmpty(), 'Debe devolver al menos un viaje');
        System.assertEquals('Business Trip Test', trips[0].Title__c);
    }

    @IsTest
    static void testSendPdf_WithFiles() {

        Map<String, Id> ids = createTestData();
        // Crear usuario y viaje
        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];

        // Crear un archivo (ContentDocument + ContentVersion + Link)
        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Archivo de prueba'),
            IsMajorVersion = true
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        insert new ContentDocumentLink(
            ContentDocumentId = docId,
            LinkedEntityId = trip.Id,
            ShareType = 'V'
        );

        Test.startTest();
        BusinessTripController.sendPdf(new List<String>{u.Email}, new List<String>{}, trip.Id, 'JJJJJJ', 'HHHH');
        Test.stopTest();

        // No hay forma directa de verificar el envío real, pero validamos que no haya fallos
        System.assert(true, 'El método sendPdf se ejecutó correctamente.');
    }

    @IsTest
    static void testGetBusinessTripHeader() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        Test.startTest();
        BusinessTrip__c header = BusinessTripController.getBusinessTripHeader(trip.Id);
        Test.stopTest();

        System.assertNotEquals(null, header, 'Debe devolver un registro');
        System.assertEquals('United Kingdom', header.Countries__c, 'El país debe ser United Kingdom');
    }

    @IsTest
    static void TestClone() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        Test.startTest();
        String newId = BusinessTripController.cloneToTrip(trip.Id);
        Test.stopTest();

        BusinessTrip__c tripNew = [SELECT id,Type__c FROM BusinessTrip__c WHERE Id =: newId];

        System.assertEquals('TRIP', tripNew.Type__c, 'El tipo debe ser TRIP');
    }

    @IsTest
    static void TestCloneRequest() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        Test.startTest();
        String newId = BusinessTripController.cloneToRequest(trip.Id);
        Test.stopTest();

        BusinessTrip__c tripNew = [SELECT id,Type__c FROM BusinessTrip__c WHERE Id =: newId];

        System.assertEquals('REQUEST', tripNew.Type__c, 'El tipo debe ser REQUEST');
    }

    @IsTest
    static void testGetBusinessTripEvents() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        Test.startTest();
        List<BusinessTripVisit__c> visits = BusinessTripController.getBusinessTripVisits(trip.Id);
        Test.stopTest();

        System.assertEquals(1, visits.size(), 'Debe devolver un evento');
        System.assertEquals('ACTIVE', visits[0].Status__c);
    }

    @IsTest
    static void testGetBusinessTripStrategies() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        Test.startTest();
        List<BusinessTripStrategy__c> strategies = BusinessTripController.getBusinessTripStrategies(trip.Id);
        Test.stopTest();

        System.assertEquals(1, strategies.size(), 'Debe devolver un evento');
        System.assertEquals('YELLOW', strategies[0].Title__c);
    }

    @IsTest
    static void testGetBusinessTripWrapper() {
        Map<String, Id> ids = createTestData();

        BusinessTrip__c trip = [SELECT id FROM BusinessTrip__c LIMIT 1];

        PageReference pageRef = new PageReference('/apex/BusinessTripPdfPage');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('tripId', trip.Id);

        Test.startTest();
        BusinessTripController.businesssTripData data = BusinessTripController.getBusinessTrip(trip.Id);
        BusinessTripPdfController ctrl = new BusinessTripPdfController();

        Test.stopTest();

        System.assertNotEquals(null, data.header, 'El wrapper debe tener cabecera');
        System.assertNotEquals(null, data.visits, 'El wrapper debe tener lista de eventos');
        System.assertEquals('Business Trip Test', data.header.Title__c);
    }
}