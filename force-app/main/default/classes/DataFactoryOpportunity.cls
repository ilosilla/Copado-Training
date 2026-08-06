/**
 * @author Ramón Prades
 * @date July 2020
 *
 * @group Opportunities
 * @group-content ../../ApexDocContent/Opportunities.htm
 *
 * @description Class to create test opportunities
 */
public class DataFactoryOpportunity {

    public static boolean autoInsert = true;

    /**
   	 * @description 		Creates retail opportunities
   	 * @param accounts		List of accounts for the opportunities
	 * @param theNumber		The number of opportunities to create for each account in the list
   	 * @return				The list of person accounts created
     */    
	public static List<Opportunity> createRetailOpportunities(Integer numAccounts, Integer numOpportunities) {
        List<Account> acc = DataFactoryAccount.createPersonAccounts(numAccounts);        
        return createRetailOpportunities(acc, numOpportunities);
    } // createRetailOpportunities

    
    /**
   	 * @description 		Creates retail opportunities
   	 * @param accounts		List of accounts for the opportunities
	 * @param theNumber		The number of opportunities to create for each account in the list
   	 * @return				The list of person accounts created
     */    
	public static List<Opportunity> createRetailOpportunities(List<account> accounts, Integer theNumber) {
		Id oppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_retail').getRecordTypeId();
        List<Opportunity> opportunities = new List<Opportunity>();
        if(Test.isRunningTest()) {  
            Integer i = 0;
            for (Account acc : accounts) {                
            	for (Integer j = 0; j<theNumber; j++) {
        			Opportunity o = new Opportunity(Name= 'Test Retail Opportunity [' + i + ',' + j +']', 
                                            RecordTypeId = oppId, 
                                            AccountId= acc.Id, 
                                            StageName = 'New', 
                                            roomTypeBathroom__c = 1,
                                            CloseDate= Date.today().addDays(30), 
                                            Opportunity_Classification__c = 'Residential (Retail)');  
                    opportunities.add(o);
            	} // for nmero
                i++;
            } // for accounts
            if (autoInsert) {
                insert opportunities;
            }
        } // if test
        return opportunities;
    } // createRetailOpportunities

    /**
   	 * @description 		Creates trade opportunities
   	 * @param accounts		List of accounts for the opportunities
	 * @param theNumber		The number of opportunities to create for each account in the list
   	 * @return				The list of person accounts created
     */    
	public static List<Opportunity> createTradeOpportunities(Integer numAccounts, Integer numOpportunities) {
        List<Account> acc = DataFactoryAccount.createBusinessAccounts(numAccounts);        
        return createTradeOpportunities(acc, numOpportunities);
    } // createTradeOpportunities

    
    /**
   	 * @description 		Creates trade opportunities
   	 * @param accounts		List of accounts for the opportunities
	 * @param theNumber		The number of opportunities to create for each account in the list
   	 * @return				The list of person accounts created
     */    
	public static List<Opportunity> createTradeOpportunities(List<account> accounts, Integer theNumber) {
		Id oppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_trade').getRecordTypeId();
        List<Opportunity> opportunities = new List<Opportunity>();
        if(Test.isRunningTest()) {  
            Integer i = 0;
            for (Account acc : accounts) {                
            	for (Integer j = 0; j<theNumber; j++) {
        			Opportunity o = new Opportunity(Name= 'Test Retail Opportunity [' + i + ',' + j +']', 
                                            RecordTypeId = oppId, 
                                            AccountId= acc.Id, 
                                            StageName = 'New', 
                                            CloseDate= Date.today().addDays(30), 
                                            Opportunity_Classification__c = 'Airport');  
                    opportunities.add(o);
            	} // for nmero
                i++;
            } // for accounts
            if (autoInsert) {
                insert opportunities;
            }
        } // if test
        return opportunities;
    } // createTradeOpportunities    
}