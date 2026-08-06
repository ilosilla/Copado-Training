@IsTest
private class EventContactsControllerTest {
    @IsTest
    static void testGetRelatedContacts() {
        // Crear cuenta de prueba
        Account testAccount = DataFactoryAccount.createAccounts(1)[0];

        // Crear contacto de prueba
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '1234567890',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Crear evento de prueba
        Event testEvent = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(2),
            IsAllDayEvent = false
        );
        insert testEvent;

        // Crear EventRelation de prueba
        EventRelation testEventRelation = new EventRelation(
            EventId = testEvent.Id,
            RelationId = testContact.Id,
            IsWhat = false
        );
        insert testEventRelation;

        // Llamar al método y validar resultados
        Test.startTest();
        List<Contact> relatedContacts = EventContactsController.getRelatedContacts(testEvent.Id);
        Test.stopTest();

        // Verificaciones
        System.assertEquals(1, relatedContacts.size(), 'Debe haber exactamente un contacto relacionado');
        System.assertEquals(testContact.Id, relatedContacts[0].Id, 'El contacto relacionado debe coincidir con el contacto de prueba');
    }
}