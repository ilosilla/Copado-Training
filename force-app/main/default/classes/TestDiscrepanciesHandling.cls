@isTest
public with sharing class TestDiscrepanciesHandling {
    
    @TestSetup
    static void makeData(){

        List<Account> accounts = new List<Account>();

        Account acc1 = new Account(
            Name = 'Company 1',
            BillingStreet = '1 rue de la Paix',
            BillingPostalCode = '33000',
            BillingCity = 'Bordeaux',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0612345678',
            SynchronizedWithDvs__c = false
            );
        accounts.add(acc1);

        Account acc2 = new Account(
            Name = 'Company 2',
            BillingStreet = '45 avenue Frédéric Mistral',
            BillingPostalCode = '06130',
            BillingCity = 'Grasse',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0702161419',
            SynchronizedWithDvs__c = false
            );
        accounts.add(acc2);

        Account acc3 = new Account(
            Name = 'Company 3',
            BillingStreet = '5 place du Sergent Lebouc',
            BillingPostalCode = '72100',
            BillingCity = 'Le Mans',
            BillingCountry = 'France',
            BillingCountryCode = 'FR',
            Phone = '0658987412',
            SynchronizedWithDvs__c = false
            );
        accounts.add(acc3);

        insert accounts;
        
        List<DvsDiscrepancy__c> discrepancies = new List<DvsDiscrepancy__c>();

        DvsDiscrepancy__c discrepancy1 = new DvsDiscrepancy__c(
            DvsName__c = 'Company 1',
            DvsStreet__c = '1 rue de la Paix',
            DvsPostalCode__c = '33000',
            DvsCity__c = 'Bordeaux',
            DvsId__c = '50747059800024',
            DvsId2__c = '507470598',
            SalesforceName__c = 'Company 1',
            SalesforceStreet__c = '1 rue de la Paix',
            SalesforcePostalCode__c = '33000',
            SalesforceCity__c = 'Bordeaux',
            SalesforceCountryCode__c = 'FR',
            Account__c = acc1.Id
        );

        discrepancies.add(discrepancy1);

        DvsDiscrepancy__c discrepancy2 = new DvsDiscrepancy__c(
            DvsName__c = 'SARL Company 2',
            DvsStreet__c = '45 avenue Frédéric Mistral',
            DvsPostalCode__c = '06130',
            DvsCity__c = 'Grasse',
            DvsId__c = '95614275600019',
            DvsId2__c = '956142756',
            SalesforceName__c = 'Company 2',
            SalesforceStreet__c = '45 avenue Frédéric Mistral',
            SalesforcePostalCode__c = '06130',
            SalesforceCity__c = 'Grasse',
            SalesforceCountryCode__c = 'FR',
            Account__c = acc2.Id
        );

        discrepancies.add(discrepancy2);

        DvsDiscrepancy__c discrepancy3 = new DvsDiscrepancy__c(
            DvsName__c = 'Company 3',
            DvsStreet__c = '19 place du Sergent Lebouc',
            DvsPostalCode__c = '72100',
            DvsCity__c = 'Le Mans',
            DvsId__c = '15634952100016',
            DvsId2__c = '156349521',
            SalesforceName__c = 'Company 3',
            SalesforceStreet__c = '5 place du Sergent Lebouc',
            SalesforcePostalCode__c = '72100',
            SalesforceCity__c = 'Le Mans',
            SalesforceCountryCode__c = 'FR',
            Account__c = acc3.Id
        );

        discrepancies.add(discrepancy3);
        insert discrepancies;

    }

    @isTest
    public static void testCorrectDiscrepancy() {

        // In org context the trigger DvsAccountTrigger will be triggered but will be ignored
        // With this varibale the trigger is going to be ignored to reproduce the expected behavior
        
        List<DvsDiscrepancy__c> discrepancies = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.areEqual(1, discrepancies.size());

        Account acc1 = getAccount('Company 1');
        Assert.isNull(acc1.VAT_Number__c);
        Assert.isNull(acc1.VAT_Number_2__c);
        Assert.isFalse(acc1.SynchronizedWithDvs__c);

        List<List<Id>> selectedRecordIds = new List<List<Id>>{new List<Id>{discrepancies[0].Id}};

        Test.startTest();
        DvsDiscrepanciesInfoCorrection.correctDvsDiscrepanciesInfo(selectedRecordIds);
        Test.stopTest();

        Account accAfterCorrection = getAccount('Company 1');
        Assert.areEqual('50747059800024', accAfterCorrection.VAT_Number__c);
        Assert.areEqual('507470598',accAfterCorrection.VAT_Number_2__c);
        Assert.isTrue(accAfterCorrection.SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesAfterCorrection = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.isTrue(discrepanciesAfterCorrection.size() == 0);
    }

    @isTest
    public static void testCorrectDiscrepancies() {

        // In org context the trigger DvsAccountTrigger will be triggered but will be ignored
        // With this varibale the trigger is going to be ignored to reproduce the expected behavior
        
        List<DvsDiscrepancy__c> discrepancies = [SELECT Id FROM DvsDiscrepancy__c];
        Assert.areEqual(3, discrepancies.size());

        List<Account> accounts = getAccounts();
        Assert.areEqual(3, accounts.size());

        Assert.isNull(accounts[0].VAT_Number__c);
        Assert.isNull(accounts[0].VAT_Number_2__c);
        Assert.isFalse(accounts[0].SynchronizedWithDvs__c);

        Assert.isNull(accounts[1].VAT_Number__c);
        Assert.isNull(accounts[1].VAT_Number_2__c);
        Assert.isFalse(accounts[1].SynchronizedWithDvs__c);

        Assert.isNull(accounts[2].VAT_Number__c);
        Assert.isNull(accounts[2].VAT_Number_2__c);
        Assert.isFalse(accounts[2].SynchronizedWithDvs__c);

        List<List<Id>> selectedRecordIds = new List<List<Id>>{new List<Id>{discrepancies[0].Id, discrepancies[1].Id, discrepancies[2].Id}};

        Test.startTest();
        DvsDiscrepanciesInfoCorrection.correctDvsDiscrepanciesInfo(selectedRecordIds);
        Test.stopTest();

        List<Account> accountsAfterCorrection = getAccounts();
        Assert.areEqual('COMPANY 1', accountsAfterCorrection[0].Name);
        Assert.areEqual('50747059800024', accountsAfterCorrection[0].VAT_Number__c);
        Assert.areEqual('507470598',accountsAfterCorrection[0].VAT_Number_2__c);
        Assert.isTrue(accountsAfterCorrection[0].SynchronizedWithDvs__c);

        Assert.areEqual('COMPANY 3', accountsAfterCorrection[1].Name);
        Assert.areEqual('19 place du Sergent Lebouc', accountsAfterCorrection[1].BillingStreet);
        Assert.areEqual('15634952100016', accountsAfterCorrection[1].VAT_Number__c);
        Assert.areEqual('156349521',accountsAfterCorrection[1].VAT_Number_2__c);
        Assert.isTrue(accountsAfterCorrection[1].SynchronizedWithDvs__c);

        Assert.areEqual('SARL COMPANY 2', accountsAfterCorrection[2].Name);
        Assert.areEqual('95614275600019', accountsAfterCorrection[2].VAT_Number__c);
        Assert.areEqual('956142756',accountsAfterCorrection[2].VAT_Number_2__c);
        Assert.isTrue(accountsAfterCorrection[2].SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesAfterCorrection = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.isTrue(discrepanciesAfterCorrection.size() == 0);
    }

    @isTest
    public static void testIgnoreDiscrepancy() {


        List<DvsDiscrepancy__c> discrepancies = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.areEqual(1, discrepancies.size());

        Account acc1 = getAccount('Company 1');
        Assert.isNull(acc1.VAT_Number__c);
        Assert.isNull(acc1.VAT_Number_2__c);
        Assert.isFalse(acc1.SynchronizedWithDvs__c);

        List<List<Id>> selectedRecordIds = new List<List<Id>>{new List<Id>{discrepancies[0].Id}};

        Test.startTest();
        DvsDiscrepanciesInfoIgnore.ignoreDvsDiscrepanciesInfo(selectedRecordIds);
        Test.stopTest();

        Account accAfterIgnoreAction = getAccount('Company 1');
        Assert.isNull(accAfterIgnoreAction.VAT_Number__c);
        Assert.isNull(accAfterIgnoreAction.VAT_Number_2__c);
        Assert.isTrue(accAfterIgnoreAction.SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesAfterCorrection = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.isTrue(discrepanciesAfterCorrection.size() == 0);
    }

    @isTest
    public static void testIgnoreDiscrepancies() {


        List<DvsDiscrepancy__c> discrepancies = [SELECT Id FROM DvsDiscrepancy__c];
        Assert.areEqual(3, discrepancies.size());

        List<Account> accounts = getAccounts();
        Assert.areEqual(3, accounts.size());

        Assert.isNull(accounts[0].VAT_Number__c);
        Assert.isNull(accounts[0].VAT_Number_2__c);
        Assert.isFalse(accounts[0].SynchronizedWithDvs__c);

        Assert.isNull(accounts[1].VAT_Number__c);
        Assert.isNull(accounts[1].VAT_Number_2__c);
        Assert.isFalse(accounts[1].SynchronizedWithDvs__c);

        Assert.isNull(accounts[2].VAT_Number__c);
        Assert.isNull(accounts[2].VAT_Number_2__c);
        Assert.isFalse(accounts[2].SynchronizedWithDvs__c);

        List<List<Id>> selectedRecordIds = new List<List<Id>>{new List<Id>{discrepancies[0].Id, discrepancies[1].Id, discrepancies[2].Id}};

        Test.startTest();
        DvsDiscrepanciesInfoIgnore.ignoreDvsDiscrepanciesInfo(selectedRecordIds);
        Test.stopTest();

        List<Account> accountsAfterIgnoreAction = getAccounts();
        Assert.isNull(accountsAfterIgnoreAction[0].VAT_Number__c);
        Assert.isNull(accountsAfterIgnoreAction[0].VAT_Number_2__c);
        Assert.isTrue(accountsAfterIgnoreAction[0].SynchronizedWithDvs__c);

        Assert.areEqual('COMPANY 2', accountsAfterIgnoreAction[1].Name);
        Assert.isNull(accountsAfterIgnoreAction[1].VAT_Number__c);
        Assert.isNull(accountsAfterIgnoreAction[1].VAT_Number_2__c);
        Assert.isTrue(accountsAfterIgnoreAction[1].SynchronizedWithDvs__c);

        Assert.areEqual('5 place du Sergent Lebouc', accountsAfterIgnoreAction[2].BillingStreet);
        Assert.isNull(accountsAfterIgnoreAction[2].VAT_Number__c);
        Assert.isNull(accountsAfterIgnoreAction[2].VAT_Number_2__c);
        Assert.isTrue(accountsAfterIgnoreAction[2].SynchronizedWithDvs__c);

        List<DvsDiscrepancy__c> discrepanciesAfterCorrection = [SELECT Id FROM DvsDiscrepancy__c WHERE DvsName__c = 'Company 1'];
        Assert.isTrue(discrepanciesAfterCorrection.size() == 0);
    }

    public static Account getAccount(String accountName) {
        return [SELECT 
                    Id, 
                    Name, 
                    BillingCity, 
                    BillingCountryCode, 
                    BillingPostalCode, 
                    BillingStreet, 
                    VAT_Number__c, 
                    VAT_Number_2__c,
                    SynchronizedWithDvs__c,
                    Phone
                FROM Account
                WHERE Name = :accountName
                ];
    }

    public static List<Account> getAccounts() {
        return [SELECT 
                    Id, 
                    Name, 
                    BillingCity, 
                    BillingCountryCode, 
                    BillingPostalCode, 
                    BillingStreet, 
                    VAT_Number__c, 
                    VAT_Number_2__c,
                    SynchronizedWithDvs__c,
                    Phone
                FROM Account
                ORDER BY Name ASC
                ];
    }
}