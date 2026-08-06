@IsTest
public class NB2B_CreateContactPointAddressContrTest {

	@TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupContactPointAddressTestData();
	}

	public static void testAll(){
		Test.startTest();
		executeOKMethod();
		executeExceptionMethod();
		Test.stopTest();
	}

	@IsTest
	public static void executeOKMethodTest(){
		Test.startTest();
		executeOKMethod();
		Test.stopTest();
	}

	private static void executeOKMethod() {
		ContactPointAddress address = NB2B_SetupClassTest.getContactPointAddress();

		NB2B_CreateContactPointAddressController contr = new NB2B_CreateContactPointAddressController();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getStatePicklistValuesByCountryCode'
		};
		NBK_ResponseWr res = contr.execute(params);
		System.assert(res.getSuccess(),res.getErrorMsg());
	}

	@IsTest
	public static void executeExceptionMethodTest(){
		Test.startTest();
		executeExceptionMethod();
		Test.stopTest();
	}

	private static void executeExceptionMethod() {
		ContactPointAddress address = NB2B_SetupClassTest.getContactPointAddress();

		NB2B_CreateContactPointAddressController contr = new NB2B_CreateContactPointAddressController();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => null
		};
		NBK_ResponseWr res = contr.execute(params);
		System.assert(!res.getSuccess());
	}
}