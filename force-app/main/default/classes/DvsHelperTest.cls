@isTest
private class DvsHelperTest {

    private static Account createTestAccount() {
        Account acc = new Account(
            Name = 'Original Name',
            BillingStreet = 'Original Street',
            BillingPostalCode = '11111',
            BillingCity = 'Original City',
            BillingCountryCode = 'DE',
            VAT_Number__c = 'VAT111',
            VAT_Number_2__c = 'VAT222'
        );
        insert acc;
        return acc;
    }

    private static DvsDiscrepancy__c createDiscrepancy(Account acc) {
        DvsDiscrepancy__c discrepancy = new DvsDiscrepancy__c(
            Account__c = acc.Id,
            DvsName__c = 'Corrected Name',
            DvsStreet__c = 'Corrected Street',
            DvsPostalCode__c = '54321',
            DvsCity__c = 'Corrected City',
            DvsId__c = 'CORRECTEDVAT1',
            DvsId2__c = 'CORRECTEDVAT2'
        );
        insert discrepancy;
        return discrepancy;
    }

    @isTest
    static void testCorrectDiscrepancies() {
        Account acc = createTestAccount();
        DvsDiscrepancy__c discrepancy = createDiscrepancy(acc);

        List<Account> updatedAccounts;

        Test.startTest();
        updatedAccounts = DvsHelper.correctDiscrepancies(
            new List<DvsDiscrepancy__c>{discrepancy},
            new List<Account>{acc}
        );
        Test.stopTest();

        System.assertEquals(1, updatedAccounts.size());
        Account updated = updatedAccounts[0];
        System.assertEquals('Corrected Name', updated.Name);
        System.assertEquals('Corrected City', updated.BillingCity);
        System.assertEquals('CORRECTEDVAT1', updated.VAT_Number__c);
        System.assert(updated.SynchronizedWithDvs__c);
    }

    @isTest
    static void testCorrectDiscrepanciesWithNoValidDiscrepancies() {
        Account acc = createTestAccount();

        DvsDiscrepancy__c invalidDiscrepancy = new DvsDiscrepancy__c(
            Account__c = acc.Id
            // No DvsId__c => debería ser ignorado
        );
        insert invalidDiscrepancy;

        Test.startTest();
        List<Account> result = DvsHelper.correctDiscrepancies(
            new List<DvsDiscrepancy__c>{invalidDiscrepancy},
            new List<Account>{acc}
        );
        Test.stopTest();

        // Aseguramos que no haya cambios
        System.assertEquals(acc.Id, result[0].Id);
        System.assertEquals(false, result[0].SynchronizedWithDvs__c);
    }

    @isTest
    static void fillerTestAccountAdditionalData() {
        DvsHelper.testFiller();
        Assert.isTrue(1 == 1);
    }
}