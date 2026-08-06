/**
 * @description       : 
 * @author            : Andrea Da Silva
 * @group             : 
 * @last modified on  : 04-13-2024
 * @last modified by  : Andrea Da Silva
**/
@isTest
public class AccountUtilTest {

    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        TestUtils.enableTriggers();
        List<User> userList = new List<User>();
        userList.addAll(User_TestDataFactory.createUsers(1, new List<String>{'en_US'}));
        userList.addAll(User_TestDataFactory.createUsersNoAdmin(1, new List<String>{'en_US'}));
        insert userList;
        
        List<Account> accountList =  new List<Account>{
            Account_TestDataFactory.createFabricator(), Account_TestDataFactory.createRetailer(), 
                Account_TestDataFactory.createBusinessAccount(), Account_TestDataFactory.createCustomer()};
        
        accountList[0].Name = 'Account 1';
        accountList[1].Name = 'Account 2';
        accountList[2].Name = 'Account 3';
        
        List<Database.SaveResult> acctsSaveResult = Account_TestDataFactory.insertAccounts(accountList);
        
        AccountTeamMember accteamMember = new AccountTeamMember();
        accteamMember.AccountId = acctsSaveResult.get(0).getId();
        accteamMember.UserId = UserInfo.getUserId();

        insert accteamMember;
    }
    
    /*****************************************************************/
    @isTest static void isInstallerTest() {
        // Test setup
        List<User> users = [select Id from User limit 1];
        List<Account> accounts = [select Id from Account limit 2];        
        UserAccounts__c testRecord = new UserAccounts__c();
        testRecord.Account__c = accounts[0].Id;
        testRecord.User__c = users[0].Id;
        testRecord.Role__c = 'INSTALLER';
        insert testRecord;
        
        System.assert(AccountUtil.isInstaller(accounts[0].Id) == true, 'Installer account not identified as installer in AcccountUtil.isInstaller');
        System.assert(AccountUtil.isInstaller(accounts[1].Id) == false, 'Installer account wrongly identified as installer in AcccountUtil.isInstaller');
        
    } // isInstallerTest
    
    @isTest
    static void mapSalutation() {
        String salutation = 'Mr.';
        System.assertEquals('0002', AccountUtil.mapSalutation(salutation), 'MR. should have been mapped to 0002');
        salutation = 'xxx';
        System.assertEquals('xxx', AccountUtil.mapSalutation(salutation), 'xxx should have not been changed');
    } // mapSalutation
    /*****************************************************************/    
    @isTest
    static void getSAPId() {
        String sap = '0001112223';
        Account acc = [select Id from Account limit 1][0];        
        acc.SAP_Id__c = sap;
        update acc;        
        String sap2 = AccountUtil.getSAPId(acc.Id);
        System.assertEquals(sap, sap2, 'SAP Id not retrieved');
    }
    /*****************************************************************/
    @isTest static void getFromSAPCode() {
        String sap = '0001112223';
        String id18 = AccountUtil.getFromSAPCode(sap);
        System.assertEquals('', id18, 'Should be empty');
    }
    /*****************************************************************/    
    @isTest
    static void getName() {
        Account acc = [select Id, Name from Account limit 1][0];        
        String name = AccountUtil.getName(acc.Id);
        System.assertEquals(acc.Name, name, 'Wrong name');
    }
    /****************************************************************/
    @isTest static void getContacts() {
        Account acc = [select Id, Name from Account limit 1][0];        
        List<Contact> contacts = AccountUtil.getContacts(acc.Id);
        System.assertEquals(0, contacts.size(), ' No contacts should be found');

    }
    /****************************************************************/
    @isTest static void getTeamMembersAccountsId() {
        List<Account> allAcc = [select Id, Name, OwnerId from Account];
        List<Id> accountsId = AccountUtil.getTeamMembersAccountsId();
        System.assertEquals(1, accountsId.size(), ' Accounts from team members should be returned');

    }
    /****************************************************************/
    @isTest static void getRelatedContacts() {
        Account acc = [select Id, Name from Account limit 1][0];
        DataFactoryContact.createContacts(acc.Id, 2);
        List<Contact> contacts = AccountUtil.getRelatedContacts(acc.Id);
        System.assertEquals(2, contacts.size(), 'Two contacts should be found');

    }
}