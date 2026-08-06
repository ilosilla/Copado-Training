/**
 * Author           Ramón prades
 * Description      Test class from TriggerFlags custom setting
 * Date             May 2020
 * History              
 */

@isTest
public with sharing class TriggerFlagsTest {
    @isTest static void test_readFlags() {
        System.assertEquals(true, TriggerFlags.isEnabled('Account') , 'Triggers should be enabled when testing by default!');        

        Boolean exceptionReceived = false; 
        try {
            Boolean value = TriggerFlags.isEnabled('######');            
        } catch (ObjectNotFoundException ex) {
            exceptionReceived = true;
        }
        System.assertEquals(exceptionReceived, true, 'An exception shoyuld have been received for non existent flags');
    } // test_getSystemSettings

} // class  TriggerFlagsSettingsTest