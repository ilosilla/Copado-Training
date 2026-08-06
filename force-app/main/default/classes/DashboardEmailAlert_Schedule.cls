global class DashboardEmailAlert_Schedule implements Schedulable{ 
    global void execute(SchedulableContext sc) { 
        DashboardEmailAlert_Batch obj = new DashboardEmailAlert_Batch();
        Id batchJobId = DataBase.executeBatch(obj);
        System.debug('batchJobId: ' + batchJobId);
    }
}