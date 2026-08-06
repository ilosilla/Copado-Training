@isTest
public class OppContactRolesErrorControllerTest {
	@testSetup 
    static void setup() {
        TestUtils.enableTriggers();
        User testUser = User_TestDataFactory.createUsers(1, new List<String> {'en_US'})[0];
        insert testUser; 
        
        // Account con Sales Rel
        Account acc = Account_TestDataFactory.createBusinessAccount();
        Insert acc;

        List<Contact> contList = Contact_TestDataFactory.createContacts(2, new List<Map<String, Object>>{
            new Map<String, Object>{'AccountId' => acc.Id},
            new Map<String, Object>{'AccountId' => acc.Id}
        });
        Insert contList;
        
        Opportunity opp = Opportunity_TestDataFactory.createTrade(acc);
        opp.Name = 'retrieve test Opp';
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        	System.runAs(testUser){
            	Insert opp;
        	}
        	opp.Sales_Org__c = null;
        	Update opp;
        	OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contList[0].Id, SapStatus__c = 'Error');
        	OpportunityContactRole oppActor2 = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contList[1].Id, SapStatus__c = 'Error');
        	Insert new List<OpportunityContactRole>{oppActor1, oppActor2};
        Test.stopTest();
    }
    
    @isTest
    public static void returnOppContactRolesErrors(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'retrieve test Opp'];
        System.assert(OppContactRolesErrorComponentController.returnOppContactRolesErrors(opp.Id).size() > 0);
    }
    
    @isTest
    public static void retry(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'retrieve test Opp'];
        opp.Sales_Org__c = '206';
        Update opp;
        
        OpportunityContactRole oppActor = [SELECT Id FROM OpportunityContactRole 
                                         WHERE OpportunityId =: opp.Id AND SapStatus__c = 'Error' LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        	System.assertEquals('', OppContactRolesErrorComponentController.retry(oppActor.Id));
        Test.stopTest();
        System.assertNotEquals('', OppContactRolesErrorComponentController.retry(''));
    }
}