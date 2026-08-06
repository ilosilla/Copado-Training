/**
* @author           Ivan Losilla
* @date             September 2024
* @group            Accounts
* @description      Class related with syncronization with SAP.
*/
public class AccountSyncEvaluator {
    public static Boolean syncToSAP(Account newValues, Account oldValues) {
        Boolean result = false;

        // Fields that are synced with SAP
        List<String> personAccountSapFields = new List<String>{
            'Salutation', 
            'FirstName',
            'LastName',
            'PersonMailingStreet', 
            'PersonMailingCountryCode',
            'PersonMailingPostalCode',
            'PersonMailingStateCode',
            'PersonMailingCity',
            'RecordTypeId',
            'VAT_Number__c',
            'VAT_Number_2__c',
            'PersonEmail',
            'Phone'
        };

        List<String> businessAccountSapFields = new List<String>{
            'Name', 
            'BillingStreet', 
            'BillingCountryCode',
            'BillingPostalCode',
            'BillingStateCode',
            'BillingCity',
            'RecordTypeId',
            'VAT_Number__c',
            'VAT_Number_2__c',
            'Business_Email__c',
            'Phone'
        };
        
        // Check if any of the fields has changed
        
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Customer').getRecordTypeId();

        // Check if it's a Private Account because the fields are different
        if (newValues.recordTypeId == rtId) {
            for (String field : personAccountSapFields) {
                if (oldValues.get(field) != newValues.get(field)) {
                    result = true;
                    break;
                }
            }

        } else {
            for (String field : businessAccountSapFields) {
                if (oldValues.get(field) != newValues.get(field)) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }
}