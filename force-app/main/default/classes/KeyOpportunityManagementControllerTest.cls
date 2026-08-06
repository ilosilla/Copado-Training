@isTest
public class KeyOpportunityManagementControllerTest {
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard Trade' LIMIT 1];

        User usr = DataFactoryUser.createUKUser();

        List<Account> accs = DataFactoryAccount.createAccounts(1);

        // Crear Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = accs[0].Id,
            StageName = 'Prospecting',
            LeadSource = 'Porsamarket',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Crear Follow__c
        Follow__c follow = new Follow__c(
            Opportunity__c = opp.Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Opportunity' LIMIT 1].Id
        );
        insert follow;

        // Crear OpportunityAdditionalInfo__c
        OpportunityAdditionalInfo__c comment = new OpportunityAdditionalInfo__c(
            Opportunity__c = opp.Id,
            Value__c = 'Owner Comment',
            Value2__c = 'Answer',
            Value4__c = 'Answer',
            Infotype__c = 'WEEKLYCOMMENT',
            WeeklyCompleted__c = Date.today()
        );
        insert comment;

        // Crear Metadata simulado para emails
        // Para tests unitarios, los Custom Metadata no se insertan así. Se pueden usar Custom Settings o Mock.
    }

    @IsTest
    static void testRemoveAsKey() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        KeyOpportunityManagementController.removeAsKey(opp.Id);
        KeyOpportunityManagementController.removeAsKey(new List<String>{opp.Id});
        List<Follow__c> aux = [SELECT id FROM Follow__c WHERE Opportunity__c =: opp.Id];
        System.assertEquals(1, aux.size(), 'No Debe devolver un comentario');
    }

    @IsTest
    static void testGetComments() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityAdditionalInfo__c> comments = KeyOpportunityManagementController.getComments(opp.Id);
        List<OpportunityAdditionalInfo__c> lastComments = KeyOpportunityManagementController.getLastKeyOpportunitiesComments();
        System.assertNotEquals(0, comments.size(), 'Debe devolver al menos un comentario');
    }

    @IsTest
    static void testAddCCEmails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityAdditionalInfo__c> comments = KeyOpportunityManagementController.getComments(opp.Id);
        KeyOpportunityManagementController.addCCEmailToComment(Userinfo.getUserEmail(), comments[0].Id);

        OpportunityAdditionalInfo__c commentUpdated = [SELECT Id, Value3__c FROM OpportunityAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertNotEquals(comments[0].Value3__c, commentUpdated.Value3__c, 'Debe devolver al menos un comentario');
    }

    @IsTest
    static void testSetOffsite() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityAdditionalInfo__c> comments = KeyOpportunityManagementController.getComments(opp.Id);
        KeyOpportunityManagementController.addSpecialProduct(comments[0].Id,'OFFSITE');
        KeyOpportunityManagementController.addSpecialProduct(comments[0].Id,'KITCHEN');

        OpportunityAdditionalInfo__c commentUpdated = [SELECT Id, Value3__c FROM OpportunityAdditionalInfo__c WHERE Id =: comments[0].Id];
    }

    @IsTest
    static void testAddCCUser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityAdditionalInfo__c> comments = KeyOpportunityManagementController.getComments(opp.Id);
        KeyOpportunityManagementController.addCCUserToComment(Userinfo.getUserId(), comments[0].Id);

        OpportunityAdditionalInfo__c commentUpdated = [SELECT Id, Value3__c FROM OpportunityAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertNotEquals(comments[0].Value3__c, commentUpdated.Value3__c, 'Debe devolver al menos un comentario');

        KeyOpportunityManagementController.removeCCEmailToComment(Userinfo.getUserEmail(), comments[0].Id);
        commentUpdated = [SELECT Id, Value3__c FROM OpportunityAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertEquals(null, commentUpdated.Value3__c, 'Debe devolver null');

         KeyOpportunityManagementController.removeToEmailToComment(Userinfo.getUserEmail(), comments[0].Id);
        commentUpdated = [SELECT Id, Value4__c FROM OpportunityAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertEquals(null, commentUpdated.Value4__c, 'Debe devolver null');
    }

    @IsTest
    static void testGetEmailCCByUser() {
        User owner = [SELECT Id FROM User LIMIT 1];
        List<String> emails = KeyAccountManagementController.getEmailCCByUser(owner.Id);
        Assert.isNotNull(emails, 'Debe devolver lista de emails aunque esté vacía');
    }

    @IsTest
    static void testGetData() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        KeyOpportunityManagementController.keyOpportunityData data = KeyOpportunityManagementController.getData(opp.Id);
        System.assertEquals(opp.Id, data.opportunityData.Id, 'El Opportunity devuelto debe coincidir');
        Assert.isNotNull(data.comments, 'Debe devolver lista de comentarios');
        Assert.isNotNull(data.teamMembers, 'Debe devolver lista de miembros del equipo');
        Assert.isNotNull(data.emailCC, 'Debe devolver lista de emails CC');
    }
}