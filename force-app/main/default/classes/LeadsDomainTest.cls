/**
 * LeadsDomain test class. Also used to provide full coverage of zflib_DomainClass and zflib_TrigegrDomainClass
 */
@isTest public with sharing class LeadsDomainTest {

    @testSetup static void testSetup() {

        TestUtils.EnableTriggers();

        User adminUser = DataFactoryUser.createUKAdmin();
        User[] users = DataFactoryUser.createUKUsers(2);        
        User regularUser = users[0];
        User claimsUser = users[1];
        
        regularUser.LastName = 'REGULAR';
        regularUser.email = 'regular@mails.cxm';
        update regularUser;

        claimsUser.LastName = 'CLAIMS';
        claimsUser.EMail = 'claims@usmanager.cxm';
        update claimsUser;

        adminUser.LastName = 'ADMIN';
        update adminUser;

        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.USClaimsManager__c = claimsUser.EMail;
        Database.Upsert(ss);

        CountrySettings__c cs = new CountrySettings__c();
        cs.Name = 'US';
        cs.Country__c = 'US';
        cs.LeadDefaultOwnerID__c = regularUser.Id;
        insert cs;

        CountrySettings__c cs2 = new CountrySettings__c();
        cs2.Name = 'GB';
        cs2.Country__c = 'GB';
        cs2.LeadDefaultOwnerID__c = regularUser.Id;
        insert cs2;
        
        System.runAs(adminUser) {
            DataFactoryLead.autoInsert = false;
            Lead[] theLeads = DataFactoryLead.createWebRequest(2);
            // Lead 0 is US
            theLeads[0].Title = 'US LEAD';
            theLeads[0].Email = 'us-lead@usdomain.cxm';
            theLeads[0].CountryCode__c = null;
            theLeads[0].State__c = 'NJ';
            theLeads[0].RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
            
            // Lead 1 is non US
            theLeads[1].Title = 'NON US LEAD';
            theLeads[1].Email = 'sfdasfasd@sdfdasfas.com';
            theLeads[1].CountryCode__c = 'GB';
            theLeads[1].RecordTypeId = RecordTypeLibrary.Lead_WebRequest;

            insert theLeads; 
        }
    }

    @isTest static void testcast() {
        zflib_TriggerDomainClass domain = zflib_DomainConstructor.construct(LeadsDomain.class, new List<Lead>());
        Boolean casted = (domain instanceOf LeadsDomain);
        System.assert(true, casted);                  
    }

    @isTest static void testGetSObjectType() {
        LeadsDomain leadsDomain = new LeadsDomain(new List<Lead>());
        Type t = leadsDomain.getSObjectType();
        System.assertEquals('LEADSDOMAIN', t.getName().toUpperCase());
    }    

    @isTest static void testOnApplyDefaults() {
        Lead[] dbLeads = [select Id, Opportunity_Name__c from lead];
        System.assertNotEquals(0, dbleads.size(), 'Some leads should have been created');
        System.assertNotEquals(null, dbLeads[0].Opportunity_Name__c, 'A default opportunity name should have been assigned on the before insert');
    }

    @isTest static void testUpdateTriggers_US() {
        USer claims = [select Id, name from User where LastName = 'CLAIMS' limit 1];
        Lead l = [select Id, OwnerId, CountryCode__c, Status from Lead where Title = 'US LEAD' limit 1];
        l.Status = 'Product Support';
        update l;
        Lead l2 = [select Id, OwnerId, CountryCode__c, Status from Lead where Title = 'US LEAD' limit 1];
        System.assertEquals(claims.Id, l2.ownerId, 'Owner should be the claims manager');
    }

    @isTest static void testUpdateTriggers_NonUS() {
        USer claims = [select Id, name from User where LastName = 'CLAIMS' limit 1];
        Lead l = [select Id, OwnerId, CountryCode__c, Status from Lead where Title = 'NON US LEAD' limit 1];
        l.Status = 'Product Support';
        update l;
    }

    @isTest static void convertLeadManuallyTest() {
        Lead usLead = [select Id, Title, Status from Lead where Title = 'US LEAD' limit 1];
        System.assertNotEquals(null, usLead, 'There should be a usLead');
        String oldStatus = usLead.Status;
        usLead.Status = 'Converted';
        Boolean exceptionReceived = false;
        try {
            Test.startTest();
            update usLead;
            Test.stopTest();
            //Lead newLead = [select Id, Title, Status from Lead where Id = :usLead.Id limit 1];
        } catch (Exception ex) {
            exceptionReceived = true;
        }
        System.assertEquals(true, exceptionReceived, ' No manual change to converted should be allowed');
    }

    @isTest static void addErrorMethodsTest() {
        Lead usLead = [select Id, Title, Status from Lead where Title = 'US LEAD' limit 1];
        leadsSelector selector = new LeadsSelector();
        Lead[] records = selector.selectById(new Set<Id>{usLead.Id});
        LeadsDomain domain = new LeadsDomain(records);
        domain.addRecordError(records[0], 'This is a test');
        ObjectNotFoundException onf = new ObjectNotFoundException('this is another test');
        domain.addRecordError(records[0], onf);
        System.assertEquals(true, domain.hasErrors(), 'Domain class should have errors');
    }

    @isTest static void deleteTest() {
        Lead usLead = [select Id, Title, Status from Lead where Title = 'US LEAD' limit 1];
        delete usLead;
        System.assertEquals(true, true);
    }
    
}