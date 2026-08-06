/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 31-10-2023
 * @group        :
 * @see          :
**/
@IsTest
public without sharing class AppointmentStates_Selector_Test {

	@IsTest
	public static void test1(){
		Test.startTest();
			AppointmentStates_Selector.getState('Florida','US');
			AppointmentStates_Selector.getState('Florida','United States');
		Test.stopTest();
	}
}