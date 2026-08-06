@isTest
public with sharing class CronINSOStatusUpdateTest {
  @testSetup
  static void setup() {
    Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();

    List<InstallationRequest__c> listINSR = DatafactoryInstallation.createInstallationRequests(2);
    DatafactoryInstallation.createInstallationOrders(listINSR);
  }

  @IsTest
    static void testBatchable() {
      List<InstallationOrder__c> listINSO = [SELECT id, StartDate__c, State__c, EndDate__c FROM InstallationOrder__c];
    
      listINSO[0].endDate__c = Date.today().addDays(10);
      listINSO[0].startDate__c = Date.today().addDays(-2);
      
      update listINSO;

      Test.StartTest();
          Database.executeBatch(new CronINSOStatusUpdate());
      Test.StopTest();

      listINSO = [SELECT id, State__c, StartDate__c, EndDate__c FROM InstallationOrder__c where State__c = 'Ongoing'];
      System.assertEquals(1, listINSO.size(), 'Schedulable has not worked');       
    }

    

    @IsTest
    private static void testSchedulable() {        
        Test.startTest();
            System.schedule('Change Status INSO', '0 0 1 * * ?', new CronINSOStatusUpdate());
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'CronINSOStatusUpdate' AND JobType = 'BatchApex'];        
        System.assertEquals(1, batchJobs.size(), 'Unexpected number of batch jobs ran: ' + batchJobs);
        System.assertEquals('Queued', batchJobs[0].Status, 'Job planned with an unexpected status.');
    }
}