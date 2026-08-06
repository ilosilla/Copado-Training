/**
* @author Ivan Losilla
* @date February 2022
* @group Triggers
* @description Manages the Opportunity Line Item Trigger
*/
public class OpportunityLineItemTriggerHandler extends BaseTriggerHandler {
    
    public override void beforeDelete(List<SObject> oldItems) {
        canbeDeleted((List<OpportunityLineItem>) oldItems);
    }

    private void canbeDeleted(List<OpportunityLineItem> items) {
        List<Id> listIds = new List<Id>();
        List<Id> listOppsIds = new List<Id>();
        Map<Id, OppPriceRequestItem__c> mapLineItems = new Map<Id, OppPriceRequestItem__c>();

        for (OpportunityLineItem elem : items) {
            listIds.add(elem.Id);
            listOppsIds.add(elem.OpportunityId);
        }

        List<OppPriceRequestItem__c> listRequests = [SELECT Id, OpportunityProduct__c from OppPriceRequestItem__c where Status__c <> 'NOTSENT' AND Status__c <> NULL and OpportunityProduct__c IN : listIds];
        for (OppPriceRequestItem__c elem : listRequests) {
            mapLineItems.put(elem.OpportunityProduct__c, elem);
        }

        listIds = new List<Id>();
        for (OpportunityLineItem elem : items) {
            if (mapLineItems.containsKey(elem.Id)) {
                elem.addError(Label.prequest_cannot_delet_line_item);
            } else {
                listIds.add(elem.Id);
            }
        }

        listRequests = [SELECT Id, OpportunityProduct__c from OppPriceRequestItem__c where OpportunityProduct__c IN : listIds];
        
        delete listRequests;
    }
}