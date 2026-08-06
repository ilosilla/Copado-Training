@IsTest
public with sharing class NB2B_AddressController_Test {

    @TestSetup
	public static void setupData(){
		NB2B_SetupClassTest.setupAllData();
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
    @IsTest
    public static void selectPointAddressesByAccountIdTest(){
        Test.startTest();
        NB2B_AddressSelector.selectPointAddressesByAccountId(null);
        Test.stopTest();
    }

	private static void executeOKMethod() {
		WebCart webCart1 = NB2B_SetupClassTest.getWebCart();
        
		NB2B_AddressController controller = new NB2B_AddressController();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getAddresses',
			'webcartId' => webCart1.Id
		};
		NBK_ResponseWr res = controller.execute(params);

        Map<String,Object> params2 = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getAddressPickup',
			'deliveryGroup' => ''
		};
		NBK_ResponseWr res2 = controller.execute(params2);
		// System.assert(res.getSuccess(),res.getErrorMsg());

	}

	@IsTest
	public static void executeExceptionMethodTest(){
		Test.startTest();
		executeExceptionMethod();
		Test.stopTest();
	}

	private static void executeExceptionMethod() {

		NB2B_AddressController controller = new NB2B_AddressController();
		Map<String,Object> params = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getAddresses',
			'webcartId' => null
		};
		NBK_ResponseWr res = controller.execute(params);
        
        Map<String,Object> params2 = new Map<String,Object>{
			NBK_ControllerExecuterConstants.PARAM_ACTION => 'getAddressPickup',
			'deliveryGroup' => null
		};
		NBK_ResponseWr res2 = controller.execute(params2);
		System.assert(!res.getSuccess());
	}
}