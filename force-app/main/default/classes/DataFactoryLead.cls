/**
 * @author Ramón Prades
 * @date June 2020
 * @group Leads
 * @description Class to create test leads
 */
public class DataFactoryLead {
    
    public static Boolean autoInsert = true;   
    
    public static Lead[] createWebRequest(Integer num) {
        Lead[] leads = new List<Lead>();
        for (Integer i = 0; i<num; i++) {
            String random = TestUtils.generateRandomString(6);
            Lead theLead = new Lead();
            theLead.Opportunity_Name__c = 'Test Web Request ' + random;
            theLead.LastName = 'Smith' + random;
            theLead.FirstName = 'Algernoon';
            thelead.Email = 'testwr@testdomain.cxm';
            theLead.CountryCode__c = 'GB';
            theLead.CountryCode = 'GB';
            
            Schema.DescribeFieldResult field = Lead.LeadSource.getDescribe();
            List<Schema.PicklistEntry> ple = field.getPicklistValues();
            if (ple.size() > 0) {
                theLead.LeadSource = ple[0].getLabel();
            }

            theLead.LeadType__c = 'Contact Form';
            theLead.LeadSubtype__c = 'Catalog Request';
            theLead.Source__c = 'WEB';
            thelead.RecordTypeId = RecordTypeLibrary.Lead_WebRequest;
                
            leads.add(theLead);
        }     

        if(Test.isRunningTest()) {
            if (autoInsert) {
                insert leads;
            }
        }
        		
        return leads;
    }

    public static Lead[] createUSWebRequest(Integer num) {
        Lead[] leads = new List<Lead>();
        for (Integer i = 0; i<num; i++) {
            String random = TestUtils.generateRandomString(6);
            Lead theLead = new Lead();
            theLead.Opportunity_Name__c = 'Test Web Request ' + random;
            theLead.LastName = 'Smith' + random;
            theLead.FirstName = 'Algernoon';
            thelead.Email = 'testwr@testdomain.cxm';
            theLead.CountryCode__c = 'US';
            theLead.CountryCode = 'US';
            theLead.State__c = 'NJ';
            
            Schema.DescribeFieldResult field = Lead.LeadSource.getDescribe();
            List<Schema.PicklistEntry> ple = field.getPicklistValues();
            if (ple.size() > 0) {
                theLead.LeadSource = ple[0].getLabel();
            }

            theLead.LeadType__c = 'Contact Form';
            theLead.LeadSubtype__c = 'Catalog Request';
            theLead.Source__c = 'USW';
            thelead.RecordTypeId = RecordTypeLibrary.Lead_USWebRequest;
                
            leads.add(theLead);
        }     

        if(Test.isRunningTest()) {
            if (autoInsert) {
                insert leads;
            }
        }
        		
        return leads;
    }


}