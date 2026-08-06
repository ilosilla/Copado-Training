/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Data factories
* @description 	Opp Facade
*/
public class DataFactoryOppKitchen {
    
    public static OppKitchen__c createRecords () {
        if (!Test.isRunningTest()) {
            return null;
        }

        // Opportunity
        testUtils.enableTriggers();
        Opportunity opp = DataFactoryOpportunity.createRetailOpportunities(1, 1)[0];
    
        // Kitchen
        OppKitchen__c k = new OppKitchen__c();
        k.Opportunity__c = opp.Id;
        k.Stage__c = TestUtils.getPicklistOption(OppKitchen__c.Stage__c);
        k.ProductLine2__c = TestUtils.getPicklistOption(OppKitchen__c.ProductLine2__c);
        insert k;

        return k;
    }

}