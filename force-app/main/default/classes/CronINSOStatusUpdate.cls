global class CronINSOStatusUpdate implements Database.Batchable<sObject>, Schedulable {
  global Database.QueryLocator start(Database.BatchableContext BC){
    String query = 'SELECT Id, StartDate__c,EndDate__c FROM InstallationOrder__c WHERE StartDate__c <= TODAY AND EndDate__c >= TODAY and State__c <> \'Ongoing\'';
    return Database.getQueryLocator(query);
  }

 global void execute(Database.BatchableContext BC, List<InstallationOrder__c>scope){
    for(InstallationOrder__c a : scope){
        a.State__c = 'Ongoing';        
    }
    update scope;
  }

  global void finish(Database.BatchableContext BC){
  }

  global void execute(SchedulableContext sc) {
    try {
      CronINSOStatusUpdate b = new CronINSOStatusUpdate ();
      database.executebatch(b);
    } catch (Exception e) {
      SystemUtils.debugWarning('CRON', 'UPDATE INSO STATUS', e);
    }
  }
}