@isTest public with sharing class zflib_BaseDomainClassTest {
    @isTest public static void test() {
        zflib_BaseDomainClass bdc = new zflib_BaseDomainClass();
        System.assertNotEquals('', bdc.dummy, 'Pues ya');
    }
}