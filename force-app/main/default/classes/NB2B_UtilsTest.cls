@IsTest
public class NB2B_UtilsTest {

	public static void testAll(){
		Test.startTest();
		getDependentPicklistValuesMethod();
		Test.stopTest();
	}

	@IsTest
	public static void getDependentPicklistValuesMethodTest(){
		Test.startTest();
		getDependentPicklistValuesMethod();
		Test.stopTest();
	}

	private static void getDependentPicklistValuesMethod() {
		Map<String,List<Schema.PicklistEntry>> countryStatesPicklistValueMap = NB2B_Utils.getDependentPicklistValues('ContactPointAddress', 'StateCode', true);
		System.assert(!countryStatesPicklistValueMap.isEmpty());
	}
}