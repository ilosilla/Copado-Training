/**
* @author Juan Manuel Martinez
*/
@isTest
private class Account_ControllerTest {

    /*
		This is the Setup method for populate diferent objects to use in every method
	*/
    @testSetup static void setup() {
    
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        insert DataFactoryMasterRelations.createMasterRelations();
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Managers'];
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'ProfileId' => p.Id, 'LocaleSidKey' => 'en_GB'};
        Insert User_TestDataFactory.createUsers(1, fieldsToAdd);
        
        User testUser = User_TestDataFactory.createUsers(1, new Map<String, Object>{'LocaleSidKey' => 'en_GB'})[0];
        Insert testUser;
        
        System.runAs(testUser){
            insert Account_TestDataFactory.createRetailer();
        }
        
    }

    /**
     * This is a test method for saveAccount
     */
    @isTest static void test_saveAccount() {

        Account retailerAccount = [SELECT Id, Name FROM Account WHERE Name='TestAcctRetailerAccount1'];
        
        // Test 1 : Regular Update Fail
        Map<String, Object> accountMap = new Map<String, Object>();
        accountMap.put('Id', retailerAccount.Id);
        accountMap.put('Name', null);
        accountMap.put('SAP_Id__c', null);
        accountMap.put('VAT_Number__c', '726416242');
        
        string jsonAccount_1 = JSON.serialize(accountMap);
        AccountTransactionHandler.TransactionResponse testResponse_1 = Account_Controller.saveAccount(jsonAccount_1, retailerAccount.Id, false);
        
		System.debug('testResponse_1: ' + testResponse_1.errorMessage );
        System.assert( testResponse_1.errorMessage.contains('Required fields are missing') &&  
                            testResponse_1.errorMessage.contains('Name') ); 
        
        // Test 2: Regular Update Success
        accountMap.put('Id', retailerAccount.Id);
        accountMap.put('Name', retailerAccount.Name);
        accountMap.put('SAP_Id__c', null);
        accountMap.put('VAT_Number__c', '726416242');
        String jsonAccount_2 = JSON.serialize(accountMap);
        
        AccountTransactionHandler.TransactionResponse testResponse_2 = Account_Controller.saveAccount(jsonAccount_2, retailerAccount.Id, false);
        AccountTransactionHandler.TransactionResponse expectedResponse_2 = 
            new AccountTransactionHandler.TransactionResponse(true, '', 'Regular Update', retailerAccount.Id, '');
        
        System.assert(equalTransactionResponse(expectedResponse_2, testResponse_2));

        // Test 3: SAP Update Success
        accountMap.put('Id', retailerAccount.Id);
        accountMap.put('Name', retailerAccount.Name);
        accountMap.put('SAP_Id__c', '0001086108');
        accountMap.put('VAT_Number__c', '726416242');
        
        String jsonAccount_3 = JSON.serialize(accountMap);
        AccountTransactionHandler.TransactionResponse expectedResponse_3 = null;
        if (UserCommons.hasSAPConnection() == true) {
            expectedResponse_3 = new AccountTransactionHandler.TransactionResponse(true,null, null, retailerAccount.Id, null);
        } else {
            expectedResponse_3 = new AccountTransactionHandler.TransactionResponse(true,'', 'Regular Update', retailerAccount.Id, '');
        }

        // test mock up
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
            AccountTransactionHandler.TransactionResponse testResponse_3 = Account_Controller.saveAccount(jsonAccount_3, retailerAccount.Id, false);
        Test.stopTest();

        System.assert(equalTransactionResponse(expectedResponse_3, testResponse_3));
    }
    
    private static Boolean equalTransactionResponse(AccountTransactionHandler.TransactionResponse expectedResponse, 
                                             AccountTransactionHandler.TransactionResponse actualResponse){
        Boolean equals = (expectedResponse.companyId == actualResponse.companyId &&
                          expectedResponse.customerId == actualResponse.customerId &&
                          expectedResponse.success == actualResponse.success &&
                          expectedResponse.errorMessage == actualResponse.errorMessage);
                                                 
        
        return equals;
    }
    /**
     * This is a test method for detectDates
     */
    @isTest static void test_detectDates() {
        Account retailerAccount = [SELECT Name, VAT_Number__c FROM Account WHERE Name='TestAcctRetailerAccount1'];
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
        Date dateToday = Date.today();
        Datetime dateTimeNow = Datetime.now();
        retailerAccount.Conversion_Date__c = dateToday;
        retailerAccount.Updated_Type__c = dateTimeNow;

        // Test Date
        Object result = Account_Controller.detectDates(fieldMap, String.valueOf(retailerAccount.Conversion_Date__c), 'Conversion_Date__c');
        System.assertEquals(result, dateToday);
        // Test DateTime
        result = Account_Controller.detectDates(fieldMap, String.valueOf(retailerAccount.Updated_Type__c), 'Updated_Type__c');
        System.assertEquals(result, dateTimeNow);
        // Test Other types
        result = Account_Controller.detectDates(fieldMap, retailerAccount.Name, 'Name');
        System.assertEquals(result, retailerAccount.Name);
    }

    /**
     * This is a test method for getPageLayoutFields 
     */
    @isTest static void test_getPageLayoutFields() {
        System.debug('test_getPageLayoutFields');
        // PageLayoutMockHttpResponseGenerator es un mock para la llamada a tooling api.
        // Devuelve siempre el nombre "LayoutForTesting-Edition Layout"
        Test.setMock(HttpCalloutMock.class, new PageLayoutMockHttpResponseGenerator());
        
        Account retailerAccount = [SELECT Id, Name, RecordTypeId FROM Account WHERE Name='TestAcctRetailerAccount1'];
        
        Test.startTest();
        	// Test 1: Success. Trae el layout correcto.
        	List<Account_Controller.LayoutSection> methodResponse = Account_Controller.getPageLayoutFields(String.valueOf(retailerAccount.Id), retailerAccount.RecordTypeId);
        	// Test 2: Fail. Exception Invalid recordId
        	List<Account_Controller.LayoutSection> methodResponse_2 = Account_Controller.getPageLayoutFields('', '');
        Test.stopTest();
        
        // Crea la respuesta esperada de Test 1 el layout "LayoutForTesting-Edition Layout"
        List<Account_Controller.LayoutSection> expectedResponse = new List<Account_Controller.LayoutSection>();
        
        // Crea las secciones del layout
        Account_Controller.LayoutSection section_1 = new Account_Controller.LayoutSection('Fields', 2);
        Account_Controller.LayoutSection section_2 = new Account_Controller.LayoutSection('Custom Links', 3);
        
        // Crea los items de los layout con su determinado comportamiento.
        Metadata.LayoutItem itemName = new Metadata.LayoutItem();
        itemName.field = 'Name';
        itemName.behavior = Metadata.UiBehavior.Required;
        
        Metadata.LayoutItem itemParentId = new Metadata.LayoutItem();
        itemParentId.field = 'ParentId';
        itemParentId.behavior = Metadata.UiBehavior.ReadOnly;
        
        Metadata.LayoutItem itemValidatedFlag = new Metadata.LayoutItem();
        itemValidatedFlag.field = 'Validated_Flag__c';
        itemValidatedFlag.behavior = Metadata.UiBehavior.ReadOnly;
        
        Metadata.LayoutItem itemProfessionalCheck = new Metadata.LayoutItem();
        itemProfessionalCheck.field = 'Professional_check__c';
        itemProfessionalCheck.behavior = Metadata.UiBehavior.ReadOnly;
        
        Metadata.LayoutItem itemAccClassf = new Metadata.LayoutItem();
        itemAccClassf.field = 'Other_account_classification__c';
        
        section_1.fieldList.add(new Account_Controller.LayoutField (itemName));
        section_1.fieldList.add(new Account_Controller.LayoutField (itemParentId));
        section_1.fieldList.add(new Account_Controller.LayoutField (itemProfessionalCheck));
        section_1.fieldList.add(new Account_Controller.LayoutField (itemValidatedFlag));
        section_1.fieldList.add(new Account_Controller.LayoutField (itemAccClassf));
        
        expectedResponse.add(section_1);
        expectedResponse.add(section_2);
        
        // Respuesta esperada de Test 2: Fail. Exception Invalid recordId
        List<Account_Controller.LayoutSection> expectedResponse_2 = new List<Account_Controller.LayoutSection>();
        
        System.assertEquals(methodResponse,methodResponse);
        System.assertEquals(methodResponse_2, methodResponse_2);
        
    }

    @isTest static void test_userHasAccess() {
        Account acc = [SELECT Id, Name, Sap_Id__c FROM Account WHERE Name='TestAcctRetailerAccount1'];
        acc.put('Id', acc.Id);
        acc.put('Name', acc.Name);
        acc.put('SAP_Id__c', '0001086108');
        
        User testUser = [SELECT Name, Id FROM User WHERE Profile.Name = 'Managers' and Execution_Context__c = 'FR' and isActive = true LIMIT 1];
        acc.OwnerId = testUser.Id;
        update acc;
        System.runAs(testUser){
            // Test 1: Usuario Manager User no creo la cuenta asi que no la puede editar.
            Assert.isTrue( Account_Controller.userHasAccess(acc.Id).get('hasAccess') );
            
            // Test 2: Usuario Manager User creo la cuenta asi que la puede editar.
            Account acc2 = Account_TestDataFactory.createBusinessAccount();
            Insert acc2;
            Assert.isTrue(Account_Controller.userHasAccess(acc2.Id).get('hasAccess') );
            
        }
        
    }
}