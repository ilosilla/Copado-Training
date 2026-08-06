@isTest
public class SalesRelationshipTriggerHandlerTest {
    // Crea un usuario de prueba para darle permisos.
    @testSetup static void setup() {
        TestUtils.enableTriggers();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Map<String, Object> fieldsToAdd = new Map<String, Object> {'ProfileId' => p.Id, 'LocaleSidKey' => 'en_GB', 
            'Sales_Org__c' => OrganizationCommons.ORG_AZURCERAMIQUE + ';' + OrganizationCommons.ORG_PIDF, 'Default_Sales_Organization__c' => OrganizationCommons.ORG_AZURCERAMIQUE, 'Distribution_Channel__c' => '10;15;30;50;60;65;70', 'Sales_office__c' => '3015'};
		User testUser = User_TestDataFactory.createUsers(1, fieldsToAdd)[0];
       	Insert testUser;
        
        List<Account> accList = new List<Account>();
        accList.add(Account_TestDataFactory.createBusinessAccount());
        accList.add(Account_TestDataFactory.createRetailer());
        accList.add(Account_TestDataFactory.createRetailer());
        
        accList[1].Name = 'Acc Many Sales Rel';
        accList[2].Name = 'Acc One Sales Rel';
        
        Account_TestDataFactory.insertAccounts(accList);
        
    }
    
    @isTest public static void insertOpportunity() {
        // Busca el usuario recien creado
        User u = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' LIMIT 1];
        
        // Corremos el caso de prueba como el usuario recien creado.
        
        // Test 1: 
        // Cuando se inserta una "Sales Relationship" con un Account de record Type Third party Retailer / Reseller
        // Se debera activar el trigger y este inserta una Oportunity y un Opportunity Actor
        // Y los envia a sap
        System.debug('Test 1');
        
        Account accManySalesRel = [SELECT Id FROM Account WHERE Name = 'Acc Many Sales Rel'];
        Account accOneSalesRel = [SELECT Id FROM Account WHERE Name = 'Acc One Sales Rel'];
        System.debug('accManySalesRel: ' + accManySalesRel.Id);
        
        List<Sales_RelationShip__c> salesRelList = new List<Sales_RelationShip__c>();
        salesRelList.add(Sales_RelationShip_TestDataFactory.createSalesRelationship(accOneSalesRel));
        salesRelList.add(Sales_RelationShip_TestDataFactory.createSalesRelationship(accManySalesRel));
        salesRelList.add(Sales_RelationShip_TestDataFactory.createSalesRelWithPicklist(accManySalesRel, OrganizationCommons.ORG_EUROCERAMIQUE, '3035', '10'));
        System.debug('salesRelList: ' + salesRelList);
        
        Database.SaveResult[] result_test_1;
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        System.runAs(u) {
            result_test_1 = Database.insert(salesRelList, false);
        }
        Test.stopTest();
        
        for(Database.SaveResult sv : result_test_1){
            System.assert( sv.isSuccess() );
        }
        
        // Verificando que se haya creado solamente una Opportunity para ambas cuentas
        Opportunity opp2 = [SELECT Id, Name, CloseDate, StageName, RecordTypeId FROM Opportunity WHERE accountId =: accManySalesRel.Id];
        
        // Test 3: Se crea otra sales rol con la misma cuenta que test 1 pero con diferente sales org y dist channel
        // Luego verifia que no se inserte otra opportunity comparando que dos queries sean iguales.
        Sales_RelationShip__c salesRel3 = Sales_RelationShip_TestDataFactory.createSalesRelWithPicklist(accManySalesRel, OrganizationCommons.ORG_PIDF, '3035', '10');
        System.debug('salesRel: ' + salesRel3);
        
        Database.SaveResult result_test_3 = Database.insert(salesRel3, false);
        System.assert( result_test_3.isSuccess() );
        
        Opportunity oppAfter = [SELECT Id, Name, CloseDate, StageName, RecordTypeId FROM Opportunity WHERE accountId =: salesRel3.Account_Org__c];
        System.assertEquals(opp2, oppAfter);
        
        // Test 2: 
        // Account con record Type Trade.
        // Se debe dejar pasar sin crear objetos relacionados.
        Account acc2 = [SELECT Id FROM Account WHERE NAME = 'TestAcctBusinessAccount1'];
        System.debug('acc2: ' + acc2);
        
        Sales_RelationShip__c salesRel2 = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc2);
        System.debug('salesRel2: ' + salesRel2);
        
        Database.SaveResult result_test_2 = Database.insert(salesRel2, false);
        System.assert( result_test_2.isSuccess() );
        
        // Verificando que no se hayan insertado Opportunities relacionadas al Account de la Sales Relationship
        String error_test_2 = '';
        Opportunity newOpp = new Opportunity();
        try {
            newOpp = [SELECT Id FROM Opportunity WHERE AccountId =: salesRel2.Account_Org__c];
        } catch (QueryException ex){
            error_test_2 = ex.getMessage();
        }
        System.assert(error_test_2.contains('List has no rows for assignment to SObject') );
    }

    @isTest static void updateActivity(){
        // Busca el usuario recien creado
        User testUser = [SELECT Name, Id FROM User WHERE UserName LIKE '%@testOrg.com'];
        
        System.runAs(testUser) {
            Account acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
            Test.startTest();
            acc.Last_Activity_Date__c = System.now().addDays(-8);
            update acc;
            //Check the beforeInsert Trigger
            Sales_Relationship__c newSalesRel = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc);
            Insert newSalesRel;
            Test.stopTest();
            
            acc = [SELECT Id, Last_Activity_Date__c FROM Account WHERE Id =: acc.Id];
            // Check the update of the Last_Activity_Date on Account
            System.assert(acc.Last_Activity_Date__c.date() == System.now().date());
        }
    }

    @isTest static void updateOwnerTest() {
        // Busca el usuario recien creado
        User user = DatafactoryUser.createUKAdmin();

        RegionalSettings__mdt soutMetadata = [SELECT Id, MasterLabel, SalesOrganization__c, ReassignOwner__c 
            FROM RegionalSettings__mdt 
            WHERE SalesOrganization__c = :OrganizationCommons.ORG_FLORIDA LIMIT 1];
        soutMetadata.ReassignOwner__c = true;

        Account acc = [SELECT Id,OwnerId,Owner.Name FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        acc.OwnerId = user.Id;
        Update acc;

        Test.startTest();
            Sales_RelationShip__c newSalesRel = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc);
            newSalesRel.Sales_Office__c = '4102'; // Sales Office assigned to the user
            newSalesRel.Sales_Org__c = OrganizationCommons.ORG_FLORIDA; // Sales Org assigned to the user
            newSalesRel.Distribution_Channel__c = '60'; // Distribution Channel assigned to the user
            Insert newSalesRel;
        Test.stopTest();
        
        Account accPost = [SELECT Id,OwnerId,Owner.Name FROM Account WHERE Id =: acc.Id];
        System.debug(acc.OwnerId + ' != ' + accPost.OwnerId);
        Assert.areNotEqual(acc.OwnerId, accPost.OwnerId, 'Owner should have been reassigned');
    }
}