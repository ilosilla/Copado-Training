@isTest
public class PorsaMarketEmailsTest {
    @isTest
    static void testPrepareBodyWithAccount_FR() {
        // Simulación de resultado tipo Account
        PorsaMarket.PorsaMarketResult result = new PorsaMarket.PorsaMarketResult();
        result.obj = 'ACCOUNT';
        result.action = 'Créé';
        result.sfId = '001XXXXXXXXXXXX';
        result.name = 'Test Compte';

        result.accountData = new Account(
            BillingStreet = 'Rue Exemple',
            BillingPostalCode = '75001',
            BillingCity = 'Paris',
            Vat_number__c = 'FR123456789'
        );

        List<PorsaMarket.PorsaMarketResult> results = new List<PorsaMarket.PorsaMarketResult>{ result };
        String html = PorsaMarketEmails.prepareBody(results, 'fr', false);

        System.assert(html.contains('Bonjour'), 'Debe contener saludo en francés');
        System.assert(html.contains('Compte'), 'Debe contener "Compte" como objeto');
        System.assert(html.contains('Rue Exemple'), 'Debe contener dirección simulada');
    }

    @isTest
    static void testPrepareBodyWithOpportunity_EN() {
        PorsaMarket.PorsaMarketResult result = new PorsaMarket.PorsaMarketResult();
        result.obj = 'OPPORTUNITY';
        result.action = 'Created';
        result.sfId = '006XXXXXXXXXXXX';
        result.name = 'Test Opportunity';

        result.opportunityData = new Opportunity(
            Address__c = '123 Sales St.',
            Postcode__c = '90210',
            City__c = 'Los Angeles',
            Amount_custom__c = 50000
        );

        List<PorsaMarket.PorsaMarketResult> results = new List<PorsaMarket.PorsaMarketResult>{ result };
        String html = PorsaMarketEmails.prepareBody(results, 'en', false);

        System.assert(html.contains('Opportunity'), 'Debe contener "Opportunity" como objeto');
        System.assert(html.contains('123 Sales St.'), 'Debe contener dirección simulada');
        System.assert(html.contains('50000'), 'Debe contener el monto simulado');
    }

    @IsTest
    static void testPrepareBodyCustomData_IsTestTrue() {
        // Creamos datos simulados de Account y Opportunity
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main St',
            BillingPostalCode = '90210',
            BillingCity = 'Paris',
            Vat_number__c = 'FR123456789'
        );

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            Address__c = '456 Project Ave',
            Postcode__c = '75000',
            City__c = 'Lyon',
            Amount_custom__c = 150000
        );

        // Creamos el objeto PorsaMarketCustom simulado
        PorsaMarketCustom customData = new PorsaMarketCustom();
        customData.dataAccount = acc;
        customData.dataProject = opp;

        // Ejecutamos el método con isTest = true
        String html = PorsaMarketEmails.prepareBodyCustomData(customData, true);

        // === ASSERTS ===
        System.assertNotEquals(null, html, 'El HTML no debería ser nulo');
        System.assert(html.contains('<html>'), 'Debe contener HTML');
        System.assert(html.contains('Test Account'), 'Debe incluir el nombre de la cuenta');
        System.assert(html.contains('123 Main St'), 'Debe incluir la dirección de la cuenta');
        System.assert(html.contains('FR123456789'), 'Debe incluir el VAT');
        System.assert(html.contains('Test Opportunity'), 'Debe incluir el nombre del proyecto');
        System.assert(html.contains('456 Project Ave'), 'Debe incluir la dirección del proyecto');
        System.assert(html.contains('150000'), 'Debe incluir el monto');
        System.assert(html.contains('##SENTEMAIL##'), 'Debe incluir la marca ##SENTEMAIL## cuando isTest = true');
    }

    @isTest
    static void testPrepareBodyWithCustom() {
        PorsaMarket.PorsaMarketResult result = new PorsaMarket.PorsaMarketResult();
        result.obj = 'OPPORTUNITY';
        result.action = 'Created';
        result.sfId = '006XXXXXXXXXXXX';
        result.name = 'Test Opportunity';

        result.opportunityData = new Opportunity(
            Address__c = '123 Sales St.',
            Postcode__c = '90210',
            City__c = 'Los Angeles',
            Amount_custom__c = 50000
        );

        List<PorsaMarket.PorsaMarketResult> results = new List<PorsaMarket.PorsaMarketResult>{ result };
        String html = PorsaMarketEmails.prepareBody(results, 'en', false);

        System.assert(html.contains('Opportunity'), 'Debe contener "Opportunity" como objeto');
        System.assert(html.contains('123 Sales St.'), 'Debe contener dirección simulada');
        System.assert(html.contains('50000'), 'Debe contener el monto simulado');
    }

    @isTest
    static void testPrepareBodyInTestMode() {
        PorsaMarket.PorsaMarketResult result = new PorsaMarket.PorsaMarketResult();
        result.obj = 'ACCOUNT';
        result.action = 'Assigned';
        result.sfId = '001XXXXXXXXXXXX';
        result.name = 'Test Account';
        result.accountData = new Account();

        List<PorsaMarket.PorsaMarketResult> results = new List<PorsaMarket.PorsaMarketResult>{ result };
        String html = PorsaMarketEmails.prepareBody(results, 'en', true);

        System.assert(html.contains('##SENTEMAIL##'), 'Debe contener marcador de prueba ##SENTEMAIL##');
    }

    @isTest
    static void testSendEmailFileError() {
        Map<String, String> errorMap = new Map<String, String>{
            'Line 1' => 'Missing name',
            'Line 2' => 'Invalid VAT'
        };

        Test.startTest();
        PorsaMarketEmails.sendEmailFileError(errorMap);
        Test.stopTest();

        // No podemos hacer assertions sobre emails enviados en sí, pero si no hay error, el test pasa.
    }
}