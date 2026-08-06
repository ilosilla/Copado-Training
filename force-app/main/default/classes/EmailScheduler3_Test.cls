@isTest
public class EmailScheduler3_Test{
    
    private static List<Opportunity> opportunityList;
    private static String CRON_EXP = '0 0 0 3 9 ? 2030';
    private static Date yesterdayDate = Date.Today().addDays(-1);
    
    @testSetup static void setup(){
        
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        List<User> userList = User_TestDataFactory.createUsers(4, new List<String>{'en_GB', 'en_US', 'fr_FR', 'es_ES'});
        insert userList;
        
        System.runAs(userList[0]){
            Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
            Test.startTest();
            insert Opportunity_TestDataFactory.createOppsWithReqDate(2, yesterdayDate);
            Test.stopTest();
        }
        
        // randomContact (queried in EmailScheduler3)
        insert new Contact(LastName='testLastName', FirstName='testFirstName', Title='Mr');
        
        
    }
    
    private static void init(){
        
        opportunityList = [SELECT Id
                           FROM Opportunity
                           WHERE Request_Store_Appointment__c =: yesterdayDate];
        //System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }

    //@isTest
    @isTest static void execute_englishUserTest(){        
        init();        
        User u = [SELECT Id FROM User WHERE ((LocaleSidKey = 'en_GB') OR (LocaleSidKey = 'en_US')) AND (isActive = TRUE) LIMIT 1];        
        String jobId = System.schedule('EmailScheduler3', CRON_EXP, new EmailScheduler3());            
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];            
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);        
        // Verify the next time the job will run
        System.assertEquals('2030-09-03 00:00:00', String.valueOf(ct.NextFireTime));            
}
    
    @isTest static void execute_frenchUserTest(){        
        init();        
        User u = [SELECT Id FROM User WHERE LocaleSidKey = 'fr_FR' AND isActive = TRUE LIMIT 1];
        String jobId = System.schedule('EmailScheduler3', CRON_EXP, new EmailScheduler3());            
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];            
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);        
        // Verify the next time the job will run
        System.assertEquals('2030-09-03 00:00:00', String.valueOf(ct.NextFireTime));            
}
    
    @isTest static void execute_spanishUserTest(){        
        init();        
        User u = [SELECT Id, LanguageLocaleKey FROM User WHERE LocaleSidKey = 'es_ES' AND isActive = TRUE LIMIT 1];        
        String jobId = System.schedule('EmailScheduler3', CRON_EXP, new EmailScheduler3());            
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];            
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);        
        // Verify the next time the job will run
        System.assertEquals('2030-09-03 00:00:00', String.valueOf(ct.NextFireTime));            
    }
}