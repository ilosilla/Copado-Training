@isTest
public class AccountRecordTypeChangeHandler_Test {
	@testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        TestUtils.enableTriggers();
		
        // Setup test Convert Account
        // La conversion person to business account no tiene requisitos asi que no debe tener problemas.
        Account customer = Account_TestDataFactory.createCustomer();
        customer.FirstName = 'Successful'; customer.LastName = 'Customer';
        
        // A las cuentas business que no tengan contactos relacionados se les tiene que crear uno asi que no debe haber problemas.
        Account trade = Account_TestDataFactory.createBusinessAccount();
        trade.Name = 'Trade Success';
        
        Account fabricator = Account_TestDataFactory.createFabricator();
        fabricator.Name = 'Fabricator Success';
        
        Account retailer = Account_TestDataFactory.createRetailer();
        retailer.Name = 'Retailer Success';
        
        // Setup test checkIfPossible: Accounts que deben dar error
        // PARENT_ID_ERROR
        Account tradeError = Account_TestDataFactory.createBusinessAccount();
        tradeError.Name = 'Trade Error';
		
        // CHILD_ACCOUNTS_ERROR
        Account fabricatorError = Account_TestDataFactory.createFabricator();
        fabricatorError.Name = 'Fabricator Error'; 
        
        // REPORTS_TO_ERROR
        Account fabricatorContactError = Account_TestDataFactory.createFabricator();
        fabricatorContactError.Name = 'Fabricator Contact Error'; 
        
        // NUMBER_OF_CONTACTS_ERROR
        Account retailerError = Account_TestDataFactory.createRetailer();
        retailerError.Name = 'Retailer Error';
        
        // DIFFERENT_OWNER_ERROR
        Account retailerContactError = Account_TestDataFactory.createRetailer();
        retailerContactError.Name = 'Retailer Contact Error';
        
        // CHILD_CONTACTS_ERROR
        Account tradeContactError = Account_TestDataFactory.createBusinessAccount();
        tradeContactError.Name = 'Trade Contact Error';
        
        Account_TestDataFactory.insertAccounts(new List<Account>{customer, trade, fabricator, tradeContactError,
            retailer, tradeError, fabricatorError, retailerError, retailerContactError, fabricatorContactError});
        
        tradeError.ParentId = fabricatorError.Id;
        Update tradeError;
        
        Contact TradeContact = new Contact(AccountId = tradeContactError.Id, FirstName = '1', LastName = tradeContactError.Name);
        
        List<Contact> contactListToInsert = new List<Contact>{ new Contact(FirstName = '1', LastName = retailerError.Name, AccountId = retailerError.Id), 
            new Contact(FirstName = '2', LastName = retailerError.Name, AccountId = retailerError.Id),
            TradeContact
            };
        
        Insert contactListToInsert;
        
        Insert new Contact(FirstName = '1', LastName = fabricatorContactError.Name, AccountId = fabricatorContactError.Id, ReportsToId = TradeContact.Id);
        
       	List<User> usersToInsert = User_TestDataFactory.createUsers(2, new Map<String, Object>{'LocaleSidKey' => 'en_US'});
        Insert usersToInsert;
		
        // Para generar un error se crea el contacto con un distinto usuario que el que creo la cuenta.
        System.runAs(usersToInsert[1]){
            Insert new Contact(FirstName = '1', LastName = retailerContactError.Name, AccountId = retailerContactError.Id);
        }
        
    }
    
    @isTest
    public static void test_getRecordTypes(){
        Account customerAcc = [SELECT Id FROM Account WHERE IsPersonAccount = true LIMIT 1];
        Account businessAcc = [SELECT Id FROM Account WHERE IsPersonAccount = false LIMIT 1];
        
        User adminUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: Label.System_Administrator LIMIT 1];
        
        System.runAs(adminUser){
            Map<String, String> resultCustomer = AccountRecordTypeChangeHandler.getRecordTypes(customerAcc.Id);
            Map<String, String> resultBusiness = AccountRecordTypeChangeHandler.getRecordTypes(businessAcc.Id);
            
            System.assertEquals(3, resultCustomer.size());
            System.assertEquals(1, resultBusiness.size());
            
        }
        
    }
    
    @isTest
    public static void test_checkIfPossible(){
        Account customerAcc = [SELECT Id FROM Account WHERE FirstName = 'Successful' AND LastName = 'Customer'];
        Account tradeError = [SELECT Id FROM Account WHERE Name = 'Trade Error'];
        Account tradeContactError = [SELECT Id FROM Account WHERE Name = 'Trade Contact Error'];
        Account fabricatorError = [SELECT Id FROM Account WHERE Name = 'Fabricator Error'];
        Account fabricatorContactError = [SELECT Id FROM Account WHERE Name = 'Fabricator Contact Error'];
        Account retailerError = [SELECT Id FROM Account WHERE Name = 'Retailer Error'];
        Account retailerContactError = [SELECT Id FROM Account WHERE Name = 'Retailer Contact Error'];
        
        User adminUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: Label.System_Administrator LIMIT 1];
        
        Map<String,Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
            
        Id fabricatorRecTypeId = recTypeMap.get('Fabricator').getRecordTypeId();
        Id resellerRecTypeId = recTypeMap.get('Third_party_Retailer_Reseller').getRecordTypeId();
        Id privateCustomerRecTypeId = recTypeMap.get('Private_Customer').getRecordTypeId();
        Id tradeRecTypeId = recTypeMap.get('Trade_and_Specificators').getRecordTypeId();
        
        System.runAs(adminUser){
            test.startTest();
            Map<String, String> customerResult = AccountRecordTypeChangeHandler.checkIfPossible(customerAcc.Id);
            Map<String, String> tradeErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(tradeError.Id);
            Map<String, String> tradeContactErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(tradeContactError.Id);
            Map<String, String> fabricatorErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(fabricatorError.Id);
            Map<String, String> fabricatorContactErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(fabricatorContactError.Id);
            Map<String, String> retailerErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(retailerError.Id);
            Map<String, String> retailerContactErrorResult = AccountRecordTypeChangeHandler.checkIfPossible(retailerContactError.Id);
            
            System.assert(!customerResult.containsKey('error'));
            System.assertEquals(AccountRecordTypeChangeHandler.PARENT_ID_ERROR, tradeErrorResult.get('error'));
            System.assertEquals(AccountRecordTypeChangeHandler.CHILD_ACCOUNTS_ERROR, fabricatorErrorResult.get('error'));
            //AccountRecordTypeChangeHandler.REPORTS_TO_ERROR
            System.assert(fabricatorContactErrorResult.containsKey('error'));
            System.assertEquals(AccountRecordTypeChangeHandler.NUMBER_OF_CONTACTS_ERROR, retailerErrorResult.get('error'));
            //AccountRecordTypeChangeHandler.DIFFERENT_OWNER_ERROR
            System.assert(retailerContactErrorResult.containsKey('error'));
            //AccountRecordTypeChangeHandler.CHILD_CONTACTS_ERROR
            System.assert(tradeContactErrorResult.containsKey('error'));
            test.stopTest();
        }
    }
    
    @isTest
    public static void test_convertAccount(){
        Account customerAcc = [SELECT Id FROM Account WHERE FirstName = 'Successful' AND LastName = 'Customer'];
        Account tradeAcc = [SELECT Id FROM Account WHERE Name = 'Trade Success'];
        Account fabricatorAcc = [SELECT Id FROM Account WHERE Name = 'Fabricator Success'];
        Account retailerAcc = [SELECT Id FROM Account WHERE Name = 'Retailer Success'];
        
        User adminUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: Label.System_Administrator LIMIT 1];
        
        Map<String,Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
            
        Id fabricatorRecTypeId = recTypeMap.get('Fabricator').getRecordTypeId();
        Id resellerRecTypeId = recTypeMap.get('Third_party_Retailer_Reseller').getRecordTypeId();
        Id privateCustomerRecTypeId = recTypeMap.get('Private_Customer').getRecordTypeId();
        Id tradeRecTypeId = recTypeMap.get('Trade_and_Specificators').getRecordTypeId();
        
        System.runAs(adminUser){
            test.startTest();
            Map<String, String> tradeResultPosible = AccountRecordTypeChangeHandler.checkIfPossible(tradeAcc.Id);
            Map<String, String> retailerResultPosible = AccountRecordTypeChangeHandler.checkIfPossible(retailerAcc.Id);
            Map<String, String> customerResultPosible = AccountRecordTypeChangeHandler.checkIfPossible(customerAcc.Id);
            
            System.assert(!tradeResultPosible.containsKey('error'));
            System.assert(!retailerResultPosible.containsKey('error'));
            System.assert(!customerResultPosible.containsKey('error'));
            
            Map<String, String> fabricatorResult = AccountRecordTypeChangeHandler.convertAccount(fabricatorAcc.Id, privateCustomerRecTypeId);
            Map<String, String> tradeResult = AccountRecordTypeChangeHandler.convertAccount(tradeAcc.Id, privateCustomerRecTypeId);
            Map<String, String> retailerResult = AccountRecordTypeChangeHandler.convertAccount(retailerAcc.Id, privateCustomerRecTypeId);
            Map<String, String> customerResult = AccountRecordTypeChangeHandler.convertAccount(customerAcc.Id, tradeRecTypeId);
            
            System.assert(fabricatorResult.containsKey('error'));
            System.assert(!tradeResult.containsKey('error'));
            System.assert(!retailerResult.containsKey('error'));
            System.assert(!customerResult.containsKey('error'));
            test.stopTest();
            
        }
        
    }
}