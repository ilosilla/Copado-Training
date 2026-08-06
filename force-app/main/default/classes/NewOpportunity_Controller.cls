public class NewOpportunity_Controller {
    
    @AuraEnabled
    public static String manageMissedCalls(String recordId, Integer numberOfCalls){
        
        Task call, tomorrowTask;
        Opportunity opportunity = [SELECT Account.PersonEmail, OwnerId FROM Opportunity WHERE Id = :recordId];
        Integer numberOfDays = 3;
        
        try{
            Argumentario_Reminder_Days__c reminderDays = Argumentario_Reminder_Days__c.getInstance('Log a Call');
            numberOfDays = (Integer) reminderDays.NUM_Number_of_days__c;
        } catch(Exception ex){
            System.debug('Error retrieving the custom setting: ' + ex.getMessage());
        }
            
        // To avoid Internal Error
        numberOfCalls = Integer.valueOf(numberOfCalls);
        
        switch on numberOfCalls{
            
            when 1{
            
                // Log a Call
                call = new Task(ActivityDate = Date.today(),
                                IsReminderSet = false,
                                Priority = 'Normal',
                                Status = 'Completed',
                                Subject = 'Llamada perdida',
                                WhatId = recordId
                                );
                
                insert call;
                System.debug('call' + call.Id);
                // Task for the next day
                tomorrowTask = new Task(ActivityDate = Date.today().addDays(numberOfDays),
                                        Description = 'Volver a llamar a cliente',
                                        IsReminderSet = true,
                                        OwnerId = opportunity.OwnerId,
                                     	Priority = 'Normal',
                                     	ReminderDateTime = DateTime.now().addDays(numberOfDays),
                                     	Status = 'Open',
                                     	Subject = 'Volver a llamar a cliente para consultar satisfacción muestras',
                                     	WhatId = recordId
                                     	);
                
                insert tomorrowTask;
                System.debug('tomorrowTask' + tomorrowTask.Id);
                return tomorrowTask.Id;
            
            }
            
            when 2{
            
            	// Second Missed Call
                call = new Task(ActivityDate = Date.today(),
                                IsReminderSet = false,
                                Priority = 'Normal',
                                Status = 'Completed',
                                Subject = 'Segunda llamada perdida',
                                WhatId = recordId
                                );
                
                insert call;
                System.debug('call2' + call.Id);
                
                // Just for returning purposes
                string result = EmailFlow.execute(new List<String>{opportunity.Account.PersonEmail})[0];
				if(result == 'Success'){
                	return result;//opportunity.Account.PersonEmail;
                } else {
                    return result;
                }
                
                
            }
            
            when else{
                
                return 'else';
                
            }
            
        }
        
    }

}