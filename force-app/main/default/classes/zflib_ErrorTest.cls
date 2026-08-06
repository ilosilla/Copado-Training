@isTest public with sharing class zflib_ErrorTest {

    @isTest static void test02() {
        Lead l = new Lead();
        zflib_Error err = new zflib_Error(l, 'test message');
        system.assertEquals('LEAD', err.domain.toUpperCase());
    }

    @isTest static void test03() {
        try {
            throw new ObjectNotFoundException('Object not found');
        } catch(Exception ex) {
            zflib_Error err = new zflib_Error(new Lead(), ex);
            system.assertEquals('OBJECTNOTFOUNDEXCEPTION', err.exceptionType.toUpperCase());
        }
    }

    @isTest static void test04() {
        try {
            throw new ObjectNotFoundException('Object not found');
        } catch(Exception ex) {
            Lead l = new Lead();
            zflib_Error err = new zflib_Error(l, ex);
            system.assertEquals('OBJECTNOTFOUNDEXCEPTION', err.exceptionType.toUpperCase());
            system.assertEquals('LEAD', err.domain.toUpperCase());
        }
    }


}