/**
 * @author Ramón Prades
 * @date June 2020
 *
 * @group Accounts
 * @group-content ../../ApexDocContent/Accounts.htm
 *
 * @description Class to create test accounts
 */
@SuppressWarnings('PMD.ExcessiveParameterList')
public class DataFactoryAccount {
    
    public static Boolean autoInsert = true;    
    
  	/**
   	 * @description 	Creates test person accounts
   	 * @param theNumber	The number of person ccounts to create
   	 * @return			The list of person accounts created
     */    
	public static List<Account> createPersonAccounts(Integer theNumber) {
 		Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Customer').getRecordTypeId();		        
        List<Account> accounts = new List<Account>();
		String random = TestUtils.generateRandomString(6);
        if(Test.isRunningTest()){
            for (Integer i = 0; i<theNumber; i++) {
                String postCode = 'LS' + i + ' 3NZ';
                if ( i > 9) {
                    postCode = 'LS9 3NZ';
                }
				Account a = new Account(LastName = 'Smith ' + random + ' #' +  i, FirstName = 'John', RecordTypeId = rtId, Salutation = 'Dr.',
								PersonEmail='test' + random + i + '@test.c0m',
                                PersonMailingCountryCode='GB', PersonMailingCity = 'Bristol', PersonMailingPostalCode = postCode );
                accounts.add(a);
            }
            if (autoInsert) {
         		insert accounts;
            }
        } 
        return accounts;                        
    } // createPersonAccounts

    public static List<Account> createAccounts(Integer theNumber) {
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();		        
        return createAccounts(rtId, theNumber);
    }

    public static List<Account> createAccounts(Id RecordTypeId, Integer theNumber) {
        String random = TestUtils.generateRandomString(12);
        List<Account> accounts = new List<Account>();
        if(Test.isRunningTest()){
            for (Integer i = 0; i<theNumber; i++) {
                String postCode = 'AB' + i + ' 3EH';
                if ( i > 9) {
                    postCode = 'AB9 3EH';
                }

                Account a = new Account(Name = 'T ' + random + ' #' + i, RecordTypeId=RecordTypeId, 
                Business_Email__c='test' + random + i + '@test.c0m',
                    BillingCountryCode = 'GB', BillingCity = 'London', BillingPostalCode = postCode);                
                accounts.add(a);
            }
            if (autoInsert) {
         		insert accounts;
            }
        } 
        return accounts;                        
    } // createAccounts
    

    /**
   	 * @description 	Creates test person accounts
   	 * @param           theNumber	The number of person accounts to create
   	 * @return			The list of person accounts created
     */    
	public static List<Account> createBusinessAccounts(Integer theNumber) {
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();		        
       List<Account> accounts = new List<Account>();
       if(Test.isRunningTest() || SystemUtils.getOnSandbox()){
           for (Integer i = 0; i<theNumber; i++) {
               Account a = new Account(Name='Trade Smith #' + i, RecordTypeId = rtId,
                                Account_Classification__c='Architectural firm',
                                Business_Email__c='test' + i + '@test.c0m',
                                BillingCountryCode='GB', BillingCity = 'Bristol', BillingPostalCode = 'BS1 3NZ' );
               accounts.add(a);
           }
       } 
       if (autoInsert) {
           insert accounts;
       }        
       return accounts;                        
   } // createBusinessAccounts

   /**
    * @description      Creates sales relationships for the given account. 
    */
    public static Sales_Relationship__c createSalesRelation(Account account, String org, String channel, String office ) {
        Sales_Relationship__c rel = new Sales_Relationship__c(
            Account_Org__c = account.Id,
            Sales_Org__c = org,
            Distribution_Channel__c = channel,
            Sales_Office__c	= office
        );
        if (autoInsert) {
            insert rel;
        }
        return rel;
    }
    

} // class