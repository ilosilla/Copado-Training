@isTest
public class ScriptSirenPartnerBatchTest {

    @isTest static void testBatchExecution_createsAndCleansPartners() {
        // Crear cuentas de prueba con el mismo VAT_Number_2__c (SIREN)
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(3);
        accounts[0].Name = 'Empresa 1';
        accounts[0].VAT_Number_2__c = 'A1';
        accounts[0].VAT_Number__c = '123456789';
        accounts[0].Business_Email__c = 'a@test.com';
        accounts[0].DVSAction__c = 'CONFIRMED';
        accounts[0].BillingCountryCode =  'FR';
        accounts[0].BillingPostalCode =  '11234';
        accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

        accounts[1].Name = 'Empresa 2';
        accounts[1].VAT_Number_2__c = 'B1';
        accounts[1].VAT_Number__c = '987654321';
        accounts[1].DVSAction__c = 'CONFIRMED';
        accounts[1].BillingCountryCode =  'FR';
        accounts[1].Business_Email__c = 'b@test.com';
        accounts[1].BillingPostalCode =  '12334';
        accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);


        accounts[2].Name = 'Empresa 3';
        accounts[2].VAT_Number_2__c = 'A1';
        accounts[2].VAT_Number__c = '987654321';
        accounts[2].Business_Email__c = 'a@test.com';
        accounts[2].DVSAction__c = 'CONFIRMED';
        accounts[2].BillingCountryCode =  'FR';
        accounts[2].BillingPostalCode =  '22234';
        accounts[2].DvsAcceptedDate__c = Date.newInstance(2024, 9, 15);

        // Create a contact with matching email for acc3
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'a@test.com', AccountId = accounts[2].Id);
        insert con;

        update accounts;

        Test.startTest();
        ScriptSirenPartnerBatch batch = new ScriptSirenPartnerBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Check Partner records
        List<Partner> partners = [SELECT AccountFromId, AccountToId FROM Partner];
        System.assertEquals(2, partners.size(), 'Two bidirectional relations should be created for VAT match and email match');
    }

    @isTest static void testBatchExecution_createsAndCleansPartners_2() {
        // Crear cuentas de prueba con el mismo VAT_Number_2__c (SIREN)
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(3);
        accounts[0].Name = 'Empresa 1';
        accounts[0].VAT_Number_2__c = 'A1';
        accounts[0].VAT_Number__c = '123456789';
        accounts[0].Business_Email__c = 'a@test.com';
        accounts[0].DVSAction__c = 'CONFIRMED';
        accounts[0].BillingCountryCode =  'FR';
        accounts[0].BillingPostalCode =  '11234';
        accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

        accounts[1].Name = 'Empresa 2';
        accounts[1].VAT_Number_2__c = 'B1';
        accounts[1].VAT_Number__c = '123456789';
        accounts[1].DVSAction__c = 'CONFIRMED';
        accounts[1].BillingCountryCode =  'FR';
        accounts[1].Business_Email__c = 'b@test.com';
        accounts[1].BillingPostalCode =  '12334';
        accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);


        accounts[2].Name = 'Empresa 3';
        accounts[2].VAT_Number_2__c = 'A1';
        accounts[2].VAT_Number__c = '987654321';
        accounts[2].Business_Email__c = 'a@test.com';
        accounts[2].DVSAction__c = 'CONFIRMED';
        accounts[2].BillingCountryCode =  'FR';
        accounts[2].BillingPostalCode =  '22234';
        accounts[2].DvsAcceptedDate__c = Date.newInstance(2024, 9, 15);

        // Create a contact with matching email for acc3
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'a@test.com', AccountId = accounts[2].Id);
        insert con;

        update accounts;

        // Insert a duplicate to simulate dirty data
        insert new Partner(AccountFromId = accounts[0].Id, AccountToId = accounts[1].Id);
        insert new Partner(AccountFromId = accounts[1].Id, AccountToId = accounts[0].Id);

        Test.startTest();
        Database.executeBatch(new ScriptSirenPartnerBatch(), 200);
        Test.stopTest();

        // Should clean duplicates
        Integer countAfter = [SELECT count() FROM Partner WHERE (AccountFromId = :accounts[0].Id AND AccountToId = :accounts[1].Id) OR (AccountFromId = :accounts[1].Id AND AccountToId = :accounts[0].Id)];
        System.assertEquals(2, countAfter, 'Should keep only 1 pair in each direction');
    }

    @isTest static void testBlockedEmailIsIgnored() {
       // Crear cuentas de prueba con el mismo VAT_Number_2__c (SIREN)
       PorcelanosaSetting__c aux = new PorcelanosaSetting__c(key__c='EMAIL', subkey__c='INVALIDWORDS', value1__c = 'noemail;porsa;prueba;fake;nomail;porcelanosa;no.email;test;xxx;gg.;noenail;nono;xtone;aaaa');
       insert aux;

       List<Account> accounts = DataFactoryAccount.createBusinessAccounts(2);
       accounts[0].Name = 'Empresa 1';
       accounts[0].VAT_Number_2__c = '111';
       accounts[0].VAT_Number__c = '1234562789';
       accounts[0].Business_Email__c = 'noemail@test.com';
       accounts[0].DVSAction__c = 'CONFIRMED';
       accounts[0].BillingCountryCode =  'FR';
       accounts[0].BillingPostalCode =  '11234';
       accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

       accounts[1].Name = 'Empresa 2';
       accounts[1].VAT_Number_2__c = '222';
       accounts[1].VAT_Number__c = '12342256789';
       accounts[1].DVSAction__c = 'CONFIRMED';
       accounts[1].BillingCountryCode =  'FR';
       accounts[1].Business_Email__c = 'noemail@test.com';
       accounts[1].BillingPostalCode =  '12334';
       accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);
       update accounts;

        Test.startTest();
        ScriptSirenPartnerBatch batch = new ScriptSirenPartnerBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // No partner should be created due to blocked email
        List<Partner> partners = [SELECT Id FROM Partner];
        System.assertEquals(0, partners.size(), 'Blocked emails should not generate partner relations');
    }
}