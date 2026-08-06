@IsTest
private class Test_ContactsUtil {

    @TestSetup
    static void makeData(){
        DataFactoryAccount.createPersonAccounts(1);
    }
    
    @IsTest
    static void test_selectPersonAccountContactByAccountId() {
        List<Account> existingAccounts = [SELECT Id FROM Account];
        Assert.isFalse(existingAccounts.isEmpty(), 'La lista de cuentas no deberia estar vacia');
        Account acc = existingAccounts.get(0);

        List<Contact> existingAccountContacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
        Assert.isFalse(existingAccountContacts.isEmpty(), 'La lista de contactos no deberia estar vacia');
        Contact cont = existingAccountContacts.get(0);

        Test.startTest();
        Contact matchedCont = ContactsUtil.selectPersonAccountContactByAccountId(acc.Id);
        Test.stopTest();

        Assert.areNotEqual(null, matchedCont, 'Se deberia haber encontrado un contacto');
        Assert.areEqual(cont.Id, matchedCont.Id);
    }

}