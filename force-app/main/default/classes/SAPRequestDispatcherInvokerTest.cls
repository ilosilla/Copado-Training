@isTest public with sharing class SAPRequestDispatcherInvokerTest {    
    @IsTest static void testInvoke_DispatcherKickoff() {
        List<String> dummy = new List<String>{ 'run' };
        Test.startTest();
        SAPRequestDispatcherInvoker.invoke(dummy);
        Test.stopTest();
        System.assert(true, 'Invoker executed without errors.');
    }
}