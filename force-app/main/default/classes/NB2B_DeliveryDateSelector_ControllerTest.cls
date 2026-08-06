@IsTest
public class NB2B_DeliveryDateSelector_ControllerTest {

	@TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupContactPointAddressTestData();
	}

	public static void testAll(){
		Test.startTest();
		executeOKMethod();
		executeExceptionMethod();
		executeGetUserDataMethod();
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

		NB2B_DeliveryDateSelector_Controller contr = new NB2B_DeliveryDateSelector_Controller();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getDeliveryDates',
			'postalCode' => address?.PostalCode
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

		NB2B_DeliveryDateSelector_Controller contr = new NB2B_DeliveryDateSelector_Controller();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getDeliveryDates',
			'postalCode' => null
		};
		NBK_ResponseWr res = contr.execute(params);
		System.assert(!res.getSuccess());
	}

	@IsTest
	public static void executeGetUserDataMethodTest(){
		Test.startTest();
		executeGetUserDataMethod();
		Test.stopTest();
	}
    @IsTest
	public static void instanceNBK_ResponseWr(){
		Test.startTest();
		NBK_ResponseWr response = new NBK_ResponseWr('Test');
		Test.stopTest();
	}

	private static void executeGetUserDataMethod() {
		ContactPointAddress address = NB2B_SetupClassTest.getContactPointAddress();

		NB2B_DeliveryDateSelector_Controller contr = new NB2B_DeliveryDateSelector_Controller();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getUserData'
		};
		NBK_ResponseWr res = contr.execute(params);
		System.assert(res.getSuccess(),res.getErrorMsg());
	}
}