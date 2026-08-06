@isTest public class LeadConversionControllerTest {
    @TestSetup static void makeData(){
        TestUtils.enableTriggers();        
        Account acc = DataFactoryAccount.createPersonAccounts(1)[0];
        Lead[] theLeads = new List<Lead>();

        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createWebRequest(1)[0];
        l.AccountId__c = acc.Id;
        theLeads.add(l);

        Lead usl = DataFactoryLead.createUSWebRequest(1)[0];
        usl.State__c = 'CA';
        theLeads.add(usl);
        
        insert theLeads;
    }

    @isTest private static void prepareConversion() {
        Account acc = [select Id, PersonEmail from Account limit 1];
        Lead l = selectLead('GB');
        LeadConversionController.ConversionDataDTO dto = LeadConversionController.prepareConversion(l.Id);
        System.assertNotEquals(0, dto.errors.size(), 'There must be errors');
        l.Address__c = '13 Baker Street';
        l.CountryCode__c = 'GB';
        l.CountryCode = 'GB';
        l.City__c = 'London';
        l.Postcode__c = 'E1 6AN';
        l.MobilePhone = '333 666 333';       
        l.Email = acc.PersonEmail;         
        l.Operation_Type__c = 'Refurbishment';
        l.roomTypeFullHouse__c = 1;
        l.Close_Date__c = System.today();

        update l;
        dto = LeadConversionController.prepareConversion(l.Id);
        String errorMsg = '';
        if (dto.errors.size() > 0) {
            errorMsg = dto.errors[0];
        }
        System.assertEquals(0, dto.errors.size(), 'No errors should have been found ' + errorMsg);

        // Todo en un test - mala idea pero no hay tiempo
        Id oppId;
        LeadConversionController.ConversionResultDTO result = LeadConversionController.convertLead(l.id, acc.Id, null, false, oppId, '', false, false, false);
        System.assertEquals(true, result.success, 'Conversion should have been successful');

    }

    @isTest private static void prepareConversionUS_1() {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        Contact con = DataFactoryContact.createContacts(acc.Id, 1)[0];
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createWebRequest(1)[0];
        l.Email = acc.Business_Email__c;
        l.Company = 'The Very Limited Company';
        l.FirstName = con.FirstName;
        l.LastName = con.Lastname;
        insert l;
        LeadConversionController.ConversionDataDTO dto = LeadConversionController.prepareConversion(l.Id);
        System.assertNotEquals(0, dto.errors.size(), 'There must be errors');

        l.Address__c = '7 Boroline Road';
        l.CountryCode__c = 'US';
        l.CountryCode = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.Postcode__c = '07770';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        update l;
        
        dto = LeadConversionController.prepareConversion(l.Id);
        System.assertEquals(0, dto.errors.size(), 'No errors should have been found');
        LeadHelper helper = new LeadHelper(dto.lead);
        helper.setAccountAndOwner();
        System.assertEquals(acc.Id, dto.lead.AccountId__c, 'Account should have been assigned');
        System.assertEquals(con.Id, dto.lead.ContactId__c, 'Contact should have been assigned');

    }


    @isTest private static void readOpportunities() {
        Opportunity[] opps = DataFactoryOpportunity.createRetailOpportunities(1, 2);
        Id accountId = opps[0].AccountId;
        LeadConversionController.ConversionDataDTO result = LeadConversionController.readAccountInfo((String) accountId);
        System.assertEquals(2, result.opportunities.size(), 'The method should have found 2 opportunities');
    }

    @isTest private static void convertUSLead_1() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createUSWebRequest(1)[0];        
        l.Opportunity_Name__c = 'This is the opportunity title';
        l.Company = 'The Very Limited Company';
        l.Address__c = '7 Boroline Road';
        l.State__c = 'NJ';
        l.CountryCode__c = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.Postcode__c = '07770';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        l.Close_Date__c = System.today();
        insert l;   
        
        LeadConversionController.ConversionResultDTO result = LeadConversionController.convertLead(l.id, null, null, true, null, '', false, false, false);
        
        System.assertEquals(true, result.success, 'No errors should have been found');
        System.assertNotEquals(null, result.account, 'An account should have been created');
        System.assertNotEquals(null, result.account.Id, 'An account should have been created');
        System.assertNotEquals(null, result.contact, 'A contact should have been created');
        System.assertNotEquals(null, result.opportunity, 'An opportunity should have been created');

    }

    /*
     * This test creates a lead and converts it to a person account and an opportunity. Tests the 
     * account and the opportunity are created.
     * Then creates a second lead with the same email and checks it is allocated to the person account
     * created in the step before.
     */
    @isTest static void USFunctionalTest1 () {
        //Account acc = DataFactoryAccount.createPersonAccounts(1)[0];
        Lead lead = getUSRetailLead();
        insert lead;
        LeadConversionController.convertLead(lead.Id, null, null, false, null, 'THE OPPORTUNITY', false, false, false);            

        // Just one opportunity
        Opportunity[] opps = [select Id, Name, AccountId from Opportunity];
        System.assertEquals(1, opps.size(), 'There should be one oportunity'); 

        // Get the account
        Account[] accs = [select Id, isPersonAccount, PersonEmail from Account where Id = :opps[0].AccountId];
        System.assertEquals(true, accs[0].IsPersonAccount, 'Account should be a person account'); 
        System.assertEquals(accs[0].Id, opps[0].AccountId, 'Opportunity account not correct');
        System.assertEquals(accs[0].PersonEmail, lead.email, 'Lead email and account email should be  the same');

        Lead lead2 = getUSRetailLead();
        lead2.Opportunity_Name__c = 'Second Lead';                
        insert lead2;
        LeadConversionController.ConversionDataDTO dto = LeadConversionController.prepareConversion(lead2.Id);
        LeadHelper helper = new LeadHelper(dto.lead);
        helper.setAccountAndOwner();
        System.assertEquals(accs[0].Id, dto.lead.accountId__c, 'Account2 should have been assigned');
    }

    /*
     * This test creates a lead and converts it to an account, a contact and an opportunity. Tests the 
     * objects are created and associted with the opportunity. 
     * Then creates a second lead with the same email and checks it is allocated to the account
     * and contact.
     */
    @isTest static void USFunctionalTest2 () {
        Lead lead = getUSTradeLead();
        lead.Company = 'ACME Company';
        insert lead;
        LeadConversionController.convertLead(lead.Id, null, null, true, null, 'THE OPPORTUNITY', false, false, false);            

        Opportunity[] opps = [select Id, Name, AccountId, ContactId from Opportunity];
        System.assertEquals(1, opps.size(), 'There should be one oportunity'); 
        
        Account[] accs = [select Id, isPersonAccount, Business_Email__c from Account where Id = :opps[0].AccountId];
        System.assertEquals(false, accs[0].IsPersonAccount, 'Account should not be a person account'); 
        System.assertEquals(accs[0].Business_Email__c, lead.email, 'Lead email and account email should be  the same');

        /*
        Contact[] cons = [select Id, Email, AccountId from Contact where Id = :opps[0].ContactId];
        System.assertEquals(1, cons.size(), 'there should be a contact');
        System.assertEquals(accs[0].Id, cons[0].AccountId, 'The contact should belong to the account');
        */

        Lead lead2 = getUSTradeLead();
        lead2.Opportunity_Name__c = 'Second Lead';                
        insert lead2;
        LeadConversionController.ConversionDataDTO dto = LeadConversionController.prepareConversion(lead2.Id);
        LeadHelper helper = new LeadHelper(dto.lead);
        helper.setAccountAndOwner();
        System.assertEquals(accs[0].Id, dto.lead.accountId__c, 'Account2 should have been assigned');
    }


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private static Lead getUSRetailLead() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createUSWebRequest(1)[0];        
        l.Opportunity_name__c = 'This is the opportunity title';
        l.Company = '';
        l.Address__c = '7 Boroline Road';
        l.State__c = 'NJ';
        l.CountryCode__c = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.Postcode__c = '07770';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        l.Close_Date__c = System.today();
        l.firstName = 'John';
        l.lastName = 'Murray';
        l.Email = 'jmurray@gmailx.xom';
        return l;        
    }

    private static Lead getUSTradeLead() {
        DataFactoryLead.autoInsert = false;
        Lead l = DataFactoryLead.createUSWebRequest(1)[0];        
        l.Opportunity_Name__c = 'This is the opportunity title';
        l.Company = 'ACME Company';
        l.Title = 'Interior Designer';
        l.Address__c = '7 Boroline Road';
        l.CountryCode__c = 'US';
        l.State__c = 'CA';
        l.City__c = 'Upper Saddle River';
        l.Postcode__c = '07770';
        l.MobilePhone = '333 666 333';
        l.Operation_Type__c = 'Refurbishment';
        l.Close_Date__c = System.today();
        l.firstName = 'John';
        l.lastName = 'Murray';
        l.Email = 'jmurray@gmailx.xom';
        return l;        
    }

    private static Lead selectLead(String country) {
        Lead l = [select Id from Lead where CountryCode = :country limit 1];
        LeadsSelector selector = new leadsSelector();
        List<Lead> leads = selector.selectById(new Set<Id>{l.id});
        return leads[0];
    }

} // class