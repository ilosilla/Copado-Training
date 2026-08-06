/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Tasks
* @description 	tasks selector class
*/
public class TasksSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Task.sObjectType;
    }

    public List<Task> selectById(Set<Id> recordIds){
        return (List<Task>) selectSObjectsById(recordIds);
    }

    public Task selectById(Id recordId){
        List<Task> listTasks = (List<Task>) selectSObjectsById(new Set<Id>{recordId});
        if (listTasks.size() == 1) {
            return listTasks[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            Task.Id,
            Task.CurrencyIsoCode,
            Task.OwnerId,
            Task.Description,
            Task.Subject,
            
            //Classification fields
            Task.Status,
            
            // Other info fields
            Task.WhoId,
            Task.WhatId,
            Task.AccountId,

            // Admin fields
            Task.CreatedById,
            Task.CreatedDate,
            Task.ActivityDate,
            Task.LastModifiedById
        };
    }
}