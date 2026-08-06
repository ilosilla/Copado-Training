@isTest
public class Account_TestDataFactory {

    public static Account createCustomer() {
        Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Customer').getRecordTypeId();
        //Saludation / Title (SAP) mandatory to SAP Platform when the account is a personAccount (Customer RecordType)
		Account a = new Account(LastName = 'TestAcctCustomer1', FirstName= 'TestAcctCustomer1', RecordTypeId=RecordTypeIdAccount, Salutation = 'Dr.',
                                PersonEmail='Prueba' + Math.random() + '@test.com', PersonMailingCountryCode='GB', PersonMailingCity = 'Bristol', PersonMailingPostalCode = 'BS1 3NZ' );
		
        return a;
    }
    
    public static Account createBusinessAccount() {
        Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();
		Account a = new Account(Name = 'TestAcctBusinessAccount1', RecordTypeId=RecordTypeIdAccount, 
                                BillingCountryCode = 'GB', BillingCity = 'London', BillingPostalCode = 'BS1 3ND');
		
        return a;
    }
    
    public static Account createFabricator() {
        Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fabricator').getRecordTypeId();
		Account a = new Account(Name = 'TestAcctFabricatorAccount1', RecordTypeId=RecordTypeIdAccount, 
                                BillingCountryCode = 'GB', BillingCity = 'MANCHESTER', BillingPostalCode = 'BS1 3NC');
		
        return a;
    }
    
    public static Account createRetailer() {
        Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Third_party_Retailer_Reseller').getRecordTypeId();
		Account a = new Account(Name = 'TestAcctRetailerAccount1', RecordTypeId=RecordTypeIdAccount, 
                                BillingCountryCode = 'GB', BillingCity = 'Liverpool', BillingPostalCode = 'BS1 1DP');
		
        return a;
    }
	
    // Metodo para insertar accounts y saltearse las reglas de duplicados
    public static List<Database.SaveResult> insertAccounts(List<Account> accList){
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        
        List<Database.SaveResult> srList = Database.Insert(accList, dml);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted account. Account ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        return srList;
    }
    
}