/** 
	* Type: Apex Test Class
	* Name: NB2B_SetupClassTest
	* @author Nubika S.L.
	* Company: Nubika S.L.
	* Date: 13/05/2022
	* Description: Apex Tests Setup class
	* @version 1.0
*/
@isTest
public with sharing class NB2B_SetupClassTest {

	/*------------------------------*/
	/*        DATA ATTRIBUTES       */
	/*------------------------------*/

	private static List<Account> accountList = new List<Account>();
	private static List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
	private static List<WebCart> webCartList = new List<WebCart>();


	/*------------------------------*/
	/*        GETTERS METHODS       */
	/*------------------------------*/

	public static Account getAccount(){
		return [
				SELECT Id, Name, OwnerId
				FROM Account
				LIMIT 1
		];
	}

	public static Order getOrder(){
		return [
				SELECT Id, Name, Ordernum__c, Sap_Id__c
				FROM Order
				LIMIT 1
		];
	}

	public static WebCart getWebCart(){
		return [
				SELECT Id, AccountId
				FROM WebCart
				LIMIT 1
		];
	}

	public static ContactPointAddress getContactPointAddress(){
		return [
				SELECT Id, Name, CountryCode, StateCode, City, PostalCode, Street
				FROM ContactPointAddress
				LIMIT 1
		];
	}

	/*------------------------------*/
	/*       COMPOSER METHODS       */
	/*------------------------------*/

	private static ContactPointAddress createContactPointAddress(Account acc, String type, String name, String city, String countryCode, String stateCode, String postalCode, String street) {
		ContactPointAddress address = new ContactPointAddress();
		address.addressType = type;
		address.Name = name;
		address.ParentId = acc.Id;
		address.City = city;
		address.CountryCode = countryCode;
		address.PostalCode = postalCode;
		address.StateCode = stateCode;
		address.Street = street;
		return address;
	}

	/*------------------------------*/
	/*      GENERATION METHODS      */
	/*------------------------------*/

	private static void generateTriggerConfiguration(){
		Trigger_configuration__c tconfig = TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();

		insert tconfig;
	}

	private static void generateAccounts(){
		accountList.add(Account_TestDataFactory.createBusinessAccount());

		insert accountList;
	}

	private static void generateContactPointAddresses(){
		cpaList.add(createContactPointAddress(
			accountList.get(0),
			'Billing',
			'Test adddress',
			'London',
			'GB',
			'LO',
			'SW1H 0ET',
			'1 Victoria St')
		);

		insert cpaList;
	}

	private static void generateWebCart(){
		WebStore webStore = new WebStore(Name='United Kingdom');
        insert webStore;
		Account acc = new Account();
        acc = Account_TestDataFactory.createCustomer();
        acc.SAP_Id__c = '1234';
        insert acc;
    
		webCartList.add(new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=acc.Id, PoNumber='test'));

		insert webCartList;
	}

	private static void generateOrderItem(){

		Order ord = new Order(
            AccountId = getAccount().Id, 
            Status = 'Draft', 
            EffectiveDate = Date.today(),
            Sap_Id__c = '1234567',
			Ordernum__c = '1234'
        );
        insert ord;
        
        Product2 pro = new Product2 (
	    		Name = 'TestProduct1',
	    		IsActive = true, 
                StockKeepingUnit = '1234567',
            	ProductCode = '111111111'
	    	);
        insert pro;
        
        OrderItem orderItemObj = new OrderItem();
        orderItemObj.OrderId  = ord.Id;
        orderItemObj.Product2Id  = pro.Id;
        orderItemObj.ListPrice = 0;
        orderItemObj.UnitPrice = 0;
        orderItemObj.TotalLineAmount = 0;
        orderItemObj.Quantity = 2;
        insert orderItemObj;

	}


	/*-------------------------------*/
	/*       MODULE GENERATORS       */
	/*-------------------------------*/

	public static void generateAccountsData(){
		generateAccounts();
	}

	/*-------------------------------*/
	/*          SETUP METHODS        */
	/*-------------------------------*/

	//Generates Basic Test Data: Admin User + Accounts + Users
	public static void setupGenericTestData(){
		generateTriggerConfiguration();
		generateAccountsData();
	}

	public static void setupContactPointAddressTestData(){
		setupGenericTestData();
		generateContactPointAddresses();
	}

	//GENERATE ALL DATA
	public static void setupAllData(){
		setupGenericTestData();
		generateContactPointAddresses();
		generateWebCart();
		generateOrderItem();
	}
}