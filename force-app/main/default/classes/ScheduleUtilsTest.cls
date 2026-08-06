/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Utils
* @description 	Utility methods to schedule apex tasks
*/
@isTest public with sharing class ScheduleUtilsTest {

    @testSetup private static void testsetup() {
        testUtils.enableTriggers();
    }

    @isTest private static void runTodayAfter() {
        System.assertNotEquals(null, ScheduleUtils.runTodayAfter(1, 30), 'String not valid');
    }
}