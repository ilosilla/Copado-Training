@isTest
public class OpportunityTeamMember_TestDataFactory{
    
    public static List<OpportunityTeamMember> createOpportunityTeamMembers(Integer numOppTeamMembers, Id opportunityId){
        
        List<OpportunityTeamMember> opportunityTeamMembersList = new List<OpportunityTeamMember>();        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        List<User> userList = User_TestDataFactory.createUsers(numOppTeamMembers, new List<String>{'en_US', 'es_ES', 'en_US', 'es_ES', 'en_US'});
        //List<User> userList = User_TestDataFactory.createUsers(numOppTeamMembers, new Map<String, Object>{}});
        
        insert userList;
        
        // TeamMemberRole picklist values
        List<String> pickListValuesList= new List<String>();        
        Schema.DescribeFieldResult fieldResult = OpportunityTeamMember.TeamMemberRole.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }
        
        Integer listSize = pickListValuesList.size();
        Integer index;
        
        for(Integer j=0; j<numOppTeamMembers; j++){
            
            if(j >= listSize){index = Math.mod(j, listSize);}
            else {index= j;}
            
            opportunityTeamMembersList.add(
                new OpportunityTeamMember(
                    OpportunityAccessLevel = 'All',
                    OpportunityId = opportunityId,
                    //Percentage__c = 0.0, //preguntar
                    TeamMemberRole = pickListValuesList[index],
                    UserId = userList[j].Id
                )
            );
            
        }
        
        return opportunityTeamMembersList;
        
    }
    
    public static List<OpportunityTeamMember> createOpportunityTeamMembers(Integer records, Map<String, Object> userFieldsToAdd, Map<String, Object> oppTeamMembersfieldsToAdd){
        
        List<OpportunityTeamMember> opportunityTeamMembersList = new List<OpportunityTeamMember>();        
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        List<User> userList = User_TestDataFactory.createUsers(records, userFieldsToAdd);        
        insert userList;
        
        // TeamMemberRole picklist values
        List<String> pickListValuesList= new List<String>();        
        Schema.DescribeFieldResult fieldResult = OpportunityTeamMember.TeamMemberRole.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }
        
        Integer listSize = pickListValuesList.size();
        Integer index;
        
        for(Integer i=0; i<records; i++){
            
            if(i >= listSize){index = Math.mod(i, listSize);}
            else {index= i;}
            
            OpportunityTeamMember oppTeamMember = new OpportunityTeamMember(OpportunityAccessLevel = 'All',
                                                                            TeamMemberRole = pickListValuesList[index],
                                                                            UserId = userList[i].Id);
            
            for(String fieldName: oppTeamMembersfieldsToAdd.keySet()){                
                oppTeamMember.put(fieldName, oppTeamMembersfieldsToAdd.get(fieldName));                
            }
            
            opportunityTeamMembersList.add(oppTeamMember);
            
        }
        
        return opportunityTeamMembersList;
        
    }
    
}