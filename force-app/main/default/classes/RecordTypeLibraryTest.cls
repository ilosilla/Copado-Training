@isTest public class RecordTypeLibraryTest {
    
    @isTest public static void test() {
        string Id = [SELECT id from RecordType where DeveloperName = 'WebRequest' limit 1].Id;
        System.assertEquals(Id, RecordTypeLibrary.Lead_WebRequest, 'Wrong Id for record type Lead_WebRequest');
        System.assertNotEquals(null, RecordTypeLibrary.Lead_WebRequest);
        System.assertNotEquals(null, RecordTypeLibrary.Lead_USWebRequest);
        System.assertNotEquals(null, RecordTypeLibrary.Opportunity_Retail);
        System.assertNotEquals(null, RecordTypeLibrary.Opportunity_Ecommerce);
        System.assertNotEquals(null, RecordTypeLibrary.Opportunity_Trade);
        System.assertNotEquals(null, RecordTypeLibrary.Account_PrivateCustomer);
        System.assertNotEquals(null, RecordTypeLibrary.Account_TradeCustomer);
        System.assertNotEquals(null, RecordTypeLibrary.Account_ResellerCustomer);
        System.assertNotEquals(null, RecordTypeLibrary.Case_ItCase);
    
    }

    @isTest
    static void testGetAvailableRecordtypesList() {
        // Define los datos de prueba
        String objectName = 'Account';

        // Llama al método que deseas probar
        List<Recordtype> result = RecordTypeLibrary.getAvailableRecordtypesList(objectName);

        // Verifica si el resultado no es nulo y si es del tipo esperado
        Assert.areNotEqual(null, result, 'El objeto cuenta deberia tener recordtypes asociados');
        Assert.isFalse(result.isEmpty(), 'Se deberian haber retornado recordtypes para el objeto cuenta');
    }
}