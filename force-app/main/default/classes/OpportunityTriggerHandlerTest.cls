@isTest
public class OpportunityTriggerHandlerTest {
    private static Map<String, Sales_Org__c> salesOrgMap;
    
	@testSetup
    static void setup() {
        TestUtils.enableTriggers();
        User testUser = User_TestDataFactory.createUsers(1, new List<String>{'en_US'})[0];
        testUser.Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE + ';' + OrganizationCommons.ORG_PIDF;
        testUser.Does_this_position_have_a_sales_budget__c = 'Si';
        testUser.Default_Sales_Organization__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        testUser.sales_office__c = '3015';
        Insert testUser;
        
        List<Account> accList = new List<Account>();
        accList.add(Account_TestDataFactory.createBusinessAccount());
        accList.add(Account_TestDataFactory.createFabricator());
        Insert accList;

        List<Contact> contList = Contact_TestDataFactory.createContacts(2, new List<Map<String, Object>>{
            new Map<String, Object>{'AccountId' => accList[0].Id},
            new Map<String, Object>{'AccountId' => accList[1].Id}
        });
        Insert contList;

        DatafactoryOrganization.createData();  
    }

    @isTest static void testAfterInsert(){
        // Busca el usuario recien creado
        User testUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg0.com' LIMIT 1];
        
        Account accbefore = [SELECT Id, LastOpportunityDateTime__c FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        accbefore.Last_Activity_Date__c = System.today().addDays(-3);
        update accbefore;
        System.runAs(testUser) {
            Test.startTest();        
            Opportunity newOpp = Opportunity_TestDataFactory.createTrade(accbefore);
            Insert newOpp;
            Test.stopTest();
        }
        Account accafter = [SELECT Id, LastOpportunityDateTime__c FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        System.assert(accbefore.LastOpportunityDateTime__c != accafter.LastOpportunityDateTime__c, 'Last Activity of the Account hasn\'t changed');
        
    }
    
    @isTest static void testBeforeInsert(){
        User testUser = [SELECT Name, Id FROM User WHERE UserName LIKE '%@testOrg0.com'][0];
        
        System.runAs(testUser){
            
            // Test 1: Success. Project Trade Record Type + Country de Account que no esta en la picklist Country__c
            List<Account> accList = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1' OR Name = 'TestAcctFabricatorAccount1'];
            
            List<Opportunity> oppList = new List<Opportunity>();
            oppList.add(Opportunity_TestDataFactory.createTrade(accList[0]));
            oppList.add(Opportunity_TestDataFactory.createTrade(accList[1]));
            
            List<Database.SaveResult> result_test_1;
            
            Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
            Test.startTest();
            	result_test_1 = Database.insert(oppList, false);
            Test.stopTest();
            
            System.assert( result_test_1[0].isSuccess() );
            System.assert( result_test_1[1].isSuccess() );
            
            // Actualizar la referencia para ver el campbio
            oppList = [SELECT Sales_Org__c, Dist_Channel__c FROM Opportunity WHERE Id IN: oppList];
            
            System.assertEquals(OrganizationCommons.ORG_AZURCERAMIQUE, oppList[0].Sales_Org__c);
            System.assertEquals('70', oppList[0].Dist_Channel__c);
            
            System.assertEquals(OrganizationCommons.ORG_AZURCERAMIQUE, oppList[1].Sales_Org__c);
            System.assertEquals('70', oppList[1].Dist_Channel__c);
            
            
       }
    }
    
    @isTest static void testBeforeUpdate(){
        Map<String, Sales_Org__c> salesOrgMap = OrganizationUtil.getSalesOrgsMap();
        User testUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg0.com' LIMIT 1];
        
        System.runAs(testUser) {
            // Test 1: Success. Una Opportunity con Actores Validos
            // Cuando se pasa al estado Cotizacion entonces debera ejecutarse la comprobacion validateAcount
            // Si pasa entonces debera enviarse a sap
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
            Contact cont = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
            
            List<Opportunity> oppListToInsert = new List<Opportunity>();
            // Opportunity valida.
            Opportunity newOpp = Opportunity_TestDataFactory.createTrade(acc);
            newOpp.Opportunity_Classification__c = 'Residential';
            newOpp.SalesOrglookup__c = salesOrgMap.get(OrganizationCommons.ORG_AZURCERAMIQUE).Id;
            oppListToInsert.add(newOpp);
            
            // Opportunity sin actores.
            Opportunity oppWithoutActors = Opportunity_TestDataFactory.createTrade(acc);
            oppWithoutActors.SalesOrglookup__c = salesOrgMap.get(OrganizationCommons.ORG_AZURCERAMIQUE).Id;
            oppWithoutActors.Opportunity_Classification__c = 'Residential';
            oppListToInsert.add(oppWithoutActors);
            
            // Opportunity con una salesOrg que no coincide con la relacion de ventas de la cuenta.
            Opportunity oppInvalidAcc = Opportunity_TestDataFactory.createTrade(acc);
            oppInvalidAcc.Opportunity_Classification__c = 'Residential';
            oppInvalidAcc.SalesOrglookup__c = salesOrgMap.get(OrganizationCommons.ORG_PIDF).Id;
            oppListToInsert.add(oppInvalidAcc);
            
            Insert oppListToInsert;
            
            // Actor para newOpp
            OpportunityContactRole oppActor_newOpp = new OpportunityContactRole(OpportunityId = newOpp.Id, ContactId = cont.Id, isPrimary = true);
            insert oppActor_newOpp;
            
            // Actor para oppInvalidAcc
            OpportunityContactRole oppActor_Invalid = new OpportunityContactRole(OpportunityId = oppInvalidAcc.Id, ContactId = cont.Id, isPrimary = false);
            insert oppActor_Invalid;
            
            // Have_we_won_specification__c es necesario para poder pasar la regla de validacion y pasar a la etapa "Cotizacion"
            newOpp.StageName = 'Cotización';
            newOpp.Amount_custom__c = 1000;
            newOpp.Have_we_won_specification__c = 'Yes';
            newOpp.Currency__c = 'CAD';
            // oppWithoutActors.StageName = 'Cotización';
            // oppWithoutActors.Amount_custom__c = 1000;
            // oppWithoutActors.Have_we_won_specification__c = 'Yes';
            
            Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
            Test.startTest();
            	update oppListToInsert;
            	// Se prueba actualizar la misma oportunidad devuelva, si el StageName no cambia entonces no se debe enviar a sap.
            	update newOpp;
            Test.stopTest();
            
            // Cherckeando que el Opportunity Actor se haya enviado a SAP exitosamente.
            List<OpportunityContactRole> oppListUpdated = [SELECT Id, SAPStatus__c FROM OpportunityContactRole 
                                                         WHERE Id =: oppActor_newOpp.Id OR OpportunityId =: oppWithoutActors.Id
                                                         OR OpportunityId =: oppInvalidAcc.Id];
            System.assertEquals('Success', oppListUpdated[0].SAPStatus__c); // oppActor_newOpp
            System.assertEquals('Success', oppListUpdated[1].SAPStatus__c); // oppInvalidAcc
        }
    }
}