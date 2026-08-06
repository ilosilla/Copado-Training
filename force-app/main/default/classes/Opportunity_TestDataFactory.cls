@isTest
public class Opportunity_TestDataFactory {
    @testSetup static void setup() {
    
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    
    }

    public static Opportunity createEcommerce(Account acc) {
        //insert_SalesOrg_DistChannel();
        
        Id RecordTypeIdOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Oportunidad_neoris').getRecordTypeId();
        System.debug('RecordTypeIdOpportunity:'+ RecordTypeIdOpportunity);
        //Account a = new Account(Name='For Opportunity ecommerce');
		//insert a;
        
        Opportunity o = new Opportunity(Name= 'Test Opportunity ecommerce 1', RecordTypeId= RecordTypeIdOpportunity, 
                                        AccountId= acc.Id, StageName = 'New', CloseDate= Date.today().addDays(30), Opportunity_Classification__c = 'Airport');
        
        return o;
    }

    public static Opportunity createTrade(Account acc) {
        //insert_SalesOrg_DistChannel();
        
        Id RecordTypeIdOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_trade').getRecordTypeId();
        //Account a = new Account(Name='For Opportunity trade');
		//insert a;
        
        Opportunity o = new Opportunity(Name= 'Test Opportunity trade', RecordTypeId=RecordTypeIdOpportunity, AccountId= acc.Id, 
                                        StageName = 'New', CloseDate= Date.today().addDays(30), Opportunity_Classification__c = 'Airport');
        return o;
    }
    
    public static Opportunity createRetail() {
        //insert_SalesOrg_DistChannel();
        
        Account account = Account_TestDataFactory.createRetailer();
        //insert account;
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
		dml.DuplicateRuleHeader.runAsCurrentUser = true;

        Database.SaveResult sr = Database.insert(account, dml);
        Opportunity o;
        
        if (sr.isSuccess()) {
            System.debug('Duplicate account has been inserted in Salesforce!');
            
            Id RecordTypeIdOpportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_retail').getRecordTypeId();
            o = new Opportunity(Name= 'Test Opportunity retail', RecordTypeId=RecordTypeIdOpportunity, AccountId= account.Id, 
                                            StageName = 'New', CloseDate= Date.today().addDays(30), Opportunity_Classification__c = 'Residential (Retail)');
        }
        return o;
    }
    
    // to create Opportunities that requested a date yesterday
    public static List<Opportunity> createOppsWithReqDate(Integer numOpps, Date requestedDate) {
        //insert_SalesOrg_DistChannel();
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer i=0; i<numOpps; i++) {            
            Opportunity opportunity = createRetail();
            opportunity.Company_Date__c = OrganizationCommons.SOC_EUROCERAMIQUE;
            opportunity.Sales_Org_Date__c = OrganizationCommons.ORG_AZURCERAMIQUE;
            opportunity.Sales_Office_Date__c = '3015';
            opportunity.Request_Store_Appointment__c = requestedDate;
            opportunityList.add(opportunity);
        }
        
        
        
        return opportunityList;
        
    }
    
    public static List<Opportunity> createOpportunities(Integer numOpps, Map<String, Object> fieldsToAdd) {
        //insert_SalesOrg_DistChannel();
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        
        for(Integer i=0; i<numOpps; i++) {
            Opportunity opportunity = createRetail();
            opportunity.Company_Date__c = OrganizationCommons.SOC_EUROCERAMIQUE;
            opportunity.Sales_Org_Date__c = OrganizationCommons.ORG_AZURCERAMIQUE;
            opportunity.Sales_Office_Date__c = '3015';
            //opportunity.Opportunity_Classification__c = 'Residential';
            //opportunity.Opportunity_Classification_II__c = 'Single-family home';   
            
            // add any extra fields or replace existing ones
            for(String fieldName : fieldsToAdd.keySet()) {
                opportunity.put(fieldName, fieldsToAdd.get(fieldName));
            }
            
            opportunityList.add(opportunity);
        }
        
        return opportunityList;
        
    }
    
}