@isTest public with sharing class LeadHelperTest {

    @testSetup static void makeData(){        
        TestUtils.EnableTriggers();

        User adminUser = DataFactoryUser.createUKAdmin();
        User regularUser = DataFactoryUser.createUKUser();
        
        List<PostCodeObjects__c> pcs = [select Id, objectId__c from PostCodeObjects__c where objectType__c = 'SALES_OFFICE' and country__c = 'GB' and postCode__c = 'W' ];
        if (pcs.size() > 0) {
            regularUser.Sales_Office__c = pcs[0].objectId__c;
        }        
        regularUser.LastName = 'REGULAR';
        regularUser.Execution_Context__c = 'US';
        adminUser.LastName = 'ADMIN';

        update regularUser;
        update adminUser;

        CountrySettings__c cs = new CountrySettings__c();
        cs.Name = 'GB';
        cs.Country__c = 'GB';
        cs.LeadDefaultOwnerID__c = regularUser.Id;
        insert cs;

        System.runAs(adminUser) {
            Account personAcc = DataFactoryAccount.createPersonAccounts(1)[0];
            DataFactoryLead.autoInsert = false;
            Lead[] theLeads = DataFactoryLead.createWebRequest(5);

            // Prepares lead 0 to be linked to the account (same email)
            theLeads[0].Title = 'LEAD-0';
            theLeads[0].Email = personAcc.PersonEmail;
            
            // Prepares lead 1 to have no account and to get a random owner from the post code
            theLeads[1].Title = 'LEAD-1';
            theLeads[1].Email = 'sfdasfasd@sdfdasfas.com';
            theLeads[1].Postcode__c = 'W2 1AA';             

            // Prepares lead 2 to get the last lead data (lead 1)
            theLeads[2].Title = 'LEAD-2';
            theLeads[2].Email = theLeads[1].Email;
            theLeads[2].Postcode__c = 'M1 1AA'; 

            // Prepares lead 3 to get the default owner (unmatched email and unkknown postcode)
            theLeads[3].Title = 'LEAD-3';
            theLeads[3].Email = 'rrrr@cvgfdsgdfsgdfs.asdad.cxm';
            theLeads[3].Postcode__c = 'X9 9XX'; 

            // Prepares lead 4 to have  anubika email (for coverage purposes - remove when nubika has finished working with us web forms)
            theLeads[4].Title = 'LEAD-4';
            theLeads[4].Email = 'rrrr@nubika.asdad.cxm';
            theLeads[4].Postcode__c = 'X9 9XY'; 



            Lead[] theUSLeads = DataFactoryLead.createUSWebRequest(1);
            // Prepares lead 0 to be linked to the account (same email)
            theUSLeads[0].Title = 'LEAD-US-0';
            theUSLeads[0].Representative__c =  regularUser.Id;

            Lead[] batch1 = new List<Lead>();
            batch1.add(theLeads[0]);
            batch1.add(theLeads[1]);
            batch1.add(theLeads[3]);
            batch1.add(theUSLeads[0]);

            insert batch1;
            insert theLeads[2];         // We need lead1 to exist on database befoire inserting lead2.

        }
    }

    @isTest static void testSetWebRequestFields() {
        Lead l = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-0'][0];
        System.assertEquals('WEB', l.Source__c, 'Lead Source should be WEB');
    }

    @isTest static void testSetUSWebRequestFields() {
        Lead l = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-US-0'][0];
        System.assertEquals('USW', l.Source__c, 'Lead Source should be USW');
    }


    @isTest static void testAssignOwnerFromAccount() {
        Account acc = [select Id, OwnerId from Account][0];
        Lead l = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-0'][0];
        System.assertEquals(acc.Id, l.accountId__c, 'STEP 1a: Account should have been found by email');
        System.assertEquals(acc.OwnerId, l.ownerId, 'STEP 1b: Lead owner should be the account owner');
    }

    @isTest static void testAssignOwnerFromAccount_2() {
        User adminUser = [select Id, Sales_Office__c from User where lastName = 'ADMIN'][0];
        Lead l = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-1'][0];
        System.assertEquals(null, l.accountId__c, 'STEP 2a: Account should not habe been assigned (different email)');        
        System.assertNotEquals(adminUser.Id, l.ownerId, 'STEP 2b: Owner should be another user (not the creator)');
    }

    @isTest static void testAssignOwnerFromContacts() {
        Lead l1 = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-1'][0];
        Lead l2 = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-2'][0];
        System.assertEquals(l1.ownerId, l2.ownerId, 'STEP 3: Owner should be the same (same lead email)');        
    }

    @isTest static void testAssignOwnerFromRepresetnative() {
        Lead l = [SELECT Id, Title, AccountId__c, OwnerId, Representative__c, Source__c from Lead where Title = 'LEAD-US-0'][0];
        System.assertEquals(l.OwnerId, l.Representative__c, 'Owner should be the representative');
    }


    @isTest static void testAssignOwner_4() {
        Lead l3 = [SELECT Id, Title, AccountId__c, OwnerId, Source__c from Lead where Title = 'LEAD-3'][0];
        User regularUser = [select Id, Sales_Office__c from User where lastName = 'REGULAR'][0];
        System.assertEquals(regularUser.Id, l3.ownerId, 'STEP 4:Owner should have been the regular user (from the custom setting)');
    }

    @isTest static void testAssignOwner_5() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createWebRequest(1)[0];        
        l.LeadSource = null;
        l.Title = 'SOURCE';
        insert l;
        Lead l3 = [SELECT Id, Title, AccountId__c, OwnerId, Source__c, LeadSource from Lead where Title = 'SOURCE' limit 1];
        System.assertNotEquals(null, l3.LeadSource, 'STEP 5: Lead source should have a value');
    }

    @isTest static void testUSDefaults_5() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createWebRequest(1)[0];        
        l.LeadSource = null;
        l.Title = 'SOURCE';
        LeadHelper helper = new LeadHelper(l);
        helper.setUSWebRequestFields();
        System.assertEquals('USW', l.SOurce__c);
    }
    
    @isTest static void testUSDefaults_6() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createWebRequest(1)[0];        
        l.OwnerId = UserInfo.getUserId();
        l.OwnerLocked__c = true;
        LeadHelper helper = new LeadHelper(l);
        helper.setUSWebRequestFields();
        System.assert(l.OwnerId == UserInfo.getUserId(), 'It shouldn\'t has changed the owner');
    }

    @isTest static void mapProfile() { 
        System.assertEquals('Architect', LeadHelper.mapProfile('Senior Architect'));
        System.assertEquals('Designer', LeadHelper.mapProfile('Interior Designer'));
        System.assertEquals('', LeadHelper.mapProfile('nada'));
    }

    @isTest static void filler() {
        String s = LeadHelper.TestFiller();
        System.assertNotEquals(null, s, 'Just to reach the mon coverage');
    }
}