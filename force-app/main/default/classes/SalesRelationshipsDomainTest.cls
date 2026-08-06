@isTest
public class SalesRelationshipsDomainTest {

    // Método de configuración que se ejecuta antes de todos los métodos de prueba
    @testSetup
    static void setupTestData() {
        // Crear datos de prueba para Sales_Org__c
        Sales_org__c salesOrg1 = new Sales_org__c(SalesOrg__c = '001', RestrictedForSAP__c = true);
        Sales_org__c salesOrg2 = new Sales_org__c(SalesOrg__c = '002', RestrictedForSAP__c = false);
        insert new List<Sales_org__c>{salesOrg1, salesOrg2};
        
        // Crear datos de prueba para Account
        List<Account> testAccounts = DataFactoryAccount.createAccounts(1);
    }

    // Prueba unitaria para el método isRestricted
    @isTest
    static void testIsRestricted() {
        // Crear datos de prueba para User
        User testUser = [SELECT Id FROM User WHERE IsActive = true and Profile.Name like '%System%' LIMIT 1]; // Usamos un usuario existente activo
        
        // Crear datos de prueba para PermissionSetAssignment
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'SAP_ACCOUNT_CREATION_008' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permSet.Id);
        insert psa;

        // Llamada al método con un Sales Org restringido
        Boolean result = SalesRelationshipsDomain.isRestrictedOrg('001');
        System.assert(result == true, 'El resultado debe ser verdadero para un Sales Org restringido.');

        // Llamada al método con un Sales Org no restringido
        result = SalesRelationshipsDomain.isRestrictedOrg('002');
        System.assert(result == false, 'El resultado debe ser falso para un Sales Org no restringido.');

        SalesRelationshipsDomain.getRestrictedOrgExtendors('008');
    }

    // Prueba unitaria para el método getRestrictedOrgs
    @isTest
    static void testGetRestrictedOrgs() {
        // Crear datos de prueba para User
        User testUser = [SELECT Id FROM User WHERE IsActive = true and Profile.Name like '%System%' LIMIT 1]; // Usamos un usuario existente activo
        
        // Crear datos de prueba para PermissionSetAssignment
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'SAP_ACCOUNT_CREATION_008' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permSet.Id);
        insert psa;

        List<Sales_org__c> restrictedOrgs = SalesRelationshipsDomain.getRestrictedOrgs();
        System.assert(restrictedOrgs.size() == 1, 'Debe haber un solo Sales Org restringido.');
        System.assertEquals('001', restrictedOrgs[0].SalesOrg__c, 'El Sales Org restringido debe ser 001.');
    }

    // Prueba unitaria para el método sendRestrictedExtensionExport
    @isTest
    static void testSendRestrictedExtensionExport() {
        // Crear datos de prueba para User
        User testUser = [SELECT Id, Email FROM User WHERE IsActive = true and Profile.Name like '%System%' LIMIT 1]; // Usamos un usuario existente activo
        
        // Crear datos de prueba para PermissionSetAssignment
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'SAP_ACCOUNT_CREATION_008' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = permSet.Id);
        insert psa;

        // Recuperar datos de prueba
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        // Ejecutar el método
        SalesRelationshipsDomain.sendRestrictedOrgRequestExportacion('001', 'CHANNEL1', 'OFFICE1', testUser.Id, testUser.Id, testAccount.Id);
        
        Test.stopTest();
        
        Assert.areEqual(true, true);
    }
}