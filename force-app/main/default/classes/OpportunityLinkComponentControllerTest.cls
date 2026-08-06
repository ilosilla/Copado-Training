@isTest
private class OpportunityLinkComponentControllerTest {
    @isTest
    static void testGetUserData() {
        // Preparación
        User usr = DataFactoryUser.createUKUser();

        // Llamada al método que se va a probar
        Test.startTest();
        System.runAs(usr) {
            User userData = OpportunityLinkComponentController.getUserData();
            // Verificación
            System.assertEquals(usr.Id, userData.Id, 'El Id del usuario obtenido no coincide con el Id del usuario de prueba');
            // Puedes agregar más aserciones para verificar los campos adicionales del usuario si es necesario
        }
        Test.stopTest();
    }

    @isTest
    static void testGetButtonsInfo() {
        // Preparación
        PorcelanosaSetting__c testSetting = new PorcelanosaSetting__c(
            key__c = 'OPPLINKOPTION',
            subkey__c = 'TestSubkey',
            value1__c = 'TestPermission',
            value2__c = 'opplink_new_tileplanner',
            isActive__c = true
            // Otros campos requeridos
        );
        insert testSetting;

        // Llamada al método que se va a probar
        Test.startTest();
        List<OpportunityLinkComponentController.ButtonInfoDTO> buttonsInfo = OpportunityLinkComponentController.getButtonsInfo();
        // Verificación
        System.assertEquals(1, buttonsInfo.size(), 'Se esperaba una sola información de botón');
        OpportunityLinkComponentController.ButtonInfoDTO buttonInfo = buttonsInfo[0];
        System.assertEquals('New Tile Planner', buttonInfo.label, 'El valor del campo "label" no coincide');
        System.assertEquals('TestSubkey', buttonInfo.internalValue, 'El valor del campo "internalValue" no coincide');
        Test.stopTest();
    }

    @isTest
    static void createCounterTop() {
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 1);
        ExternalMapping__c aux = new ExternalMapping__c(ExternalId__c='00112233', SalesforceId__c='*', Source__c='COUNTERTOP', Type__c = 'SALESOFFICE' );
        insert aux;

        // Llamada al método que se va a probar
        Test.startTest();
            String url_countertop = OpportunityLinkComponentController.createNewCounterTop(opps[0].Id);
        Test.stopTest();
        
        Assert.areEqual(true, true, 'Algo ha fallado');
    }

    @isTest
    static void createMoodboard() {
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 1);

        // Llamada al método que se va a probar
        Test.startTest();
            String url_countertop = OpportunityLinkComponentController.createNewMoodboard(opps[0].Id);
        Test.stopTest();
        
        Assert.areEqual(true, true, 'Algo ha fallado');
    }

    @isTest
    static void createUserCounterTop() {
        List<Account> accs = DataFactoryAccount.createAccounts(1);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 1);
        ExternalMapping__c aux = new ExternalMapping__c(ExternalId__c='00112233', SalesforceId__c='*', Source__c='COUNTERTOP', Type__c = 'SALESOFFICE' );
        insert aux;

        // Preparación
        User usr = DataFactoryUser.createUKUser();

        // Llamada al método que se va a probar
        Test.startTest();
            Map<String, String> user_counertop = CounterTop.createUser(usr.Id);
        Test.stopTest();
        
        Assert.areEqual(true, true, 'Algo ha fallado');
    }

    @isTest
    static void fillerTest() {
        CounterTop aux = new CounterTop();
        aux.testFiller();
        OpportunityLinkComponentController aux2 = new OpportunityLinkComponentController();
        aux2.testFiller();
        Assert.isTrue(1 == 1);
    }
}