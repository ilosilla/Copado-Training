@isTest
public class DashboardEmailAlert_Batch_Test {
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
        
        	DashboardEmailAlert_Batch obj = new DashboardEmailAlert_Batch();
        	Id batchJobId = DataBase.executeBatch(obj);
        	Integer emailsSent = Limits.getEmailInvocations();
        	System.debug('emailsSent before: ' + Limits.getEmailInvocations());
        
        Test.stopTest();
        System.debug('emailsSent after: ' + Limits.getEmailInvocations());
        
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
                            FROM AsyncApexJob WHERE Id = :batchJobId];
                
        System.assertEquals(job.NumberOfErrors, 0);
        //System.assertEquals([SELECT Count() FROM User WHERE IsActive = true] , emailsSent);
        
    }
}