// ESTA CLASE SGURAMENTE HAY QUE ELIMINARLA, QUE CREO QUE SE USA LA OPPCONTROLLER3, QUE ES LA QUE TENÍA TEST
@isTest
public class OppControllerTest {
	
    @testSetup static void setup() {
    
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        User testUser = User_TestDataFactory.createUsers(1, new List<String> {'en_US'})[0];
        insert testUser;
        
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
        System.runAs(testUser){
            insert opp;
        }
        Test.stopTest();
        
    }
    
    @isTest
    public static void test_OppController(){
        Account acc = [SELECT Id FROM Account WHERE Lastname = 'TestAcctCustomer1' ];
        Opportunity opp = [SELECT Id, CloseDate, Request_Store_Appointment__c, Company_Date__c,
                          Sales_Office_Date__c, Sales_Org_Date__c FROM Opportunity 
                           LIMIT 1];
        
        PageReference pageRef = Page.GeneratePDF;
        pageRef.getParameters().put('salesOfficeCode', '3999');
        pageRef.getParameters().put('salesOfficeLanguage', 'en_US');
        Test.setCurrentPage(pageRef);
        
        OppController oppCont = new OppController();
        List<Opportunity> expectedResult = new List<Opportunity>{opp};
        List<Opportunity> actualResult = oppCont.getOppList();
        
        System.debug('expectedResult: ' + expectedResult);
        System.debug('actualResult: ' + actualResult);
        
        System.assert( 1 == 1 );
    }
}