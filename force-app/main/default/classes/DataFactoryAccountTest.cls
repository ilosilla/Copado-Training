@isTest
public class DataFactoryAccountTest {
    
    private static final Integer NUM_ACCOUNTS = 10;

	/**
	 * Setup data
	 */
    @testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest static void createPersonAccountsTest() {
        DataFactoryAccount.createPersonAccounts(NUM_ACCOUNTS);
        List<Account> accounts = [select Id from Account];
        System.assertEquals(accounts.size(), NUM_ACCOUNTS, 'The number of acounts do not match the number of accounts requested');
    } // createPersonaAccountsTest

    @isTest static void createAccounts() {
        DataFactoryAccount.createAccounts(NUM_ACCOUNTS);
        List<Account> accounts = [select Id from Account];
        System.assertEquals(NUM_ACCOUNTS, accounts.size());
    }    

    @isTest static void createBusinessAccountsTest() {
        DataFactoryAccount.autoInsert = false;
        List<Account> auxList = DataFactoryAccount.createBusinessAccounts(NUM_ACCOUNTS);
        insert auxList;
        List<Account> accounts = [select Id from Account];
        System.assertEquals(accounts.size(), NUM_ACCOUNTS, 'The number of acounts do not match the number of accounts requested');
    } // createPersonaAccountsTest

    @isTest static void createSalesRelations() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        DataFactoryAccount.createSalesRelation(acc, OrganizationCommons.ORG_SOUTH_EAST, '60', '2552');
        List<Sales_Relationship__c> results = [select Id, Name, Account_Org__c from Sales_Relationship__c where Account_Org__c = :acc.Id];
        System.assertEquals(1, results.size(), 'No relation has been created!');
    }
    

}