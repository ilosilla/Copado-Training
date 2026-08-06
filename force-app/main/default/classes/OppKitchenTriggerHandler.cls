/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Triggers
* @description 	Trigger handler for OppKitchen__c
*/
public class OppKitchenTriggerHandler extends BaseTriggerHandler {
    
    public override void beforeInsert(List<SObject> newItems) {
        setCurrency(newItems);
    }

    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        setCurrency(newItems);
    }

    private void setCurrency(List<SObject> newItems) {
        for (OppKitchen__c item : (List<OppKitchen__c>) newItems) {
            item.CurrencyIsoCode = item.Currency__c;
        }
    }
    
    public override void afterInsert(List<SObject> newItems) {
        List<Id> oppIds = new List<Id>();
        for (OppKitchen__c k :(List<OppKitchen__c>) newItems) {            
            oppIds.add(k.Opportunity__c);
            if (SystemSettings.CPNotificationsEnabled) {        
                OppKitchenMailer mailer = new OppKitchenMailer(k.Id);
                mailer.sendNewKitchenMail();
            }
        }
        OpportunitiesInfoCommons.setOpportunityType(oppIds, OpportunitiesInfoCommons.KITCHEN_TYPE);
    } // afterInsert

    public override void afterDelete(List<SObject> oldItems) {
        List<Id> oppIds = new List<Id>();
        for (OppKitchen__c cp :(List<OppKitchen__c>) oldItems) {
            oppIds.add(cp.Opportunity__c);
        }        
        OpportunitiesInfoCommons.setOpportunityType(oppIds, null);
    }


} // OppKitchenTriggerHandler