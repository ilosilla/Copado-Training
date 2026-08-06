/**
* @author 		Ramón Prades
* @date 		July 2022
* @group 		Data Factotries
* @description 	Creates opportunities with Custom Projects attached
*/
public without sharing class DataFactoryOppCustomProjects {

    public static Boolean autoInsert = true;

    public static List<OppCustomProject__c> createRecords(Integer numRecords) {
        List<OppCustomProject__c> projects = new List<OppCustomProject__c>();
        Opportunity[] opps = DataFactoryOpportunity.createRetailOpportunities(1, numRecords);
        for  (Opportunity opp: opps ) {
            projects.add(createCustomProject(opp));
        }
        if (autoInsert && Test.isRunningTest()) {
            insert projects;
        }
        return projects;
    }

    private static OppCustomProject__c createCustomProject(Opportunity opp) {

        OppCustomProject__c cp = new OppCustomProject__c();
        cp.Opportunity__c = opp.Id;
        cp.ProjectType__c = 'KRION';
        cp.ProductManager__c = UserInfo.getUserId();
        cp.DeliveryDate__c = System.today();
        
        return cp;
        
    }

}