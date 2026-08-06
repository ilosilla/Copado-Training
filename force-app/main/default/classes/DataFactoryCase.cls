/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		DataFactories   
* @description 	Case data factory
*/
public class DataFactoryCase {

    public static Boolean autoInsert = true;    

    public static Case[] createCollections(Integer count) {
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        Case[] cases= new List<Case>();
		//String random = TestUtils.generateRandomString(6);
        if(Test.isRunningTest()){
            for (Integer i = 0; i<count; i++) {
				Case c = new Case(
                    SAPInvoice__c = '9215100036',
                    AccountId = acc.Id,
                    RecordTypeId = RecordTypeLibrary.Case_SAPInvoice);
                cases.add(c);
            }
            if (autoInsert) {
         		insert cases;
            }
        } 
        return cases;                        
    }

    public static Case[] createClaims(Integer count) {
        Integer random3 = Math.round(Math.random() * 900) + 100; // 100..999
        String invoice = '9215100' + String.valueOf(random3);
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        acc.SAP_Id__c = String.valueOf(random3);
        update acc;
        Case[] cases= new List<Case>();
        if(Test.isRunningTest()){
            for (Integer i = 0; i<count; i++) {
				Case c = new Case(
                    SAPInvoice__c = invoice,
                    SAPInvoiceLine__c = 10,
                    AccountId = acc.Id,
                    RecordTypeId = RecordTypeLibrary.Case_SAPClaim,
                    SalesOrg__c = '502',
                    DistributionChannel__c = '60'
                    );
                cases.add(c);
            }
            if (autoInsert) {
         		insert cases;
            }
        } 
        return cases;                        
    }



} // class