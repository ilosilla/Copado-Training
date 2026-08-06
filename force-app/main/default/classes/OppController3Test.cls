@isTest
public class OppController3Test {
	
    @testSetup static void setup() {
    
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        Account acc = Account_TestDataFactory.createCustomer();
        Insert acc;
        
        Opportunity opp = Opportunity_TestDataFactory.createEcommerce(acc);
        opp.CloseDate = Date.today();
        opp.Request_Store_Appointment__c =Date.today().addDays(-1);
        opp.Company_Date__c = OrganizationCommons.SOC_EUROCERAMIQUE;
        opp.Sales_Office_Date__c =  '3999'; 
		opp.Sales_Org_Date__c=OrganizationCommons.ORG_XTONE_US;
        
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        // Insertar Opportunities aca porque se inserta un actor y se lo envia a sap.
        // El run as es porque se sacan valores default del usuario.
		insert opp;
        Test.stopTest();
        
    }
    
    @isTest
    public static void test_OppController3(){
        Account acc = [SELECT Id FROM Account WHERE Lastname = 'TestAcctCustomer1' ];
        Opportunity opp = [SELECT Id, CloseDate, Request_Store_Appointment__c, Company_Date__c,
                          Sales_Office_Date__c, Sales_Org_Date__c FROM Opportunity 
                           limit 1];
        
        PageReference pageRef = Page.GeneratePDF;
        pageRef.getParameters().put('salesOfficeCode', '3999');
        pageRef.getParameters().put('salesOfficeLanguage', 'en_US');
        Test.setCurrentPage(pageRef);
        
        OppController3 oppCont = new OppController3();
        List<Opportunity> expectedResult = new List<Opportunity>{opp};
        List<Opportunity> actualResult = oppCont.getOppList();
        
        System.debug('expectedResult: ' + expectedResult);
        System.debug('actualResult: ' + actualResult);
        
        System.assertEquals( expectedResult[0].Id , actualResult[0].Id );
    }
}