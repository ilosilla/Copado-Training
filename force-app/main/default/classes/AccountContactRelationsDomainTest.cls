@isTest
public class AccountContactRelationsDomainTest {
    @isTest
    static void createRegister() {
        List<Account> accs = DataFactoryAccount.createBusinessAccounts(3);
        List<Contact> contactsAccount = DataFactoryContact.createContacts(accs[0].Id, 2);
        
        contactsAccount[1].AccountId = accs[1].Id;
        update contactsAccount[1];
        accs[2].Last_Activity_Date__c = System.today().addDays(-4);
        update accs[2];
        
        Test.startTest();
            insert new AccountContactRelation(AccountId = accs[2].Id, ContactId = contactsAccount[0].Id);
        Test.stopTest();
	
        System.debug([SELECT Id, Last_Activity_Date__c FROM Account]);
        Account acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: accs[2].Id];
        Assert.isFalse(acc.Last_Activity_Date__c == null, 'Debería haberse actualizado el Last Activity date');
    }
}