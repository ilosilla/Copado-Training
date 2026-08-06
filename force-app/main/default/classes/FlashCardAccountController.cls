public class FlashCardAccountController {

     @AuraEnabled 
    public static Account getAccount(String accountId) {
        String fields = 'Id, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingPostalCode, PersonMailingCountry, '
            		+ 'PersonMailingCountryCode, PersonEmail, Name, '
					+ 'Phone, BillingStreet, BillingCity, BillingPostalCode, BillingCountryCode, Business_Email__c';
        String sql = 'select ' + fields + ' from Account where Id = :accountId';
        Account account = null;
		List<Account> accounts = Database.query(sql);
        if (accounts.size() > 0) {
            account = accounts[0];
        }
        return account;
    } // getAcccount
}