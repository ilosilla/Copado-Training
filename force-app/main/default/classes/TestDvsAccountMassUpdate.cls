@isTest
public with sharing class TestDvsAccountMassUpdate {
  

    @TestSetup
    static void makeData(){
        
        List<Account> accountList = new List<Account>();

        Account acc1 = new Account(
            Name = 'HUGO LEMAITRE',
            BillingStreet = '1 avenue de la Paix',
            BillingCity = 'Bordeaux',
            BillingPostalCode = '33000',
            BillingCountry = 'France'
        );
        
        accountList.add(acc1);

        Account acc2 = new Account(
            Name = 'ARCHITECTE DESIGN',
            BillingStreet = '2 rue des étoiles',
            BillingCity = 'Le Mans',
            BillingPostalCode = '72000',
            VAT_Number_2__c = '303376586',
            BillingCountry = 'France'

        );
        
        accountList.add(acc2);

        Account acc3 = new Account(
            Name = 'L\'HOTEL LES GRANDS FLOTS',
            BillingStreet = '3 place des Grands Flots',
            BillingCity = 'Nice',
            BillingPostalCode = '06000',
            BillingCountry = 'France'

        );
        
        accountList.add(acc3);

        Account acc4 = new Account(
            Name = 'CAMPING LES PAPILLONS',
            BillingStreet = 'Carnie',
            BillingCity = 'Aspet',
            BillingPostalCode = '31160',
            BillingCountry = 'France'

        );
        
        accountList.add(acc4);
        insert accountList;

        List<DvsDiscrepancy__c> discrepancies = new List<DvsDiscrepancy__c>();

        DvsDiscrepancy__c discrepancy1 = new DvsDiscrepancy__c(
            Account__c = acc1.Id,
            DvsName__c = 'HUGO LEMAITRE',
            DvsStreet__c = '24 rue de la paix',
            DvsPostalCode__c = '33000',
            DvsCity__c = 'Bordeaux',
            DvsId__c = '43336871900046',
            DvsId2__c = '433368719',
            SalesforceName__c = 'HUGO LEMAITRE',
            SalesforceStreet__c = '1 avenue de la Paix',
            SalesforcePostalCode__c = '33000',
            SalesforceCity__c = 'Bordeaux'
        );
        discrepancies.add(discrepancy1);

        DvsDiscrepancy__c discrepancy2 = new DvsDiscrepancy__c(
            Account__c = acc2.Id,
            DvsName__c = 'BUREAU ARCHITECTE DESIGN',
            DvsStreet__c = '2 rue des étoiles',
            DvsPostalCode__c = '72000',
            DvsCity__c = 'Le Mans',
            DvsId__c = '30337658600085',
            DvsId2__c = '303376586',
            SalesforceName__c = 'ARCHITECTE DESIGN',
            SalesforceStreet__c = '2 rue des étoiles',
            SalesforcePostalCode__c = '72000',
            SalesforceCity__c = 'Le Mans',
            SalesforceId2__c = '303376586'
        );
        discrepancies.add(discrepancy2);

        DvsDiscrepancy__c discrepancy3 = new DvsDiscrepancy__c(
            Account__c = acc3.Id,
            DvsName__c = 'LES GRANDS FLOTS',
            DvsStreet__c = 'Cours Saleya',
            DvsPostalCode__c = '06000',
            DvsCity__c = 'Nice',
            DvsId__c = '35020619900019',
            DvsId2__c = '350206199',
            SalesforceName__c = 'L\'HOTEL LES GRANDS FLOTS',
            SalesforceStreet__c = '3 place des Grands Flots',
            SalesforcePostalCode__c = '06000',
            SalesforceCity__c = 'Nice'
        );
        discrepancies.add(discrepancy3);

        DvsDiscrepancy__c discrepancy4 = new DvsDiscrepancy__c(
            Account__c = acc4.Id,
            SalesforceName__c = 'CAMPING LES PAPILLONS',
            SalesforceStreet__c = 'Carnie',
            SalesforcePostalCode__c = '31160',
            SalesforceCity__c = 'Aspet'
        );
        discrepancies.add(discrepancy4);

        insert discrepancies;

        List<DvsAccountInfo__c> dvsAccountInfoList = new List<DvsAccountInfo__c>();
        DvsAccountInfo__c dvsAccountInfo1 = new DvsAccountInfo__c(
            Account__c = acc1.Id,
            PreviousName__c = 'HUGO LEMAITRE',
            PreviousStreet__c = '1 avenue de la Paix',
            PreviousPostalCode__c = '33000',
            PreviousCity__c = 'Bordeaux',
            ProcessedTime__c = Datetime.newInstance(2024, 01, 01, 00, 00, 00)
        );

        dvsAccountInfoList.add(dvsAccountInfo1);   
        insert dvsAccountInfoList;
    }

    @isTest
    private static void testBatch() {

        List<DvsAccountInfo__c> dvsAccountInfoListBefore = getDvsAccountInfo();
        Assert.areEqual(1, dvsAccountInfoListBefore.size());

        List<DvsDiscrepancy__c> dvsDiscrepanciesBefore = getDvsDiscrepancies();
        Assert.areEqual(4, dvsDiscrepanciesBefore.size());

        Test.startTest();
        DvsAccountsMassUpdateBatchController batch = new DvsAccountsMassUpdateBatchController();
        Database.executeBatch(batch);
        Test.stopTest();

        List<DvsDiscrepancy__c> dvsDiscrepanciesAfter = getDvsDiscrepancies();
        Assert.areEqual(1, dvsDiscrepanciesAfter.size());

        List<Account> accounts = getAccounts();
        Assert.areEqual(4, accounts.size());

        Account acc1 = accounts[0]; //Bureau architecte design
        Account acc2 = accounts[1]; //Camping les papillons
        Account acc3 = accounts[2]; //Hugo Lemaitre
        Account acc4 = accounts[3]; //Les Grands flots

        Assert.areEqual('BUREAU ARCHITECTE DESIGN', acc1.Name);
        Assert.areEqual('2 rue des étoiles', acc1.BillingStreet);
        Assert.areEqual('72000', acc1.BillingPostalCode);
        Assert.areEqual('Le Mans', acc1.BillingCity);
        Assert.areEqual('30337658600085', acc1.VAT_Number__c);
        Assert.areEqual('303376586', acc1.VAT_Number_2__c);
        Assert.isTrue(acc1.SynchronizedWithDvs__c);

        Assert.isFalse(acc2.SynchronizedWithDvs__c);

        Assert.areEqual('HUGO LEMAITRE', acc3.Name);
        Assert.areEqual('24 rue de la paix', acc3.BillingStreet);
        Assert.areEqual('33000', acc3.BillingPostalCode);
        Assert.areEqual('Bordeaux', acc3.BillingCity);
        Assert.areEqual('43336871900046', acc3.VAT_Number__c);
        Assert.areEqual('433368719', acc3.VAT_Number_2__c);
        Assert.isTrue(acc3.SynchronizedWithDvs__c);

        Assert.areEqual('LES GRANDS FLOTS', acc4.Name);
        Assert.areEqual('Cours Saleya', acc4.BillingStreet);
        Assert.areEqual('06000', acc4.BillingPostalCode);
        Assert.areEqual('Nice', acc4.BillingCity);
        Assert.areEqual('35020619900019', acc4.VAT_Number__c);
        Assert.areEqual('350206199', acc4.VAT_Number_2__c);
        Assert.isTrue(acc4.SynchronizedWithDvs__c);


        List<DvsAccountInfo__c> dvsAccountInfoListAfter = getDvsAccountInfo();
        Assert.areEqual(3, dvsAccountInfoListAfter.size());

        DvsAccountInfo__c dvsAccountInfo1 = dvsAccountInfoListAfter[0];
        DvsAccountInfo__c dvsAccountInfo2 = dvsAccountInfoListAfter[1];
        DvsAccountInfo__c dvsAccountInfo3 = dvsAccountInfoListAfter[2];

        Assert.areEqual('ARCHITECTE DESIGN', dvsAccountInfo1.PreviousName__c);
        Assert.areEqual('2 rue des étoiles', dvsAccountInfo1.PreviousStreet__c);
        Assert.areEqual('Le Mans', dvsAccountInfo1.PreviousCity__c);
        Assert.areEqual('72000', dvsAccountInfo1.PreviousPostalCode__c);
        Assert.isNull(dvsAccountInfo1.PreviousId1__c);
        Assert.areEqual('303376586', dvsAccountInfo1.PreviousId2__c);
        Assert.isNotNull(dvsAccountInfo1.ProcessedTime__c);

        Assert.areEqual('HUGO LEMAITRE', dvsAccountInfo2.PreviousName__c);
        Assert.areEqual('1 avenue de la Paix', dvsAccountInfo2.PreviousStreet__c);
        Assert.areEqual('Bordeaux', dvsAccountInfo2.PreviousCity__c);
        Assert.areEqual('33000', dvsAccountInfo2.PreviousPostalCode__c);
        Assert.isNull(dvsAccountInfo2.PreviousId1__c);
        Assert.isNull(dvsAccountInfo2.PreviousId2__c);
        Assert.isNotNull(dvsAccountInfo2.ProcessedTime__c);

        Assert.areEqual('L\'HOTEL LES GRANDS FLOTS', dvsAccountInfo3.PreviousName__c);
        Assert.areEqual('3 place des Grands Flots', dvsAccountInfo3.PreviousStreet__c);
        Assert.areEqual('Nice', dvsAccountInfo3.PreviousCity__c);
        Assert.areEqual('06000', dvsAccountInfo3.PreviousPostalCode__c);
        Assert.isNull(dvsAccountInfo3.PreviousId1__c);
        Assert.isNull(dvsAccountInfo3.PreviousId2__c);
        Assert.isNotNull(dvsAccountInfo3.ProcessedTime__c);

    }

    private static List<Account> getAccounts() {
        return [SELECT Id,
                        Name, 
                        BillingStreet, 
                        BillingPostalCode,
                        BillingCountryCode,
                        BillingCity,
                        VAT_Number__c,
                        VAT_Number_2__c,
                        SynchronizedWithDvs__c
                FROM Account
                ORDER BY Name ASC];
    }

    private static List<DvsAccountInfo__c> getDvsAccountInfo() {
        
        return [SELECT Id, 
                        Account__c,
                        PreviousName__c,
                        PreviousStreet__c,
                        PreviousPostalCode__c,
                        PreviousCity__c,
                        PreviousId1__c,
                        PreviousId2__c,
                        ProcessedTime__c
                FROM DvsAccountInfo__c
                ORDER BY PreviousName__c ASC];
    }

    private static List<DvsDiscrepancy__c> getDvsDiscrepancies() {

        return [SELECT Id
                FROM DvsDiscrepancy__c];
    }
}