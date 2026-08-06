@isTest
public class AutomaticContactRolesSendToSapTest {
    @testSetup 
    static void setup() {
        TestUtils.enableTriggers();
        TriggerFlags.tflags.Opportunity_Contact_Role__c = false;
		
        CollaborationGroup collabGroup = new CollaborationGroup(Name = 'test group name', CollaborationType = 'Private');
        Insert collabGroup;
        
        // Setup Test 1
        Account privateAcc = Account_TestDataFactory.createCustomer();
        Insert privateAcc;

        Account privateAccountPlus = [SELECT Id, PersonContactId from Account where Id =: privateAcc.Id LIMIT 1];

        Opportunity opp = Opportunity_TestDataFactory.createTrade(privateAcc);
		Insert opp;
        
        List<OpportunityContactRole> oppActorList = new List<OpportunityContactRole>();
        oppActorList.add(new OpportunityContactRole(ContactId = privateAccountPlus.PersonContactId, OpportunityId = opp.Id));
        Insert oppActorList;
        
        // Setup Test 2
        List<Account> accListToInsert = new List<Account>();
        for(Integer i=0; i<2; i++){
            Account acc = Account_TestDataFactory.createBusinessAccount();
            acc.Name = 'Bulk Test Acc';
            accListToInsert.add(acc);
        }
        Account_TestDataFactory.insertAccounts(accListToInsert);

        List<Contact> contList = Contact_TestDataFactory.createContacts(2, new List<Map<String, Object>>{
            new Map<String, Object>{'AccountId' => accListToInsert[0].Id},
            new Map<String, Object>{'AccountId' => accListToInsert[1].Id}
        });
        Insert contList;
        
        List<Opportunity> oppListToInsert = new List<Opportunity>();
        for(Integer j=0; j<accListToInsert.size(); j++){
            Opportunity oppty = Opportunity_TestDataFactory.createTrade(accListToInsert[j]);
            oppty.Name = 'Bulk Test Opp';
            oppListToInsert.add(oppty);
        }
		Insert oppListToInsert;

        for(Integer j=0; j<oppListToInsert.size()/2; j++){
            Opportunity oppty = oppListToInsert[j];
            oppty.Name = 'Bulk Test Opp Error';
            oppty.Sales_Org__c = null;
        }
        
        Update oppListToInsert;
        
        List<OpportunityContactRole> oppActorListToInsert = new List<OpportunityContactRole>();
        for(Integer k=0; k<oppListToInsert.size(); k++){
            for(Integer i=0; i<3; i++){
                oppActorListToInsert.add(new OpportunityContactRole(ContactId = contList[k].Id, OpportunityId = oppListToInsert[k].Id));
            }
        }
        Insert oppActorListToInsert;
    }
    
    @isTest
    public static void sendToSap(){
        Opportunity opp = [SELECT Id, Sales_Org__c FROM Opportunity LIMIT 1];
        List<OpportunityContactRole> oppActorList = [SELECT Id, ContactId, OpportunityId 
                                                   FROM OpportunityContactRole WHERE OpportunityId =: opp.Id];
        List<Id> oppActorIdList = new List<ID>();
        
        for(OpportunityContactRole oppActor : oppActorList){
            oppActorIdList.add(oppActor.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        	AutomaticContactRolesSendToSap.sendToSAPFuture(oppActorIdList);
        Test.stopTest();
        
        System.assertEquals(oppActorIdList.size(), [SELECT Count() FROM OpportunityContactRole WHERE Id IN: oppActorIdList AND SAPStatus__c = 'Success']);
    }
    
    @isTest
    public static void manageSendToSAP(){
        List<OpportunityContactRole> oppActorList = [SELECT Id FROM OpportunityContactRole 
                                                   WHERE Opportunity.Name LIKE 'Bulk Test Opp%'];
        
        List<Id> oppActorIdList = new List<ID>();
        
        for(OpportunityContactRole oppActor : oppActorList){
            oppActorIdList.add(oppActor.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
            AutomaticContactRolesSendToSap.manageSendToSap(oppActorList);
        Test.stopTest();

        System.assertEquals(oppActorIdList.size()/2, [SELECT Count() FROM OpportunityContactRole WHERE Id IN: oppActorIdList AND SAPStatus__c = 'Success' AND Opportunity.Name = 'Bulk Test Opp']);
        System.assertEquals(oppActorIdList.size()/2, [SELECT Count() FROM OpportunityContactRole WHERE Id IN: oppActorIdList AND SAPStatus__c = 'Error' AND Opportunity.Name = 'Bulk Test Opp Error']);
        
        Id groupId = [SELECT Id FROM CollaborationGroup WHERE Name = 'test group name'][0].ID;

        System.assertEquals(oppActorIdList.size()/2, [SELECT Count() FROM FeedItem WHERE ParentId =: groupId]);
    }
}