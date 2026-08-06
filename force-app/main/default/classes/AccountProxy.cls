/**
* @author 		Ramón Prades
* @date 		April 2021
* @group 		Accounts
* @description 	Proxy class to provide a common interface to account and person account
*/
public class AccountProxy {

    @AuraEnabled public Account account { get; private set; }
    @AuraEnabled public Id id { get; private set; }
    @AuraEnabled public Boolean isPersonAccount { get; private set; }
    @AuraEnabled public String name;
    @AuraEnabled public String street;
    @AuraEnabled public String city;
    @AuraEnabled public string stateCode;
    @AuraEnabled public string state;
    @AuraEnabled public string countryCode;    
    @AuraEnabled public String country;
    @AuraEnabled public string postalCode;
    @AuraEnabled public string email;
    @AuraEnabled public string phone;

    public AccountProxy(String Id) {
        this.read(Id);
    }

    private void read(String Id) {
        this.account = [select
            Account_Classification__c, Account_Status__c, BillingCity, BillingCountry, BillingCountryCode, BillingPostalCode,
            BillingState, BillingStateCode, BillingStreet, Business_Email__c, CreatedDate, Id, IsDeleted, IsPersonAccount,
            Language__c, Name, OwnerId, Potential__c, PersonEmail, PersonMailingStreet, PersonMailingCity, PersonMailingCountryCode,
            PersonMailingCountry,  PersonMailingPostalCode, PersonMobilePhone, PersonMailingStateCode, PersonMailingState, Phone,  Salutation, FirstName, LastName,
            RecordTypeId, SAP_Id__c
        from Account where Id = :Id limit 1];
        if (this.account.isPersonAccount) {
            assignPersonAccount();
        } else {
            assignAccount();
        }
    } // read

    private void assignAccount() {
        this.id = this.account.Id;
        this.city = this.account.BillingCity;
        this.country = this.account.BillingCountry;
        this.countryCode = this.account.BillingCountryCode;
        this.postalCode = this.account.BillingPostalCode;
        this.state = this.account.BillingState;
        this.stateCode = this.account.BillingStateCode;
        this.street = this.account.BillingStreet;
        this.email = this.account.Business_Email__c;
        this.isPersonAccount = this.account.IsPersonAccount;
        this.name = this.account.Name;
        this.phone = this.account.Phone;
    } // assignAccount

    private void assignPersonAccount() {
        this.id = this.account.Id;
        this.city = this.account.PersonMailingCity;
        this.country = this.account.PersonMailingCountry;
        this.countryCode = this.account.PersonMailingCountryCode;
        this.postalCode = this.account.PersonMailingPostalCode;
        this.state = this.account.PersonMailingState;
        this.stateCode = this.account.PersonMailingStateCode;
        this.street = this.account.PersonMailingStreet;
        this.email = this.account.PersonEmail;
        this.isPersonAccount = this.account.IsPersonAccount;
        this.name = this.account.Name;
        this.phone = this.account.PersonMobilePhone;
    } // assignAccount

}