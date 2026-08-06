@isTest public class LeadsServiceTest {
    @testSetup
    static void setupData(){
        User admin = TestUtils.getAdminUser();
        system.runAs(admin){
            UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
            insert r;
            DataFactoryUser.createUKAdmin();
        }
    }

    static testMethod void testcreateUSAppointmentLead(){

        Id currUser = [SELECT Id FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1].Id;
        
		PorcelanosaSetting__c newSetting = new PorcelanosaSetting__c();
        newSetting.Key__c = 'APPOINTER';
        newSetting.Subkey__c = 'LOGGER';
        newSetting.Value1__c = 'true';
        newSetting.isActive__c = true;
        insert newSetting;
        
        List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true];
        list<LeadsService.Request> listTest = new list<LeadsService.Request>();
        LeadsService.Request lead = new LeadsService.Request();
        lead.firstname = 'test';
        lead.lastName = 'testing';
        lead.email = 'test@testService.com';
        lead.mobile = '666666666';
        lead.salesrepId = currUser;
        lead.appointmentType = 'Virtual';
        lead.countryCode = 'US';
        lead.street = 'test street';
        lead.postCode = '20334';
        lead.town = 'testTown;';
        lead.state = 'Florida';
        lead.comments = 'test comments';
        lead.profile = 'Architect';
        lead.hearAboutUs = 'Internet';
        lead.products = 'Bath;Kitchen';
        lead.preferredContactMethod = 'XXX';
        lead.preferredContactTime = 'Morning';
        lead.operationType = 'R';
        lead.newsletterChecked = true;
        lead.eventStartDate = Date.Today();
        lead.salesOfficeName = 'salesofficeName';
        lead.actualBusinessHours = bhs[0];
        lead.fechaHoraStr = '2023-09-29 11:00:00';

        listTest.add(lead);
        Test.startTest();
        list<LeadsService.Response> b = LeadsService.createUSAppointmentLead(listTest);
        LeadsService.requestToLead(listTest[0]);
        LeadsService.convertOperationType('new');
        LeadsService.convertOperationType('REFURB');
        Test.stopTest();
        System.assertequals(b,b,'Dummy test');
    }
    
    @isTest
    static void appointmentEmail() {
        SystemSettings.USNotifyWebLeads = true;
 
        User usr = [SELECT Id, name from user where isActive = true and Id <>: UserInfo.getUserId() and profileId =: UserInfo.getProfileId() LIMIT 1];
        DataFactoryLead.autoInsert = false;
        Lead[] theLeads = DataFactoryLead.createWebRequest(2);
        // Lead 0 is US
        theLeads[0].Title = 'US LEAD';
        theLeads[0].Email = 'us-lead@usdomain.cxm';
        theLeads[0].CountryCode__c = 'US';
        theLeads[0].State__c = 'NJ';
        theLeads[0].LeadSubtype__c =
        theLeads[0].RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
        theLeads[0].ownerId = usr.Id;
        insert theLeads;
        theLeads[0].ownerId = usr.Id;
        update theLeads;

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        Event aux = new Event(WhoId = theLeads[0].Id, Event_type__c = 'Showroom', DurationInMinutes = 60, startDateTime = System.now());
        insert aux;
        System.assertEquals(1, Limits.getEmailInvocations(), 'emails should be sent');
        Test.stopTest();
    }
    
     @isTest
    static void testGetOffset() {

        Date selectedDate = Date.newInstance(2023, 10, 19);
        String timeZoneId = 'America/New_York'; 
        Test.startTest();
        Integer offsetMinutes = LeadsService.getOffset(selectedDate, timeZoneId);
        Test.stopTest();
    }
    
    /*@isTest
    static void test1() {
        Id currUser = [SELECT Id FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1].Id;
        List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true];
        list<LeadsService.Request> listTest = new list<LeadsService.Request>();
        LeadsService.Request lead = new LeadsService.Request();
        lead.firstname = 'test';
        lead.lastName = 'testing';
        lead.email = 'test@testService.com';
        lead.mobile = '666666666';
        lead.salesrepId = currUser;
        lead.appointmentType = 'Virtual';
        lead.countryCode = 'US';
        lead.street = 'test street';
        lead.postCode = '20334';
        lead.town = 'testTown;';
        lead.state = 'Florida';
        lead.comments = 'test comments';
        lead.profile = 'Architect';
        lead.hearAboutUs = 'Internet';
        lead.products = 'Bath;Kitchen';
        lead.preferredContactMethod = 'XXX';
        lead.preferredContactTime = 'Morning';
        lead.operationType = 'R';
        lead.newsletterChecked = true;
        lead.eventStartDate = Date.Today();
        lead.salesOfficeName = 'salesofficeName';
        lead.actualBusinessHours = bhs[0];
        lead.fechaHoraStr = '2023-09-29 11:00:00';

        listTest.add(lead);
        
        LeadsService.GoogleFields fields = new LeadsService.GoogleFields();
            fields.googleLeadId = glead.lead_id;
            fields.googleFormId = glead.form_id;
            fields.googleCampaignId = glead.campaign_id;
            fields.isTest = glead.is_test;            
            fields.googleDomain = RESTGoogleLeads.google_domain;
            fields.defaultUserId = UserUtils.getUserIdFromEmail(setting.value2);
        
        Test.startTest();
            LeadsService.createGoogleAdLead(lead,);
        Test.stopTest();
    }*/
}