@isTest
public with sharing class AccountTeamMember_TestDataFactory {
    public static List<AccountTeamMember> createAccountTeamMembers(Integer numAccTeamMembers, Id accountId){
        
        List<AccountTeamMember> accountTeamMembersList = new List<AccountTeamMember>();        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        List<User> userList = User_TestDataFactory.createUsers(numAccTeamMembers, new List<String>{'en_US', 'es_ES', 'en_US', 'es_ES', 'en_US'});
        
        insert userList;
        
        // TeamMemberRole picklist values
        List<String> pickListValuesList= new List<String>();        
        Schema.DescribeFieldResult fieldResult = AccountTeamMember.TeamMemberRole.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }
        
        Integer listSize = pickListValuesList.size();
        Integer index;
        
        for(Integer j=0; j<numAccTeamMembers; j++){
            
            if(j >= listSize){index = Math.mod(j, listSize);}
            else {index= j;}
            
            accountTeamMembersList.add(
                new AccountTeamMember(
                    AccountId = accountId,
                    //Percentage__c = 0.0, //preguntar
                    TeamMemberRole = pickListValuesList[index],
                    UserId = userList[j].Id
                )
            );
            
        }
        
        return accountTeamMembersList;
        
    }
    
    public static List<AccountTeamMember> createAccountTeamMembers(Integer records, Map<String, Object> userFieldsToAdd, Map<String, Object> accTeamMembersfieldsToAdd){
        
        List<AccountTeamMember> accountTeamMembersList = new List<AccountTeamMember>();        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        List<User> userList = User_TestDataFactory.createUsers(records, userFieldsToAdd);        
        insert userList;
        
        // TeamMemberRole picklist values
        List<String> pickListValuesList= new List<String>();        
        Schema.DescribeFieldResult fieldResult = AccountTeamMember.TeamMemberRole.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }
        
        Integer listSize = pickListValuesList.size();
        Integer index;
        
        for(Integer i=0; i<records; i++){
            
            if(i >= listSize){index = Math.mod(i, listSize);}
            else {index= i;}
            
            AccountTeamMember accTeamMember = new AccountTeamMember( TeamMemberRole = pickListValuesList[index],
                                                                            UserId = userList[i].Id);
            
            for(String fieldName: accTeamMembersfieldsToAdd.keySet()){                
                accTeamMember.put(fieldName, accTeamMembersfieldsToAdd.get(fieldName));                
            }
            
            accountTeamMembersList.add(accTeamMember);
            
        }
        
        return accountTeamMembersList;
        
    }
}