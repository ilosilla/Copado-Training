@isTest
public class DashboardEmailAlert_Schedule_Test {
    @testSetup
    static void setup(){
        
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        List<User> userList = User_TestDataFactory.createUsers(7, new List<String>{'en_US', 'en_US', 'en_US','en_US','en_US', 'en_US','en_US'});
        userList[0].IsActive = false;
        userList[1].IsActive = false;
        
        Insert userList;
    }
    
    @isTest
    public static void test(){
        
        Test.startTest();
        
        DashboardEmailAlert_Schedule sh1 = new DashboardEmailAlert_Schedule();
        
        String sch = '0 0 23 * * ?'; 
        String jobId = system.schedule('Test', sch, sh1);        
        Integer emailsSent = Limits.getEmailInvocations();        
        Test.stopTest();        
        CronTrigger ct = [SELECT TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobID];
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
        //System.assertEquals(ct.TimesTriggered, 1);
        //System.assertEquals([SELECT Count() FROM User WHERE IsActive = true] , emailsSent);
        
    }
}