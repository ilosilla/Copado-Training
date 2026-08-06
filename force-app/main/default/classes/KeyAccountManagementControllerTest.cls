@isTest
public class KeyAccountManagementControllerTest {
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
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Crear Follow__c
        Follow__c follow = new Follow__c(
            Account__c = accs[0].Id,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Account' LIMIT 1].Id
        );
        insert follow;

        // Crear AccountAdditionalInfo__c
        AccountAdditionalInfo__c comment = new AccountAdditionalInfo__c(
            Account__c = accs[0].Id,
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
        Account acc = [SELECT Id FROM Account LIMIT 1];
        KeyAccountManagementController.removeAsKey(acc.Id);
        KeyAccountManagementController.removeAsKey(new List<String>{acc.Id});
        List<Follow__c> aux = [SELECT id FROM Follow__c WHERE Account__c =: acc.Id];
        System.assertEquals(1, aux.size(), 'No Debe devolver un comentario');
    }

    @IsTest
    static void testGetComments() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<AccountAdditionalInfo__c> comments = KeyAccountManagementController.getComments(acc.Id);
        List<AccountAdditionalInfo__c> lastComments = KeyAccountManagementController.getLastKeyAccountsComments();
        System.assertNotEquals(0, comments.size(), 'Debe devolver al menos un comentario');
    }

    @IsTest
    static void testAddCCEmails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<AccountAdditionalInfo__c> comments = KeyAccountManagementController.getComments(acc.Id);
        KeyAccountManagementController.addCCEmailToComment(Userinfo.getUserEmail(), comments[0].Id);

        AccountAdditionalInfo__c commentUpdated = [SELECT Id, Value3__c FROM AccountAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertNotEquals(comments[0].Value3__c, commentUpdated.Value3__c, 'Debe devolver al menos un comentario');

        KeyAccountManagementController.removeCCEmailToComment(Userinfo.getUserEmail(), comments[0].Id);
        commentUpdated = [SELECT Id, Value3__c FROM AccountAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertEquals(null, commentUpdated.Value3__c, 'Debe devolver null');

        KeyAccountManagementController.removeToEmailToComment(Userinfo.getUserEmail(), comments[0].Id);
        commentUpdated = [SELECT Id, Value4__c FROM AccountAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertEquals(null, commentUpdated.Value4__c, 'Debe devolver null');
    }

    @IsTest
    static void testAddCCUser() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<AccountAdditionalInfo__c> comments = KeyAccountManagementController.getComments(acc.Id);
        KeyAccountManagementController.addCCUserToComment(Userinfo.getUserId(), comments[0].Id);

        AccountAdditionalInfo__c commentUpdated = [SELECT Id, Value3__c FROM AccountAdditionalInfo__c WHERE Id =: comments[0].Id];
        System.assertNotEquals(comments[0].Value3__c, commentUpdated.Value3__c, 'Debe devolver al menos un comentario');
    }

    @IsTest
    static void testGetEmailCCByUser() {
        User owner = [SELECT Id FROM User LIMIT 1];
        List<String> emails = KeyAccountManagementController.getEmailCCByUser(owner.Id);
        Assert.isNotNull(emails, 'Debe devolver lista de emails aunque esté vacía');
    }

    @IsTest
    static void testGetEmailCCByUsers() {
        List<User> users = [SELECT Id FROM User];
        Map<String, List<String>> emailsMap = KeyAccountManagementController.getEmailCCByUsers(new List<String>{users[0].Id});
       Assert.isNotNull(emailsMap, 'Debe devolver mapa de emails aunque esté vacío');
    }

    @IsTest
    static void testGetData() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        KeyAccountManagementController.keyAccountData data = KeyAccountManagementController.getData(acc.Id);
        System.assertEquals(acc.Id, data.accountData.Id, 'El Account devuelto debe coincidir');
        Assert.isNotNull(data.comments, 'Debe devolver lista de comentarios');
        Assert.isNotNull(data.opportunities, 'Debe devolver lista de oportunidades');
        Assert.isNotNull(data.teamMembers, 'Debe devolver lista de miembros del equipo');
        Assert.isNotNull(data.follows, 'Debe devolver lista de follows');
        Assert.isNotNull(data.emailCC, 'Debe devolver lista de emails CC');
    }
}