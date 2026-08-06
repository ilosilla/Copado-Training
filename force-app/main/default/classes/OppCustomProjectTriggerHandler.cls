/**
* @author 		Ramón Prades
* @date 		June 2021
* @group 		Triggers
* @description 	Trigger handler for OppCustomProject__c
*/
public class OppCustomProjectTriggerHandler extends BaseTriggerHandler {
   
    public override void beforeInsert(List<SObject> newItems) {
        if (this.isEnabled()) {
            setCurrency(newItems);
        }
    }

    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        if (this.isEnabled()) {
            setCurrency(newItems);
        }
    }

    private void setCurrency(List<SObject> newItems) {
        if (this.isEnabled()) {
            for (OppCustomProject__c item : (List<OppCustomProject__c>) newItems) {
                item.CurrencyIsoCode = item.Currency__c;
            }
        }
    }

    public override void afterInsert(List<SObject> newItems) {
        if (this.isEnabled()) {
            List<Id> oppIds = new List<Id>();
            List<Id> ids = new List<Id>();
            for (OppCustomProject__c cp :(List<OppCustomProject__c>) newItems) {
                ids.add(cp.Id);
                oppIds.add(cp.Opportunity__c);
            }        
            OpportunitiesInfoCommons.setOpportunityType(oppIds, OpportunitiesInfoCommons.PROJECT_TYPE);

            if (SystemSettings.CPNotificationsEnabled) {
                CustomProjectUtils.scheduleNoFilesEmail(ids);
                CustomProjectUtils.scheduleNewProjectEmail(ids);
            }
            if (SystemSettings.CPDeletionTime > 0) {
                CustomProjectUtils.scheduleDeletion(ids);
            }
        }
    } // afterInsert

    public override void afterDelete(List<SObject> oldItems) {
        if (this.isEnabled()) {
            List<Id> oppIds = new List<Id>();
            for (OppCustomProject__c cp :(List<OppCustomProject__c>) oldItems) {
                oppIds.add(cp.Opportunity__c);
            }        
            OpportunitiesInfoCommons.setOpportunityType(oppIds, null);
        }
    }

    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        if (this.isEnabled()) {
            CustomProjectMailer mailer = new CustomProjectMailer();
            for (OppCustomProject__c newCP :(List<OppCustomProject__c>) newItems) {
                OppCustomProject__c oldCP = (OppCustomProject__c) oldItems.get(newCP.Id);
                /*
                if (newCP.ShopDrawings__c && !oldCP.ShopDrawings__c) {
                    if (SystemSettings.CPNotificationsEnabled) {
                        mailer.sendDrawingsMail(newCP.Id);
                    }
                }
                */
                if (newCP.Stage__c <> oldCP.Stage__c) {
                    if (SystemSettings.CPNotificationsEnabled) {
                    mailer.sendStageChangeMail(newCP.Id, oldCP.Stage__c);
                    }
                }
                if (newCP.materialReleased__c != oldCP.materialReleased__c && newCP.materialReleased__c == 'YES' ) {
                    if (SystemSettings.CPNotificationsEnabled) {
                        mailer.sendMaterialMail(newCP.Id);
                    }
                }
            }
        }
    }     

} // class