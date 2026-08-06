public with sharing class TaskUtils {
    public static List<Task> getData(Set<Id> taskIds) {
        String objectName = 'Task';
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
        String queryString  = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + ' WHERE Id IN :taskIds';

        return Database.query(queryString);
    }

    public static Task getData(Id taskId) {
        List<Task> listTasks = getData(new Set<Id>{taskId});

        if (listTasks.size() == 1) {
            return listTasks[0];
        }
        return null;
    }
    
    public static Boolean isCall(Task elem) {
        return elem.TaskSubtype == 'Call';
    }
    
    public static Boolean isEmail(Task elem) {
        return elem.TaskSubtype == 'Email';
    }
    
    public static Boolean hasLeadRelated(Task elem) {
        Schema.SObjectType leadType = Schema.Lead.SObjectType;
        return elem.WhoId != null && elem.WhoId.getSObjectType() == leadType;
    }
    
    public static Boolean hasAccountRelated(Task elem) {
        Schema.SObjectType accountType = Schema.Account.SObjectType;
        return elem.WhatId != null && elem.WhatId.getSObjectType() == accountType;
    }
    
    public static Boolean hasOpportunityRelated(Task elem) {
        Schema.SObjectType opportunityType = Schema.Opportunity.SObjectType;
        return elem.WhatId != null && elem.WhatId.getSObjectType() == opportunityType;
    }
}