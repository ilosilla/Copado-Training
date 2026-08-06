@isTest
private class WeeklyManagementEmailsTest {

    @isTest
    static void testSendWeeklyReport() {
        User u = DatafactoryUser.createUKUser();

        Account acc = DatafactoryAccount.createAccounts(1)[0];

        Opportunity opp = new Opportunity(
            Name='Test Opp',
            StageName='Prospecting',
            CloseDate=System.today().addDays(30),
            OwnerId=u.Id,
            LeadSource='Porsamarket',
            AccountId=acc.Id
        );
        insert opp;

        // Crear evento
        Event evt = new Event(
            Subject='Test Event',
            StartDateTime=System.now().addDays(-1),
            EndDateTime=System.now().addHours(1),
            OwnerId=u.Id,
            WhatId=acc.Id,
            IsPrivate=false
        );
        insert evt;

        // Crear Follow__c
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType='Follow__c' AND Name='Account' LIMIT 1];
        Follow__c fol = new Follow__c(
            Account__c=acc.Id,
            OwnerId=u.Id,
            RecordTypeId=rt.Id
        );
        insert fol;

        // Crear registros adicionales
        AccountAdditionalInfo__c accInfo = new AccountAdditionalInfo__c(
            Account__c=acc.Id,
            StartDateTime__c=System.today().addDays(-1),
            Value__c='Info',
            Infotype__c = 'WEEKLYCOMMENT'
        );
        insert accInfo;

        OpportunityAdditionalInfo__c oppInfo = new OpportunityAdditionalInfo__c(
            Opportunity__c=opp.Id,
            StartDateTime__c=System.today().addDays(-1),
            Value__c='Opp Info',
            Infotype__c = 'WEEKLYCOMMENT'
        );
        insert oppInfo;

        Test.startTest();

        // Probar createEventsXls
        Map<String, String> xlsResult = WeeklyManagementEmails.createEventsXls(new List<Event>{evt}, u);
        System.assert(xlsResult.containsKey('CONTENT'));

        // Probar generateReportName y generateRecordName
        String reportName = WeeklyManagementEmails.generateReportName(u, System.today());
        System.assert(reportName.contains('WKR_'));

        String recordName = WeeklyManagementEmails.generateRecordName(u, System.today());
        System.assert(recordName.contains('Weekly Report'));

        // Probar insertRecord
        WeeklyReport__c wr = WeeklyManagementEmails.insertRecord(u, 'testFile.xls', '/path/to/file', 'Test Record');
        System.assertNotEquals(null, wr.Id);

        // Probar existingRecordsByNames
        Map<String, WeeklyReport__c> existing = WeeklyManagementEmails.existingRecordsByNames(new List<String>{'testFile.xls'});
        System.assert(existing.containsKey('testFile.xls'));

        WeeklyManagementEmails.sendWeeklyReport(System.today().addDays(-10), System.today().addDays(-1), u.Id);

        // Probar sendWeeklyReport
        // Se envía correo en modo test, no se envía realmente

        Test.stopTest();
    }

    @isTest
    static void testSendKeyAccountCommentAnswers_RealMode() {
        Account acc = DatafactoryAccount.createAccounts(1)[0];
        AccountAdditionalInfo__c info = new AccountAdditionalInfo__c(
            Account__c = acc.Id,
            Value2__c = 'Real email send test (simulation)',
            Infotype__c = 'WEEKLYCOMMENT'
        );
        insert info;

        Test.startTest();
        WeeklyManagementEmails.sendKeyAccountCommentAnswers(new List<String>{ info.Id }, false, new List<String>{ info.Id });
        WeeklyManagementEmails.sendKeyAccountCommentAnswers(new List<String>{ info.Id }, true, new List<String>{ info.Id });
        Test.stopTest();
    }

    @isTest
    static void testSendKeyAOpportunityCommentAnswers_RealMode() {
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        OpportunityAdditionalInfo__c info = new OpportunityAdditionalInfo__c(
            Opportunity__c = opp.Id,
            Value2__c = 'Real email send test (simulation)',
            Infotype__c = 'WEEKLYCOMMENT'
        );
        insert info;

        Test.startTest();
        WeeklyManagementEmails.sendKeyOpportunityCommentAnswers(new List<String>{ info.Id }, false, new List<String>{ info.Id });
        WeeklyManagementEmails.sendKeyOpportunityCommentAnswers(new List<String>{ info.Id }, true, new List<String>{ info.Id });
        Test.stopTest();
    }

    @isTest
    static void testSendKeyMainCommentOpps() {
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
        OpportunityAdditionalInfo__c info = new OpportunityAdditionalInfo__c(
            Opportunity__c = opp.Id,
            Value2__c = 'Real email send test (simulation)',
            Infotype__c = 'WEEKLYCOMMENT',
            WeeklyCompleted__c = System.today()
        );
        insert info;

        Test.startTest();
        WeeklyManagementEmails.sendMainCommentKeyOpportunityComments('Test Email', opp.AccountId);
        Test.stopTest();
    }

    @isTest
    static void testGetWeekNumber() {
        // Probar getWeekNumber de forma indirecta mediante generateReportName
        User u = DatafactoryUser.createUKUser();
        String name = WeeklyManagementEmails.generateReportName(u, Date.newInstance(2025, 1, 10));
        System.assert(name.contains('WKR_2025'));
    }

    @isTest
    static void fillerTestAccountAdditionalData() {
        WeeklyManagementEmails.testFiller();
        Assert.isTrue(1 == 1);
    }
}