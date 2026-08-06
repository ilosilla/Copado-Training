@isTest public with sharing class SAPCasesMailerHelperTest {

    static String PORSA_DEFAULT = 'porsa-default';

    @testSetup private static void testSetup() {
        DataFactoryOrganization.createData();
        List<PorcelanosaSetting__c> settingsToInsert = new List<PorcelanosaSetting__c>{
            new PorcelanosaSetting__c(Key__c = 'SAT-FACTORY-MAIL', Subkey__c = 'PORSA-DEFAULT', Value1__c = PORSA_DEFAULT),
            new PorcelanosaSetting__c(Key__c = 'SAT-FACTORY-MAIL', Subkey__c = 'PORSA-FR', Value1__c = 'porsa-fr-1;porsa-fr-2')
        };
        insert settingsToInsert;
    }

    @isTest private static void testGetFactoryEmailTest_1() {
        Sales_Org__c org = [select Id, SalesOrg__c from Sales_Org__c where CountryCode__c = 'FR' limit 1];
        String factory = 'PORSA';
        Test.startTest();
        String[] emails = SAPCasesMailerHelper.getSATFactoryEmail(factory, org.SalesOrg__c);
        Test.stopTest();
        Assert.areEqual(2, emails.size(), 'Two emails were expected');
    }

    @isTest private static void testGetFactoryEmailTest_2() {
        Sales_Org__c org = [select Id, SalesOrg__c from Sales_Org__c where CountryCode__c != 'FR' limit 1];
        String factory = 'PORSA';
        Test.startTest();
        String[] emails = SAPCasesMailerHelper.getSATFactoryEmail(factory, org.SalesOrg__c);
        Test.stopTest();
        Assert.areEqual(1, emails.size(), 'One emails were expected');
        Assert.areEqual(PORSA_DEFAULT, emails[0], 'The email should be the PORSA-DEFAULT');
    }

    @isTest private static void testGetFactoryEmailTest_3() {
        Sales_Org__c org = [select Id, SalesOrg__c from Sales_Org__c where CountryCode__c = 'FR' limit 1];
        String factory = 'NOPE';
        Test.startTest();
        String[] emails = SAPCasesMailerHelper.getSATFactoryEmail(factory, org.SalesOrg__c);
        Test.stopTest();
        Assert.areEqual(0, emails.size(), 'No emails were expected');
    }

    @isTest private static void testGetApprover() {

        // DataFactoryUser.autoInsert = false;
        User u = DataFactoryUser.createUKUsers(1)[0];
        Assert.isNotNull(u.Sales_Office__c, 'The user should have a sales office');

        PorcelanosaSetting__c setting = new PorcelanosaSetting__c();
        setting.Key__c = SAPCasesMailerHelper.RETURN_APPROVER_KEY;
        setting.Subkey__c = u.Sales_Office__c;
        setting.Value1__c = 'uno:dos:';
        setting.Value2__c = 'tres';
        setting.IsActive__c = true;
        insert setting;

        String expected = setting.Value1__c + setting.Value2__c;        
        String result = SAPCasesMailerHelper.getReturnsApprover(u.Id);

        Assert.areEqual(expected, result, 'Unexpected result');
    }

    @isTest private static void testLinkedFIlesText() {
        List<Mail.DownloadLinkInfo> links = new List<Mail.DownloadLinkInfo>();
        links.add(new Mail.DownloadLinkInfo('a', 'b'));
        String result = SAPCasesMailerHelper.getLinkedFilesText(links, 'lable');
        Assert.isNotNull(result, 'A text was expected');
    }



}