@IsTest
public class NB2B_TestExecuter {

	@TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupAllData();
	}

	@isTest
	public static void NB2B_DeliveryDateSelector_ControllerTest_MethodTest() {
		NB2B_DeliveryDateSelector_ControllerTest.testAll();
	}

	@isTest
	public static void NB2B_CreateContactPointAddressContrTest_MethodTest() {
		NB2B_CreateContactPointAddressContrTest.testAll();
	}

	@isTest
	public static void NB2B_UtilsTest_MethodTest() {
		NB2B_UtilsTest.testAll();
	}
}