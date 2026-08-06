/**
* @author Ivan Losilla
* @date November 2024
*
* @group Others 
* @description Class to manage everything about PopupActions LWC.
*/
public class PopupActionsService {
    @AuraEnabled (cacheable=true)
    public static User currentUserData() {
        return new UsersSelector().selectById(UserInfo.getUserId());
    }

    @AuraEnabled (cacheable=false)
    public static List<Account> getNoManagedAccounts(Integer numOfRecords) {
        List<RecordType> rcTypes = [SELECT Id FROM RecordType WHERE (Name = 'Fabricator' OR Name = 'Third party Retailer / Reseller' OR Name = 'Trade and Specificators')];
        List<Id> rcTypesIds = new List<Id>{rcTypes[0].Id, rcTypes[1].Id, rcTypes[2].Id};

        List<Account> listAccounts = [SELECT ID, Name, VAT_Number__c, VAT_Number_2__c, BillingStreet, BillingPostalCode, BillingCity, BillingCountry, BillingCountryCode,
                                    DvsLongError__c, DvsHasError__c, Last_Activity_Date__c,Activity_Level__c,Sap_id__c,
                                    DvsAcceptedBy__c, DvsAction__c, Account_Classification__c
        FROM Account
        WHERE DvsAction__c = null
        AND BillingCountryCode = 'FR'
        AND Account_Status__c = 'Active'
        AND RecordTypeId IN :rcTypesIds
        AND createddate < LAST_N_DAYS:1
        AND OwnerId =: Userinfo.getUserId()
        ORDER BY Activity_Level__c DESC
        LIMIT : numOfRecords];

        return listAccounts;
    }
}