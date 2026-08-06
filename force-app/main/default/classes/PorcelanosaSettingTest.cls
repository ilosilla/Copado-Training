/**
* @author 		Ramón Prades
* @date 		November 2022
* @group 		Settings
* @description  Class to handle system global settings
*/
@isTest public class PorcelanosaSettingTest {
    
    @testSetup public static void testSetup() {
        PorcelanosaSetting__c setting = new Porcelanosasetting__c();
        setting.key__c = 'TEST';
        setting.subkey__c = 'UK';
        setting.value1__c = 'HELLO';
        insert setting;
    }

    @isTest private static void test1() {
        PorcelanosaSetting setting = new PorcelanosaSetting('TEST', 'UK');
        System.assertEquals('HELLO', setting.value1, 'value should be hello');
    }

    @isTest private static void test2() {
        Boolean exr = false;
        try {
            PorcelanosaSetting setting = new PorcelanosaSetting('XXXXTEST', 'UK');
            System.assertNotEquals(setting, setting, 'Never should be here');
        } catch (ObjectNotFoundException onf) {
            exr = true;
        }
        System.assertEquals(true, exr, 'A exception should have been raised');
    }


}