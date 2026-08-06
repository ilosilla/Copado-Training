/**
* @author Ivan Losilla
* @date July 2022
* @group Pricebooks
* @description Class that implements methods related with Pricebooks
*/
public class PricebookCommons {
    @future
    public static void setOpportunityPricebookUpdate(Id opportunityId) {
        try {
            List<Opportunity> opps = new OpportunitiesSelector().selectByIdWithOwner(new Set<Id>{opportunityId});
            if (opps.size() == 0) {
                AbstractPricebookAssignator pricebookAssign = PricebookAssignator.getInstance(opps[0].Owner.Execution_Context__c);
                pricebookAssign.setUser(opps[0].OwnerId);
                pricebookAssign.setAccount(opps[0].AccountId);
                Pricebook2 pbAssigned = pricebookAssign.getPricebook();

                if (pbAssigned != null) {
                    opps[0].Pricebook2Id = pbAssigned.Id;
                    update opps[0];
                }
            }
        } catch (ContextException ex) {
           LoggerCommons.LogException('PRICEBOOKOPPORTUNITY', '', ex);
        }
    }

}