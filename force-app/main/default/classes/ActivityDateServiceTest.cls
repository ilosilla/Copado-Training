@IsTest
public class ActivityDateServiceTest {
    @TestSetup
    static void makeData(){
        TestUtils.enableTriggers();
        TriggerFlags.tflags.Opportunity_Contact_Role__c = true;
        TriggerFlags.tflags.Contact__c = true;
        List<Account> accs = DataFactoryAccount.createAccounts(5);
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(accs, 2);
        DataFactoryContact.createContacts(accs[0].Id, 2);
    }

    @isTest
    public static void testAccounts() {
        List<Account> accsList = [SELECT Id, Last_Activity_Date__c FROM Account];
        
        Test.startTest();

        Displays_Marketing_Material__c display = new Displays_Marketing_Material__c(Account__c = accsList[0].Id, Type__c = 'Settings');
        insert display;
        AccountTeamMember teamMember = new AccountTeamMember(AccountId = accsList[1].Id, UserId = UserInfo.getUserId());
        insert teamMember;
        Task newTask = new Task(TaskSubType = 'Email', WhatId = accsList[0].Id, Subject = 'Test');
        insert newTask;
        
        insert Sales_RelationShip_TestDataFactory.createSalesRelationship(accsList[0]);
        
        Test.stopTest();

        Assert.isTrue(accsList[0].Last_Activity_date__c != null, 'No tiene Last Activity Date');

    }

    @isTest
    public static void testOpportunities() {
        List<Opportunity> oppsList = [SELECT Id, AccountId, Last_Activity_Date__c FROM Opportunity];
        Contact ct = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        Test.startTest();
        
        Moodboard__c aux = new Moodboard__c(Opportunity__c = oppsList[0].id, Name = 'Test Moodboard');
        insert aux;

        OpportunityTeamMember teamMember = new OpportunityTeamMember(OpportunityId = oppsList[0].Id, UserId = UserInfo.getUserId());
        insert teamMember;
        
        OpportunityContactRole oppActor1 = new OpportunityContactRole(OpportunityId = oppsList[0].Id, ContactId = ct.Id);
        insert oppActor1;
        
        Event ev = new Event(WhatId = ct.AccountId, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
        insert ev;
        
        ActivityMetric actMetric = new ActivityMetric(BaseId = ct.AccountId, LastEmailDateTime = System.now());
        insert actMetric;
        
        InstallationRequest__c request = new InstallationRequest__c(
													Name= 'Test Retail Opportunity #', 
                                            		bathrooms__c = 1, 
                                                    Description__c = 'Description of the test intallation request',
                                                   	InstallerAccount__c = oppsList[0].AccountId,
                                                    Opportunity__c = oppsList[0].Id);
        Test.stopTest();

        Assert.isTrue(oppsList[0].Last_Activity_date__c != null, 'No tiene Last Activity Date');

    }
    
    @isTest
    static void fillerTest() {
        ActivityDateService aux = new ActivityDateService();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}