public class LeadRelatedListComponentController {
	@AuraEnabled 
    public static List<Lead> getComponentData(String objectId) {
        List<Lead> listLeadsRelated = new List<Lead>();
        String accountId = null;
        String email = null;
        
        if (objectId.startsWith('001')) { //Account
            Account acc = [Select Id, Name, PersonEmail, Business_Email__c from Account where Id =: objectId LIMIT 1];
            if (acc != null) {
                accountId = acc.Id;
                email = String.isBlank(acc.Business_Email__c) ? acc.PersonEmail : acc.Business_Email__c;
            }
        } else {
            Lead leadOrigin = [select Id, AccountId__c, Email from Lead where id = :objectId LIMIT 1];
            if (leadOrigin != null) {
                accountId = leadOrigin.AccountId__c;
                email = leadOrigin.Email;
            }
        }
        listLeadsRelated = [select Id, AccountId__c, Owner.Name, Status, AccountId__r.Name, CountryCode, Name, Phone, CreatedDate, LeadSource, LeadType__c, Email from Lead 
                            //where ((AccountId__c =: accountId and Email !=: email) or (AccountId__c !=: accountId and Email =: email))
                            where (
                                (AccountId__c =: accountId and AccountId__c <> '') or
                                ((AccountId__c =: '' and Email =: email))
                            )
                            //and IsConverted = false and Id !=: objectId];
                            and Id !=: objectId];

        return listLeadsRelated;
    } // getComponentData
}