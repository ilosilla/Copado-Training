@isTest
public class Sales_RelationShip_TestDataFactory {

    public static Sales_RelationShip__c createSalesRelationship( Account acc) {
		
        //Picklist Dependencies!! Azurceramique	203	Sales Office: Aubagne: 3015 Big Projects: 30
        Sales_RelationShip__c s = new Sales_RelationShip__c (Name = 'TestSales_RelationShip', Account_Org__c = acc.Id, Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE,
                                                            Sales_Office__c = '3015', Distribution_Channel__c = '30');
	        
        return s;
    }
    
    public static Sales_RelationShip__c createSalesRelWithPicklist( Account acc, String salesOrg, String salesOffice, String distChannel) {
		
        //Picklist Dependencies!! Azurceramique	203	Sales Office: Aubagne: 3015 Big Projects: 30
        Sales_RelationShip__c s = new Sales_RelationShip__c (Name = 'TestSales_Rel [' + salesOrg + ', ' + distChannel + ']', Account_Org__c = acc.Id, Sales_Org__c = salesOrg,
                                                            Sales_Office__c = salesOffice, Distribution_Channel__c = distChannel);
	        
        return s;
    }
    
    public static Sales_RelationShip__c createSales_RelationShip() {
        Account acc = new Account();
        acc.Name='For SalesRelationShip 1';
        acc.BillingCountryCode = null;
		insert acc;
		
        //Picklist Dependencies!! Azurceramique	203	Sales Office: Aubagne: 3015 Big Projects: 30
        Sales_RelationShip__c s = new Sales_RelationShip__c (Name = 'TestSales_RelationShip', Account_Org__c = acc.Id, Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE,
                                                            Sales_Office__c = '3015', Distribution_Channel__c = '30');
	        
        return s;
    }
    
    public static Sales_RelationShip__c createSales_RelationShipWithoutAccount() {

		
        //Picklist Dependencies!! Azurceramique	203	Sales Office: Aubagne: 3015 Big Projects: 30
        Sales_RelationShip__c s = new Sales_RelationShip__c (Name = 'TestSales_RelationShip', Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE,
                                                            Sales_Office__c = '3015', Distribution_Channel__c = '30', Custom_Id__c= null);
	        
        return s;
    }
}