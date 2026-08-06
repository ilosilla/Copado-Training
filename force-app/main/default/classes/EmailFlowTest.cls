@isTest
public class EmailFlowTest {
	
    @testSetup static void setup() {
    	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
		insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
		
		List<User> testUsers = User_TestDataFactory.createUsers(2, new List<String>{'fr_FR', 'es_ES'});
		Insert testUsers;
    
    }
    
    // Test for the method void execute(List<String> emailList)
    @isTest static void test_execute(){
        User testUser_fr = [SELECT Id, Name FROM User WHERE UserName 
                           LIKE '%@testOrg0.com' AND LanguageLocaleKey = 'fr' ];
        User testUser_es = [SELECT Id, Name FROM User WHERE UserName 
                           LIKE '%@testOrg1.com' AND LanguageLocaleKey = 'es'];
        
    	Test.startTest();
            // Test 1/ Fail Porque no se encuentran las plantillas
        	String actualResult_1 = EmailFlow.execute( new List<string> () )[0];
        	Integer invocations_1 = Limits.getEmailInvocations();
        	System.assertEquals(0, invocations_1);        	
        	// System.assertEquals('SendEmail failed. First exception on row 0; first error: REQUIRED_FIELD_MISSING, Add a recipient to send an email.: []', actualResult_1);
        
        	// Test 2/ Success
        	String actualResult_2 = EmailFlow.execute( new List<string> {'mail@mail.com'} )[0];
        	Integer invocations_2 = Limits.getEmailInvocations();
        	System.assertEquals(1, invocations_2);
        	System.assertEquals('Success', actualResult_2);
        
        	// Test 3/ Success
        	String actualResult_3;
        	System.runAs(testUser_fr){
            	actualResult_3 = EmailFlow.execute( new List<string> {'mail@mail.com'} )[0];
        	}
        	
        	Integer invocations_3 = Limits.getEmailInvocations();
        	System.assertEquals(2, invocations_3);
        	System.assertEquals('Success', actualResult_3);
        
        	// Test 3/ Success
        	String actualResult_4;
        	System.runAs(testUser_es){
            	actualResult_4 = EmailFlow.execute( new List<string> {'mail@mail.com'} )[0];
        	}
        	
        	Integer invocations_4 = Limits.getEmailInvocations();
        	System.assertEquals(3, invocations_4);
        	System.assertEquals('Success', actualResult_4);
        Test.stopTest();
        
	}
}