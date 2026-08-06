/**
* @author 		Ivan Losilla
* @date 		June 2022
* @group 		Accounts
* @description 	account selector class
*/

public class AccountsSelector extends zflib_SObjectSelector {

    public Schema.SObjectType getSObjectType(){
        return Account.sObjectType;
    }

    public List<Account> selectById(Set<Id> recordIds){
        return (List<Account>) selectSObjectsById(recordIds);
    }
    
    public Account selectById(Id recordId){
        List<Account> listAccounts = (List<Account>) selectSObjectsById(new Set<Id>{recordId});
        if (listAccounts.size() == 1) {
            return listAccounts[0];
        }
        return null;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {

            // Main info fields
            Account.Id,
            Account.OwnerId,
            Account.CurrencyIsoCode,
            Account.Name,
            Account.Fax,
            Account.Website,
            Account.Description,
            Account.Phone,
            Account.AccountNumber,
            Account.Site,
            Account.AccountSource,
            Account.Industry,
            Account.Ownership,
            Account.Sic,
            Account.SicDesc,
            
            //Classification fields
            Account.Type,
            Account.IsPersonAccount,
            Account.IsCustomerPortal,
            Account.IsPartner,
            Account.IsDeleted,
            Account.Account_Classification__c,
            Account.Account_Subclassification__c,
            Account.Rating,
            
            // Other info fields
            Account.VAT_Number__c,
            Account.VAT_Number_2__c,
            Account.Other_Phone__c,
            Account.AddressesSynced__c,

            //DVS Fields
            Account.DVSAcceptedBy__c,
            Account.DVSAcceptedDate__c,
            Account.DVSAction__c,
            Account.DVSHasError__c,
            Account.DVSLongError__c,
            
            // Reference fields
            Account.ParentId,

            // Admin fields
            Account.RecordTypeId,
            Account.CreatedById,
            Account.CreatedDate,
            Account.LastModifiedById,
            Account.LastActivityDate,
            Account.LastModifiedDate,
            Account.LastViewedDate,
            // Account.ActivityMetricId,
            Account.Conversion_Date__c,
            Account.ConversionDate__c,
            Account.Is_Deleted__c,
            Account.Is_Locked__c,
            Account.Last_Activity_Date__c,
            Account.LastEventDateTime__c,
            Account.LastEmailDateTime__c,
            Account.LastOpportunityDateTime__c,
            Account.LastEventDateTime__c,
            Account.LastOrderDateTime__c,
            Account.LastQuoteDateTime__c,
            Account.Dirty__c,

            // External keys
            Account.SAP_Id__c,
            Account.SAP_id_formule__c,
            
            // Counter fields
            Account.NumberOfEmployees,
            Account.Number_of_Contacts__c,
            Account.Number_Of_Projects__c,
            
            // Private Account Fields
            Account.Salutation,
            Account.FirstName,
            Account.LastName,
            Account.PersonMailingAddress,
            Account.PersonMailingCity,
            Account.PersonMailingCountry,
            Account.PersonMailingCountryCode,
            Account.PersonMailingLatitude,
            Account.PersonMailingLongitude,
            Account.PersonMailingPostalCode,
            Account.PersonMailingState,
            Account.PersonMailingStateCode,
            Account.PersonMailingStreet,
            Account.PersonMobilePhone,
            Account.PersonOtherPhone,
            Account.PersonTitle,
            Account.PersonBirthdate,
            Account.PersonEmail,
            Account.PersonHasOptedOutOfEmail,
            Account.PersonDoNotCall,
            Account.PersonIndividualId,
            Account.PersonLeadSource,
            Account.PersonOtherAddress,
            Account.PersonContactId,

            // Trade Account Fields
            Account.BillingAddress,
            Account.BillingCity,
            Account.BillingCountry,
            Account.BillingCountryCode,
            Account.BillingLatitude,
            Account.BillingLongitude,
            Account.BillingPostalCode,
            Account.BillingState,
            Account.BillingStateCode,
            Account.BillingStreet,
            Account.Business_Email__c,

            // Shipping Fields
            Account.ShippingAddress,
            Account.ShippingCity,
            Account.ShippingCountry,
            Account.ShippingCountryCode,
            Account.ShippingLatitude,
            Account.ShippingLongitude,
            Account.ShippingPostalCode,
            Account.ShippingState,
            Account.ShippingStateCode,
            Account.ShippingStreet
        };
    }
}