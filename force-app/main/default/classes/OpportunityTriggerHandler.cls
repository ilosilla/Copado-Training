/**
* @author Ivan Losilla
* @date January 2021
*
* @group Triggers
*/
public class OpportunityTriggerHandler extends BaseTriggerHandler {
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Opportunity> mapOldItems = new Map<Id, Opportunity>();
        for (Opportunity opp : (List <Opportunity>)oldItems.values()){
            mapOldItems.put(opp.Id, opp);
        }
        OpportunitiesDomain.setOpportunityStage((List<Opportunity>) newItems, mapOldItems);
        changesBeforeupdate((List<Opportunity>) newItems);
        Porsamarket.manageLockedOpportunitiesBefore((List<Opportunity>) newItems, mapOldItems);
    }
    
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        OpportunitiesDomain domain = new OpportunitiesDomain(newItems);
        domain.runStageActions((Map<Id, Opportunity>)oldItems);

        if (UserCommons.hasSAPConnection()) {
            for (Opportunity newOpp : (List<Opportunity>) newItems) {
                Opportunity oldOpp = (Opportunity) oldItems.get(newOpp.Id);
                boolean changed = (
                                (oldOpp.Name != newOpp.Name) || 
                                (oldOpp.CloseDate != newOpp.CloseDate) ||
                                (oldOpp.AccountId != newOpp.AccountId) || (oldOpp.SalesProgram__c != newOpp.SalesProgram__c));
                if (changed) {                  
                        SAPSyncOpportunity.sync(newOpp.Id);
                }
            }
        }

        Map<Id, Opportunity> mapOldItems = new Map<Id, Opportunity>();
        for (Opportunity opp : (List <Opportunity>)oldItems.values()){
            mapOldItems.put(opp.Id, opp);
        }
        setOpportunityPricebookUpdate((List<Opportunity>) newItems, mapOldItems);
        platformEventUpdate(newItems,oldItems);
        Porsamarket.manageLockedOpportunitiesAfter((List<Opportunity>) newItems, mapOldItems);
    }
  
  public override void beforeInsert(List<SObject> newItems) {
    defaultValues((List<Opportunity>) newItems);
    OpportunitiesDomain.setOpportunityStage((List<Opportunity>) newItems);
}

  public override void afterInsert(List<SObject> newItems) {
        if (UserCommons.hasSAPConnection()) {
            for (Opportunity newOpp : (List<Opportunity>) newItems) {                 
                SAPSyncOpportunity.sync(newOpp.Id);
            }
        }
        automaticOpportunityTeamMember((List<Opportunity>) newItems);
        automaticOpportunityContactRole((List<Opportunity>) newItems);
        setOpportunityPricebookInsert((List<Opportunity>) newItems);
        platformEventNew((List<Opportunity>) newItems);
    }
    
    
    /*********************************************************************************************/    
    /********************************       Private Methods      *********************************/
    /*********************************************************************************************/

    public static void setOpportunityPricebookInsert(List<Opportunity> opportunities) {
        Set<Id> oppsSet = new Set<Id>();
        for (Opportunity opp : opportunities) {
            oppsSet.add(opp.Id);
        }
        setOpportunityPricebookInsertFuture(oppsSet);
    }

    @future
    public static void setOpportunityPricebookInsertFuture(Set<Id> opportunitiesIds) {
        List<Opportunity> oppsList = [SELECT Id, Pricebook2Id,Owner.Execution_Context__c, AccountId, OwnerId FROM Opportunity WHERE Id IN : opportunitiesIds];
        for (Opportunity opp : oppsList) {
            AbstractPricebookAssignator pricebookAssign = PricebookAssignator.getInstance(opp.Owner.Execution_Context__c);
            pricebookAssign.setUser(opp.OwnerId);
            pricebookAssign.setAccount(opp.AccountId);
            Pricebook2 pbAssigned = pricebookAssign.getPricebook();

            if (pbAssigned != null && opp.Pricebook2Id == null) {
                opp.Pricebook2Id = pbAssigned.Id;
            }
        }
        List<Database.SaveResult> resultsOpps = Database.update(oppsList, false);

        for (Database.SaveResult sr : resultsOpps) {
            if (!sr.isSuccess()) {
                Logger.error('Failed update Opportunity Pricebook', sr);
            }
        }
        Logger.saveLog();
    }

    // Not used Future method because it doesn't fill the pricebook2Id field
    public static void setOpportunityPricebookUpdate(List<Opportunity> opportunities, Map<Id, Opportunity> oldValues) {
        Set<Id> changePricebookIds = new Set<Id>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : opportunities) {
            if (opp.CurrencyIsoCode != oldValues.get(opp.Id).CurrencyIsoCode) {
                changePricebookIds.add(opp.Id);
            } 
        }

        if (changePricebookIds.size() > 0) {
            try {
                List<Opportunity> opps = new OpportunitiesSelector().selectByIdWithOwner(changePricebookIds);
                if (opps.size() > 0) {
                    for (Opportunity opp : opps) {
                        AbstractPricebookAssignator pricebookAssign = PricebookAssignator.getInstance(opp.Owner.Execution_Context__c);
                        pricebookAssign.setUser(opp.OwnerId);
                        pricebookAssign.setAccount(opp.AccountId);
                        Pricebook2 pbAssigned = pricebookAssign.getPricebook();
        
                        if (pbAssigned != null && opp.Pricebook2Id != pbAssigned.Id) {
                            opp.Pricebook2Id = pbAssigned.Id;
                            oppsToUpdate.add(opp);
                        }
                    }
                }
                update oppsToUpdate;
            } catch (ContextException ex) {
               LoggerCommons.LogException('PRICEBOOKOPPORTUNITY', '', ex);
            }
        }
    }

    private void defaultValues(List<Opportunity> opportunities) {
      User triggerUser = [SELECT Id, ProfileId, CountryCode, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c
          FROM User WHERE Id =: UserInfo.getUserId()];

          OpportunitiesDomain.setOpportunityCurrency(opportunities);

        for (Opportunity opp : opportunities) {
            opp.Sales_Org__c = triggerUser.Default_Sales_Organization__c;
            opp.Dist_Channel__c = triggerUser.Distribution_channel_default__c;
            opp.Last_Activity_Date__c = System.now();
            opp.Name = opp.Name + ' / ' + opp.Postcode__c;
            if (opp.Currency__c != null && opp.Currency__c != '') {
                opp.CurrencyIsoCode = opp.Currency__c;
            }
        }
    }

    private void changesBeforeupdate(List<Opportunity> opportunities) { 
        for (Opportunity opp : opportunities) {
            if (opp.Currency__c != null && opp.Currency__c != '') {
                opp.CurrencyIsoCode = opp.Currency__c;
            }
        }


    }

    private void automaticOpportunityContactRole(List<Opportunity> newOpps) {
        try {
            List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
    
            for (Opportunity opp : newOpps) {
                if (opp.ContactId__c != null) {
                    contactRoles.add(new OpportunityContactRole(ContactId = opp.ContactId__c, OpportunityId = opp.Id));
                }
            }

            if (contactRoles.size() > 0) {
                insert contactRoles;
            }
        } catch (ContextException ex) {
            Logger.error('Automatic Contact role not created');
            Logger.error(ex.getTypeName() +  '(' + ex.getLineNumber() + ') - ' + ex.getMessage());
            Logger.error(ex.getStackTraceString());
            logger.saveLog();
        }
    }

    private void automaticOpportunityTeamMember(List<Opportunity> newOpps) {
        List<OpportunityTeamMember> listTeamMembers = new List<OpportunityTeamMember>();

        for (Opportunity opp : newOpps) {
            OpportunityTeamMember newElem = new OpportunityTeamMember(OpportunityId = opp.Id, UserId = opp.OwnerId, OpportunityAccessLevel ='Edit', TeamMemberRole='Opportunity Owner'); 
            listTeamMembers.add(newElem);
        }

        try {
            insert listTeamMembers;
        } catch (ContextException ex) {
            Logger.error('NO TEAMMEMBER CREATED');
            Logger.error(ex.getTypeName() +  '(' + ex.getLineNumber() + ') - ' + ex.getMessage());
            Logger.error(ex.getStackTraceString());
            logger.saveLog();
        }
    }

    /**
    * @description Creates Platform Events about the updated opportunity
    */
    private void platformEventUpdate(List<SObject> newValues, Map<Id,SObject> oldValues) {
        List<PEUpdateOpportunity__e> listPlatformEvents = new List<PEUpdateOpportunity__e>();
        for (Opportunity opp : (List<opportunity>) newValues) {
            if (opp.StageName != ((Opportunity) oldValues.get(opp.Id)).StageName) {
                listPlatformEvents.add( new PEUpdateOpportunity__e( objectId__c = opp.Id, fieldChanged__c = 'StageName' ));
            }
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess() == false) {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    }

    /**
    * @description Creates Platform Events about the new opportunity
    */
    private void platformEventNew(List<Opportunity> opps) {
        List<PENewOpportunity__e> listPlatformEvents = new List<PENewOpportunity__e>();
        for (Opportunity opp : (List<Opportunity>) opps) {
            listPlatformEvents.add( new PENewOpportunity__e( objectId__c = opp.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess() == false) {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}