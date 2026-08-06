@isTest public with sharing class TypeConversionCommonsTest {
    
    @TestSetup static void makeData(){
        TestUtils.enableTriggers();        
    }

    @isTest private static void extractList() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        List<Id> ids = TypeConversionCommons.extractListOfIds(accounts);
        System.assertEquals(accounts.size(), ids.size(), 'The size of the returned list should be equal to the size of the objects list');
        System.assertEquals(accounts[0].Id, ids[0], 'Id of the first element should match');
    }

    @isTest private static void extractFieldValues() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        List<String> result1 = TypeConversionCommons.extractFieldValues(accounts, 'Id');
        Assert.areEqual(accounts.size(), result1.size(), 'Lists should have the same size');
        List<String> result2 = TypeConversionCommons.extractFieldValues(accounts, 'Name');
        Assert.areEqual(accounts[0].Name, result2[0], 'Name should be the same');
    }
    
    @isTest private static void listToSet() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        Set<Id> ids = TypeConversionCommons.listToSet(accounts);
        System.assertEquals(accounts.size(), ids.size(), 'All ids should have been copied to the set');
    }

    @isTest private static void listToSet2() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        Set<String> names = (Set<String>) TypeConversionCommons.listToSet(accounts, 'Name');
        System.assertEquals(accounts.size(), names.size(), 'All ids should have been copied to the set');
    }
    
    @isTest private static void testEnglishToBoolean_1() {
        // 1
        String str = 'yes';
        Boolean result = TypeConversionCommons.englishToBoolean(str);
        System.assertEquals(true, result, '"yes" should have returned true');

        //2
        str = 'n';
        result = TypeConversionCommons.englishToBoolean(str);
        System.assertEquals(false, result, '"n" should have returned false');

        // 3
        str = null;
        result = TypeConversionCommons.englishToBoolean(str);
        System.assertEquals(false, result, '<null> should have returned false');

        // 4
        str = '    ';
        result = TypeConversionCommons.englishToBoolean(str);
        System.assertEquals(false, result,'<blanks> should have returned false');
    }

    @isTest private static void booleanToLabelTest() {
        String noLabel = Label.dict_no;
        String yesLabel = Label.dict_yes;

        String result = TypeConversionCommons.booleanToLabel(true);
        System.assertEquals(yesLabel, result, 'true should have been ' + yesLabel);
        
        result = TypeConversionCommons.booleanToLabel(false);
        System.assertEquals(noLabel, result, 'false should have been ' + noLabel);
        
    } // booleanToWord
    
    @isTest private static void listToMap() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        Map<Id, SObject> mapAccs = TypeConversionCommons.listToMap(accounts);
        System.assertEquals(accounts.size(), mapAccs.size(), 'All ids should have been copied to the Map');
        System.assertEquals(mapAccs.containsKey(accounts[0].Id), true,  'All ids should have been copied to the Map');
    }

    @isTest private static void testListToMap2() {
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(10);
        String testName = accounts[0].Name;
        Map<String, SObject> mapAccounts = TypeConversionCommons.listToMap(accounts, 'Name', true);
        Assert.isTrue(mapAccounts.size() > 0, 'Map should not be empty');
        Assert.isNull(mapAccounts.get(testName.toLowerCase()), 'No result expected');
        Account acc = (Account) mapAccounts.get(testName.toUpperCase());
        Assert.isNotNull(acc, 'A result expected for ');
        Assert.areEqual(testName, acc.Name, 'Name should be the equal to the test one');
    }

    @isTest private static void deNullify() {
        String s = null;
        Assert.areEqual('', TypeConversionCommons.deNullify(s));
        s = 'Hola';
        Assert.areEqual(s, TypeConversionCommons.deNullify(s));
    }

} // class