public class OppContactRolesErrorComponentController {
    @AuraEnabled
    public static List<OpportunityContactRole> returnOppContactRolesErrors(String recordId){
        List<OpportunityContactRole> returnList = [SELECT Id, ErrorMessage__c, Contact.Name
                                                  FROM OpportunityContactRole 
                                                  WHERE OpportunityId =: recordId AND SapStatus__c = 'Error'];
        return returnList;
    }
    
    @AuraEnabled
    public static String retry(String recordId){
        String result = '';
        
        try{
            OpportunityContactRole oppContactRole = [SELECT Id, SapStatus__c, OpportunityId FROM OpportunityContactRole WHERE Id =: recordId];
            Update oppContactRole;
        } catch(Exception ex){
            result = ex.getMessage();
        }
        return result;
    }
}