public class Qualification_Controller{
	@AuraEnabled
    public static String createTask(String recordId, String taskDate, String taskSubject){
        // Log a Call
        Id ownerId = [SELECT OwnerId FROM Opportunity WHERE Id =: recordId Limit 1].OwnerId;
        
        System.debug('date: ' + DateTime.valueOfGmt(taskDate));
        
        Task call= new Task(ActivityDate = Date.valueOf(taskDate),
                            IsReminderSet = true,
                            ReminderDateTime = DateTime.valueOfGmt(taskDate),
                            Description = taskSubject,
                            OwnerId = ownerId,
                            Priority = 'Normal',
                            Status = 'Open',
                            Subject = taskSubject,
                            WhatId = recordId
                           );
        
        insert call;
        
        System.debug('call' + call.Id);
        
        return call.Id;
    }
    @AuraEnabled
    public static String getUserName(){
        return UserInfo.getName();
    }
    
}