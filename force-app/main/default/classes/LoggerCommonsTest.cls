@isTest public class LoggerCommonsTest {

    @isTest private static void testA() {
        try {
            Contact c = new Contact(FirstName = 'Unit', LastName = 'Test', 
                                AccountId = UserInfo.getUserId()
            );  // Forzamos una excepción usando un Id incorrecto
            inserta(c);
            System.assert(false, 'Ha fallado el test (no se ha producido la excepción');
        } catch (Exception ex) {
            String tid = LoggerCommons.logException('TEST', UserInfo.getUserId(), ex);
            System.assertNotEquals(null, tid, 'Ha fallado el test (transactionId no puede ser nulo');                        
            Test.startTest();
            LoggerCommons.createCase(ex);
            Test.stopTest();
        }
    }

    // Force the exception on a different method so the stack trace has two lines
    private static void inserta(Contact c) {
        insert c;
    }
}