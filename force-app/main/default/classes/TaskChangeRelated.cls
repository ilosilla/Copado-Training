/**
* @author Ivan Losilla
* @date November 2021
* @group Trigger
* @description Manage the changes to do on the related objects of a task, when it changes
*/
public class TaskChangeRelated {

    /**
    * @description Manage the changes to do on the Accounts related to the tasks.
    * @param tasks
    */
    public static void changeAccounts(List<Task> tasks, String typeChange) {
        Set<Id> accountsIds = new Set<Id>();
        
        for (Task elem : tasks) {
            accountsIds.add(elem.WhatId);
            accountsIds.add(elem.AccountId);
        }
    }
    
    /**
    * @description Manage the changes to do on the Opportunities related to the tasks.
    * @param tasks
    */
    public static void changeOpportunities(List<Task> tasks, String typeChange) {
        Set<Id> opportunitiesIds = new Set<Id>();

        for (Task elem : tasks) {
            opportunitiesIds.add(elem.WhatId);
            opportunitiesIds.add(elem.AccountId);
        }
    }
    
    /**
    * @description Manage the changes to do on the Leads related to the tasks.
    * @param tasks
    */
    public static void changeLeads(List<Task> tasks, String typeChange) {
        List<Lead> leadsList = new List<Lead>();
        List<Lead> leadsToUpdate = new List<Lead>();
        Map<Id,Lead> leadsMap = new Map<Id,Lead>();
        Set<Id> changedLeadsMap = new Set<Id>();
        Set<Id> leadsIds = new Set<Id>();

        try {
            for (Task elem : tasks) {
                leadsIds.add(elem.WhoId);
            }
            
            leadsList = LeadUtil.getData(leadsIds);
            for (Lead elem : leadsList) {
                leadsMap.put(elem.Id, elem);
            }
            
            if (leadsMap.size() > 0) {
                switch on typeChange {
                    when  'INSERT'{
                        leadsUSWebRequestChangeStatus(tasks, leadsMap, changedLeadsMap);
                    }
                }
                
                for (Id elem : changedLeadsMap) {
                    leadsToUpdate.add(leadsMap.get(elem));
                }
                update leadsToUpdate;
            }
        } catch (ContextException ex) {
            SystemUtils.debugWarning('LEADSNOTUPDATED', 'LEADS NOT UPDATED AFTER TASK', ex);
        }
        
    }
    
    
    /**
    * @description Manage the change of the Status on the US Web Request Leads.
    * @param tasks List of tasks, to check wich one is a US Web Request
    * @param leadsMap Map of the Leads related to tasks
    * @param changedLeadsIds Set of the Leads changed, so they have to be updated
    */
    private static void leadsUSWebRequestChangeStatus(List<Task> tasks, Map<Id, Lead> leadsMap, Set<Id> changedLeadsIds) {
        Lead auxLead = new Lead();
        
        try {
            for (Task elem : tasks){
                auxLead = leadsMap.get(elem.WhoId);
                if (LeadUtil.isUSWebRequest(auxLead) && (TaskUtils.isEmail(elem) || TaskUtils.isCall(elem))) {
                   
                    if (TaskUtils.isEmail(elem) && auxLead.Status == 'Not contacted') {
                        auxLead.Status = 'Contacted via Email';
                        leadsMap.put(auxLead.Id, auxLead);
                        changedLeadsIds.add(auxLead.Id);
                    }
                    if (TaskUtils.isCall(elem) && (auxLead.Status == 'Not contacted' || auxLead.Status == 'Contacted via Email')) {
                        auxLead.Status = 'Contacted via Phone';
                        leadsMap.put(auxLead.Id, auxLead);
                        changedLeadsIds.add(auxLead.Id);
                    }
                }
            }   
        } catch (ContextException ex) {
            SystemUtils.debugWarning('LEADNOTUPDATED', 'LEAD STATUS NOT UPDATED', ex);
        }
    }
}