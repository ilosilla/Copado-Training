@isTest
private class ContactsHelperTest {
    @testSetup
    static void setupTestData() {
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com'
        );
        insert testContact;
    }
    
    @isTest
    static void testGetContactSuccess() {
        // Obtener un contacto de prueba
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Llamar al método getContact
        Test.startTest();
        Contact retrievedContact = ContactsHelper.getContact(testContact.Id);
        Test.stopTest();
        
        // Verificar que se haya recuperado el contacto correctamente
        System.assertNotEquals(null, retrievedContact, 'El contacto no debería ser nulo.');
        System.assertEquals(testContact.Id, retrievedContact.Id, 'El ID del contacto recuperado debe coincidir con el insertado.');
    }
    
    @isTest
    static void testGetContactException() {
        Test.startTest();
        try {
            ContactsHelper.getContact('InvalidId');
            System.assert(false, 'Se esperaba una excepción, pero no se lanzó.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null, 'El mensaje de la excepción no debería ser nulo.');
        }
        Test.stopTest();
    }
}