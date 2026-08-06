@isTest
private class TaxCommonsTest {
    
    @isTest
    private static void testSelectBySAPId() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Sales_Org__c org = new Sales_Org__c(
                Name = 'SalesOrg',
                Company__c = '502',
                SalesOrg__c = '502',
                CountryCode__c = 'GB',
                ShortName__c = 'ShortName',
                SamplesCutoff__c = Time.newInstance(12, 0, 0, 0),
                SamplesMinDays__c = 2,
                TimeZone__c = 'America/Los_Angeles',
                Autopick__c = true,
                IsBlocked__c = false,
                TaxPercent__c = 10.0
            );
            insert org;

            Decimal taxPercent = TaxCommons.getSalesOrgTax(org.SalesOrg__c);
            Test.stopTest();

            System.assertEquals(10.0, taxPercent, 'The tax percent should be the same as the inserted SalesOrg record');
        }
    }

    @isTest
    static void testIsValidSiret() {
        // Test con un SIRET válido
        String validSiret = '34114111700083'; // Asegúrate de usar un SIRET válido para tu lógica
        Boolean isValid = TaxCommons.isValidSiret(validSiret);
        System.assert(isValid, 'El SIRET debería ser válido');

        // Test con un SIRET inválido
        String invalidSiret = '34114111700085'; // Asegúrate de usar un SIRET inválido para tu lógica
        isValid = TaxCommons.isValidSiret(invalidSiret);
        System.assert(!isValid, 'El SIRET debería ser inválido');

        // Test con un SIRET nulo
        String nullSiret = null;
        isValid = TaxCommons.isValidSiret(nullSiret);
        System.assert(!isValid, 'El SIRET nulo debería ser inválido');

        // Test con un SIRET de longitud incorrecta
        String shortSiret = '12345';
        isValid = TaxCommons.isValidSiret(shortSiret);
        System.assert(!isValid, 'El SIRET de longitud incorrecta debería ser inválido');
    }

    @isTest
    static void testGetSirenFromSiret() {
        // Test con un SIRET válido
        String validSiret = '34114111700083';
        String expectedSiren = '341141117';
        String siren = TaxCommons.getSirenFromSiret(validSiret);
        System.assertEquals(expectedSiren, siren, 'El SIREN obtenido debería ser correcto');

        // Test con un SIRET nulo
        try {
            TaxCommons.getSirenFromSiret(null);
            System.assert(false, 'Debería lanzar una excepción para SIRET nulo');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Excepción capturada correctamente para SIRET nulo');
        }

        // Test con un SIRET de longitud incorrecta
        try {
            TaxCommons.getSirenFromSiret('12345');
            System.assert(false, 'Debería lanzar una excepción para SIRET de longitud incorrecta');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Excepción capturada correctamente para SIRET de longitud incorrecta');
        }
    }

    @isTest
    static void testValidUKVAT() {
        String validVAT = '287910661';
        Boolean validated = TaxCommons.isValidUKVAT(validVAT);
        System.assertEquals(true, validated, 'El VAT debería ser correcto');
        
        validVAT = null;
        validated = TaxCommons.isValidUKVAT(validVAT);
        System.assertEquals(false, validated, 'El VAT debería ser devolver incorrecto');

        validVAT = '28791661';
        validated = TaxCommons.isValidUKVAT(validVAT);
        System.assertEquals(false, validated, 'El VAT debería ser incorrecto');

        validVAT = 'DDR';
        validated = TaxCommons.isValidUKVAT(validVAT);
        System.assertEquals(false, validated, 'El VAT debería ser incorrecto');

        validVAT = 'GB287910661';
        validated = TaxCommons.isValidUKVAT(validVAT);
        System.assertEquals(true, validated, 'El VAT debería ser correcto');
    }

    @isTest
    static void testValidCRN() {
        String crn = '11070210';
        Boolean validated = TaxCommons.isValidCRN(crn);
        System.assertEquals(true, validated, 'El CRN debería ser correcto');

        crn = null;
        validated = TaxCommons.isValidCRN(crn);
        System.assertEquals(false, validated, 'El CRN debería ser devolver incorrecto');

        crn = '110700';
        validated = TaxCommons.isValidCRN(crn);
        System.assertEquals(false, validated, 'El CRN debería ser incorrecto');

        crn = '11070210443';
        validated = TaxCommons.isValidCRN(crn);
        System.assertEquals(false, validated, 'El CRN debería ser incorrecto');

        crn = 'GB110702';
        validated = TaxCommons.isValidCRN(crn);
        System.assertEquals(true, validated, 'El CRN debería ser correcto');
    }
}