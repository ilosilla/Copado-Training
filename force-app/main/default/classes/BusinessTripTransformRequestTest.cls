@IsTest
public with sharing class BusinessTripTransformRequestTest {
    @IsTest
    static void testCloneToTripInvocable() {

        // -------------------------------------------------
        // 1️⃣ PREPARAR DATOS
        // -------------------------------------------------
        BusinessTrip__c trip = new BusinessTrip__c(
            Title__c = 'Test Title',
            StartDate__c = Date.today(),
            EndDate__c = Date.today().addDays(2),
            Type__c = 'REQUEST'
        );
        insert trip;

        // Lista de entrada (como lo hace Flow)
        List<String> tripIds = new List<String>{ trip.Id };

        // -------------------------------------------------
        // 2️⃣ EJECUTAR MÉTODO INVOCABLE
        // -------------------------------------------------
        Test.startTest();
        List<BusinessTripTransformRequest.Results> results =
            BusinessTripTransformRequest.cloneToTripInvocable(tripIds);
        Test.stopTest();

        // -------------------------------------------------
        // 3️⃣ ASSERTS
        // -------------------------------------------------
        System.assertEquals(
            1,
            results.size(),
            'Debe devolver un resultado'
        );

        System.assertNotEquals(
            null,
            results[0].outputMember,
            'El outputMember debe contener el Id del trip clonado'
        );

        // -------------------------------------------------
        // 4️⃣ VALIDAR QUE EL REGISTRO EXISTE
        // -------------------------------------------------
        BusinessTrip__c clonedTrip = [
            SELECT Id, Type__c, RequestTrip__c
            FROM BusinessTrip__c
            WHERE Id = :results[0].outputMember
        ];

        System.assertEquals(
            'TRIP',
            clonedTrip.Type__c,
            'El trip clonado debe ser de tipo TRIP'
        );

        System.assertEquals(
            trip.Id,
            clonedTrip.RequestTrip__c,
            'Debe apuntar al trip original'
        );
    }
}