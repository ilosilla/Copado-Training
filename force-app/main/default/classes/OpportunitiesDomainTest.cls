@isTest private class OpportunitiesDomainTest {

    @testSetup static void setup(){
        TestUtils.enableTriggers();
        List<Account> listAccs = new List<Account>();
        Account accCustomer = Account_TestDataFactory.createCustomer();
        listAccs.add(accCustomer);
        Account accBussiness = Account_TestDataFactory.createBusinessAccount();
        listAccs.add(accBussiness);
        Insert listAccs;

        List<Contact> contList = Contact_TestDataFactory.createContacts(1, new List<Map<String, Object>>{
            new Map<String, Object>{'AccountId' => listAccs[1].Id}
        });
        Insert contList;
         
        Map<String, Object> fieldsToAdd = new Map<String, Object>();
        fieldsToAdd.put('Sales_Org__c', OrganizationCommons.ORG_AZURCERAMIQUE);
        fieldsToAdd.put('Dist_Channel__c', '10');
        fieldsToAdd.put('AccountId', accCustomer.Id);
        
        Opportunity opp1 = Opportunity_TestDataFactory.createOpportunities(1, fieldsToAdd)[0];
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        insert opp1;
        Test.stopTest();

    }
    
    @isTest static void testInfoObjectsCustomProjects() {
        TestUtils.enableTriggers();
    
        SystemSettings.CPDeletionTime = 0;
    
        List<String> wonStages = OpportunityCommons.getClosedWonStages();
        List<String> lostStages = OpportunityCommons.getClosedLostStages();
    
        DataFactoryOppCustomProjects.createRecords(2);
    
        List<Opportunity> opps = [select Id, StageName, InfoType__c from Opportunity];
        Integer nProjects = 0;
        for (Opportunity opp : opps) {
            if (opp.InfoType__c == OpportunitiesInfoCommons.PROJECT_TYPE) {
                if (nProjects == 0) {
                    opp.StageName = wonStages[0];
                    nProjects++;
                } else {
                    opp.StageName = lostStages[0];
                }
            } else {
                opp.StageName = lostStages[0];
            }
        }
        OpportunitiesDomain domain = new OpportunitiesDomain(opps);
        domain.runStageActions();

        // Custom projects
        Integer deposits = 0;
        Integer lost = 0;
        List<OppCustomProject__c> projects = [select Id, Stage__c from OppCustomProject__c];
        for (OppCustomProject__c project : projects) {
            if (project.Stage__c == OpportunitiesDomain.INFO_LOST_STAGE) {
                lost++;
            }
            if (project.Stage__c == OpportunitiesDomain.PROJECT_DEPOSIT_STAGE) {
                deposits++;
            }
        }
        System.assertEquals(1, deposits, 'One custom project should be in stage ' + OpportunitiesDomain.PROJECT_DEPOSIT_STAGE);
        System.assertEquals(1, lost, 'One custom project should be in stage ' + OpportunitiesDomain.INFO_LOST_STAGE);

    }

    @isTest static void testInfoObjectsFacades() {
        TestUtils.enableTriggers();
    
        SystemSettings.CPDeletionTime = 0;
    
        List<String> wonStages = OpportunityCommons.getClosedWonStages();
        List<String> lostStages = OpportunityCommons.getClosedLostStages();
    
        DataFactoryOppFacade.createFacade();
    
        List<Opportunity> opps = [select Id, StageName, InfoType__c from Opportunity];
        Integer nProjects = 0;
        for (Opportunity opp : opps) {
            if (opp.InfoType__c == OpportunitiesInfoCommons.PROJECT_TYPE) {
                if (nProjects == 0) {
                    opp.StageName = wonStages[0];
                    nProjects++;
                } else {
                    opp.StageName = lostStages[0];
                }
            } else {
                opp.StageName = lostStages[0];
            }
        }
        OpportunitiesDomain domain = new OpportunitiesDomain(opps);
        domain.runStageActions();

        // Facades
        List<OppFacade__c> facades = [select Id, Stage__c from OppFacade__c];
        for (OppFacade__c facade : facades) {
            System.assertEquals(OpportunitiesDomain.INFO_LOST_STAGE, facade.Stage__c, 'The facade should be in stage ' + OpportunitiesDomain.INFO_LOST_STAGE);
        }
    }

    @isTest static void testInfoObjectsKitchen() {
        TestUtils.enableTriggers();
    
        SystemSettings.CPDeletionTime = 0;
    
        List<String> wonStages = OpportunityCommons.getClosedWonStages();
        List<String> lostStages = OpportunityCommons.getClosedLostStages();
    
        DataFactoryOppKitchen.createRecords();
    
        List<Opportunity> opps = [select Id, StageName, InfoType__c from Opportunity];
        Integer nProjects = 0;
        for (Opportunity opp : opps) {
            if (opp.InfoType__c == OpportunitiesInfoCommons.PROJECT_TYPE) {
                if (nProjects == 0) {
                    opp.StageName = wonStages[0];
                    nProjects++;
                } else {
                    opp.StageName = lostStages[0];
                }
            } else {
                opp.StageName = lostStages[0];
            }
        }
        OpportunitiesDomain domain = new OpportunitiesDomain(opps);
        domain.runStageActions();

        // Kitchens
        List<OppKitchen__c> kitchens = [select Id, Stage__c from OppKitchen__c];
        for (OppKitchen__c kitchen : kitchens) {
            System.assertEquals(OpportunitiesDomain.INFO_LOST_STAGE, kitchen.Stage__c, 'The kitchen should be in stage ' + OpportunitiesDomain.INFO_LOST_STAGE);
        }

    }

    @isTest static void setOpportunityStages() {
        DataFactoryOpportunity.createRetailOpportunities(1, 2);
        
        // If a reason lost is set, the Stage should change to LOST
        Test.startTest();
        Opportunity opp = [SELECT Id, StageName, amount_custom__c FROM Opportunity WHERE StageName <> 'Lost' LIMIT 1];
        opp.amount_custom__c = 100;
        opp.reason_lost__c = 'Price';
        update opp;
        Test.stopTest();

        opp = new OpportunitiesSelector().selectById(opp.Id);
        System.assert(opp.StageName.toUpperCase() == 'LOST', 'The Stage has not been set to LOST');
    }

    @isTest public static void insertActor(){
        
        // Test 1: Success after Insert.
        Opportunity opp1 = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Account privateAccount = [SELECT Id, PersonContactId FROM Account WHERE IsPersonAccount = true];
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'];
        Contact cont = [SELECT Id FROM Contact WHERE AccountId =: acc.Id];
            
            // Actor con la misma cuenta que la opportunity
            OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = privateAccount.PersonContactId);
            // Actor con distinta cuenta que la opportunity
            OpportunityContactRole oppActor2 = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = cont.Id);
            
            Database.SaveResult result_test_1;
            Database.SaveResult result_test_2;
            Database.SaveResult result_test_3;
            Database.SaveResult result_test_4;
            
            Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
            Test.startTest();
            	// Chechea que los inserts y updates se hayan hecho correctamente.
            	result_test_1 = Database.insert(oppActor1, false);
            	result_test_2 = Database.insert(oppActor2, false);
            	System.assert( result_test_1.isSuccess(), 'No se ha podido insertar el Actor 1' );
            	System.assert( result_test_2.isSuccess(), 'No se ha podido insertar el Actor 2' );
            	
            	result_test_3 = Database.update(oppActor1, false);
            	result_test_4 = Database.update(oppActor2, false);
            	System.assert( result_test_3.isSuccess(), 'No se ha podido actualizar el Actor 1' );
            	System.assert( result_test_4.isSuccess(), 'No se ha podido actualizar el Actor 2' );
            Test.stopTest();
            
            // Query para poder ver el cambio del valor de SAP_Status__c
            // Los actores con misma cuenta que la opportunity deberian ser dos. Uno automatico generado en el after insert de opportunity y el otro "oppActor1"
            oppActor2 =  [SELECT SAPStatus__c FROM OpportunityContactRole WHERE OpportunityId =: opp1.Id AND ContactId =: cont.Id];
            
            System.assertEquals('Success', oppActor2.SAPStatus__c);
    }
}