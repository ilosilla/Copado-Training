/**
* @author 		Ramón Prades
* @date 		$CURRENT_MONTH_NAME $CURRENT_YEAR
* @group 		Accounts
* @description 	Enter a description con variable ${fileExtname}
*               @deprecated by LeadsDomain.
*/
@isTest private class LeadNewTriggerHandlerTest {
    @isTest private static void testDumy() {
        System.assertEquals('Product Support', LeadNewTriggerHandler.productSupportStatus);
    }
    /*

    @testSetup static void makeData(){        
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

        SYstemSettings.USClaimsManager = claimsUser.EMail;

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
            theLeads[0].RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
            
            // Lead 1 is non US
            theLeads[1].Title = 'NON US LEAD';
            theLeads[1].Email = 'sfdasfasd@sdfdasfas.com';
            theLeads[1].CountryCode__c = 'GB';
            theLeads[1].RecordTypeId = RecordTypeLibrary.Lead_WebRequest;

            insert theLeads; 

        }
    } // makeData

    @isTest private static void testUSInsert() {
        USer regular = [select Id, name from User where LastName = 'REGULAR' limit 1];
        Lead l = [select Id, OwnerId, CountryCode__c from Lead where Title = 'US LEAD' limit 1];
        System.assertEquals('US', l.CountryCode__c, 'Country should be the US');
        System.assertEquals(regular.Id, l.OwnerId, 'Owner should be the regular user');
    }

    @isTest private static void testNonUSInsert() {
        USer regular = [select Id, name from User where LastName = 'REGULAR' limit 1];
        Lead l = [select Id, OwnerId, CountryCode__c from Lead where Title = 'NON US LEAD' limit 1];
        System.assertEquals(regular.Id, l.OwnerId, 'Owner should be the regular user');
    }

    @isTest private static void testBeforeUpdate() {
        USer claims = [select Id, name from User where LastName = 'CLAIMS' limit 1];
        Lead l = [select Id, OwnerId, CountryCode__c, Status from Lead where Title = 'US LEAD' limit 1];
        l.Status = 'Product Support';
        update l;
        System.assertEquals(1, 1, 'Coverage');
    }
 */
        
}