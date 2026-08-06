@isTest
public class ScriptEmailPartnerBatchTest {

    @isTest static void allRelated() {
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(key__c='EMAIL', subkey__c='GENERICDOMAINS', value1__c = 'pipo.com');
       insert aux;
        // Crear cuentas de prueba con el mismo VAT_Number_2__c (SIREN)
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(3);
        accounts[0].Name = 'Empresa 1';
        accounts[0].Business_Email__c = 'abbbbcccc@monster.com';
        accounts[0].DVSAction__c = 'CONFIRMED';
        accounts[0].BillingCountryCode =  'FR';
        accounts[0].BillingPostalCode =  '66677';
        accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

        accounts[1].Name = 'Empresa 2';
        accounts[1].DVSAction__c = 'CONFIRMED';
        accounts[1].BillingCountryCode =  'IT';
        accounts[1].Business_Email__c = 'bcccdddd@monster.com';
        accounts[1].BillingPostalCode =  '11111';
        accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);

        accounts[2].Name = 'Empresa 3';
        accounts[2].Business_Email__c = 'atttyyyhhh@monster.com';
        accounts[2].DVSAction__c = 'CONFIRMED';
        accounts[2].BillingCountryCode =  'GB';
        accounts[2].BillingPostalCode =  'LA22 9NZ';
        accounts[2].DvsAcceptedDate__c = Date.newInstance(2024, 9, 15);

        // Create a contact with matching email for acc3
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'a@monster.com', AccountId = accounts[2].Id);
        insert con;

        update accounts;

        Test.startTest();
        ScriptEmailPartnerBatch batch = new ScriptEmailPartnerBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Check Partner records
        List<Partner> partners = [SELECT AccountFromId, AccountToId FROM Partner];
        System.assertEquals(3, partners.size(), 'Two bidirectional relations should be created for VAT match and email match');
    }

    @isTest static void novaliddomain() {
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(key__c='EMAIL', subkey__c='GENERICDOMAINS', value1__c = 'pipo.com;monster.com');
       insert aux;
        // Crear cuentas de prueba con el mismo VAT_Number_2__c (SIREN)
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(3);
        accounts[0].Name = 'Empresa 1';
        accounts[0].Business_Email__c = 'abbbbcccc@monster.com';
        accounts[0].DVSAction__c = 'CONFIRMED';
        accounts[0].BillingCountryCode =  'FR';
        accounts[0].BillingPostalCode =  '66677';
        accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

        accounts[1].Name = 'Empresa 2';
        accounts[1].DVSAction__c = 'CONFIRMED';
        accounts[1].BillingCountryCode =  'IT';
        accounts[1].Business_Email__c = 'bcccdddd@monster.com';
        accounts[1].BillingPostalCode =  '11111';
        accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);

        accounts[2].Name = 'Empresa 3';
        accounts[2].Business_Email__c = 'atttyyyhhh@monster.com';
        accounts[2].DVSAction__c = 'CONFIRMED';
        accounts[2].BillingCountryCode =  'GB';
        accounts[2].BillingPostalCode =  'LA22 9NZ';
        accounts[2].DvsAcceptedDate__c = Date.newInstance(2024, 9, 15);

        // Create a contact with matching email for acc3
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'a@monster.com', AccountId = accounts[2].Id);
        insert con;

        update accounts;

        Test.startTest();
        ScriptEmailPartnerBatch batch = new ScriptEmailPartnerBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Check Partner records
        List<Partner> partners = [SELECT AccountFromId, AccountToId FROM Partner];
        System.assertEquals(0, partners.size(), 'Two bidirectional relations should be created for VAT match and email match');
    }

    @isTest static void testBatchExecution_createsAndCleansPartners_2() {
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(key__c='EMAIL', subkey__c='GENERICDOMAINS', value1__c = 'pipo.com');
       insert aux;
        
        List<Account> accounts = DataFactoryAccount.createBusinessAccounts(3);
        accounts[0].Name = 'Empresa 1';
        accounts[0].Business_Email__c = 'a@rapapum.com';
        accounts[0].DVSAction__c = 'CONFIRMED';
        accounts[0].BillingCountryCode =  'FR';
        accounts[0].BillingPostalCode =  '11234';
        accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

        accounts[1].Name = 'Empresa 2';
        accounts[1].DVSAction__c = 'CONFIRMED';
        accounts[1].BillingCountryCode =  'IT';
        accounts[1].Business_Email__c = 'bcccdddd@rapapum.com';
        accounts[1].BillingPostalCode =  '11111';
        accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);


        accounts[2].Name = 'Empresa 3';
        accounts[2].Business_Email__c = 'atttyyyhhh@ttr.com';
        accounts[2].BillingCountryCode =  'GB';
        accounts[2].BillingPostalCode =  'LA22 9NZ';
        accounts[2].DvsAcceptedDate__c = Date.newInstance(2024, 9, 15);

        // Create a contact with matching email for acc3
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'a@eer.com', AccountId = accounts[2].Id);
        insert con;

        update accounts;

        // Insert a duplicate to simulate dirty data
        insert new Partner(AccountFromId = accounts[0].Id, AccountToId = accounts[1].Id);

        Test.startTest();
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(1);
        startDate = startDate.addDays(-10);
        ScriptEmailPartnerBatch batchAux = new ScriptEmailPartnerBatch(startDate, endDate);
        Database.executeBatch(batchAux);
        Test.stopTest();

        // Should clean duplicates
        Integer countAfter = [SELECT count() FROM Partner WHERE (AccountFromId = :accounts[0].Id AND AccountToId = :accounts[1].Id) OR (AccountFromId = :accounts[1].Id AND AccountToId = :accounts[0].Id)];
        System.assertEquals(1, countAfter, 'Should keep only 1 pair in each direction');
    }

    @isTest static void testBlockedDomainIsIgnored() {
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(key__c='EMAIL', subkey__c='GENERICDOMAINS', value1__c = 'test.com;pipo.com');
       insert aux;

       List<Account> accounts = DataFactoryAccount.createBusinessAccounts(2);
       accounts[0].Name = 'Empresa 1';
       accounts[0].Business_Email__c = 'noemail@test.com';
       accounts[0].DVSAction__c = 'CONFIRMED';
       accounts[0].BillingCountryCode =  'FR';
       accounts[0].BillingPostalCode =  '11234';
       accounts[0].DvsAcceptedDate__c = Date.newInstance(2024, 5, 1);

       accounts[1].Name = 'Empresa 2';
       accounts[1].DVSAction__c = 'CONFIRMED';
       accounts[1].BillingCountryCode =  'FR';
       accounts[1].Business_Email__c = 'noemail@test.com';
       accounts[1].BillingPostalCode =  '12334';
       accounts[1].DvsAcceptedDate__c = Date.newInstance(2024, 7, 10);
       update accounts;

        Test.startTest();
        ScriptEmailPartnerBatch batch = new ScriptEmailPartnerBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // No partner should be created due to blocked email
        List<Partner> partners = [SELECT Id FROM Partner];
        System.assertEquals(0, partners.size(), 'Blocked emails should not generate partner relations');
    }
}