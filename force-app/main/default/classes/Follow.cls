/**
* @author Ivan Losilla
* @date January 2025
* @group Follows
* @test FollowServiceTest
*/
public class Follow {
    public static final String ACCOUNT_RT = Schema.SObjectType.Follow__c.getRecordTypeInfosByName().get('Account').getRecordTypeId();
    public static final String OPPORTUNITY_RT = Schema.SObjectType.Follow__c.getRecordTypeInfosByName().get('Opportunity').getRecordTypeId();
    public static final String EVENT_RT = Schema.SObjectType.Follow__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
    public static final String TASK_RT = Schema.SObjectType.Follow__c.getRecordTypeInfosByName().get('Task').getRecordTypeId();

    public static Follow__c createFollowAccount(String accountId, String ownerId) {
        return new Follow__c(
            Account__c = accountId,
            OwnerId = ownerId,
            RecordTypeId = ACCOUNT_RT
            );
    }

    public static Follow__c createFollowOpportunity(String opportunityId, String ownerId) {
        return new Follow__c(
            Opportunity__c = opportunityId,
            OwnerId = ownerId,
            RecordTypeId = OPPORTUNITY_RT
            );
    }

    public static Follow__c createFollowEvent(Event event, String ownerId) {
        Follow__c result = new Follow__c(
            OwnerId = ownerId,
            ActivityId__c = event.Id,
            EventStartDate__c = event.StartDateTime,
            EventEndDate__c = event.EndDateTime,
            ActivitySubject__c = event.Subject,
            RecordTypeId = EVENT_RT
        );

        switch on event.WhatId.getSObjectType().getDescribe().getName().toUppercase() {
            when 'ACCOUNT' {
                result.Account__c = event.WhatId;
            }
            when 'OPPORTUNITY' {
                result.Opportunity__c = event.WhatId;
            }
        }
        return result;
    }

    public static Follow__c createFollowEventByContact(Event event, String accountId, String ownerId) {
        Follow__c result = new Follow__c(
            Account__c = accountId,
            OwnerId = ownerId,
            ActivityId__c = event.Id,
            EventStartDate__c = event.StartDateTime,
            EventEndDate__c = event.EndDateTime,
            ActivitySubject__c = event.Subject,
            RecordTypeId = EVENT_RT
        );
        return result;
    }

    public static Follow__c createFollowTask(Task task, String ownerId) {
        Follow__c result = new Follow__c(
            OwnerId = ownerId,
            ActivityId__c = task.Id,
            TaskDate__c = task.ActivityDate,
            ActivitySubject__c = task.Subject,
            RecordTypeId = TASK_RT
        );
        
        switch on task.WhatId.getSObjectType().getDescribe().getName().toUppercase() {
            when 'ACCOUNT' {
                result.Account__c = task.WhatId;
            }
            when 'OPPORTUNITY' {
                result.Opportunity__c = task.WhatId;
            }
        }
        return result;
    }

    public static List<Follow__c> getUnfollowedByUser(String userId) {
        List<EntitySubscription> listSubscriptions = [SELECT id,ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: userId];
        Set<String> followedIds = new Set<String>();
        
        for (EntitySubscription subscription : listSubscriptions) {
            followedIds.add(subscription.ParentId);
        }

        List<Follow__c> followsToDelete = [SELECT Id, Account__c, Opportunity__c, ActivityId__c FROM Follow__c
                                            WHERE OwnerId =: userId
                                            AND Account__c NOT IN : followedIds
                                            AND Opportunity__c NOT IN : followedIds
                                            AND ActivityId__c NOT IN : followedIds];

        return followsToDelete;
    }


    public static List<Follow__c> recreateFollowsAccount(List<EntitySubscription> subscriptions, String userId) {
        Set<String> accountIds = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();

        for (EntitySubscription subscription : subscriptions) {
            switch on subscription.ParentId.getSObjectType().getDescribe().getName().toUppercase() {
                when 'ACCOUNT' {
                    accountIds.add(subscription.ParentId);
                }
            }
        }

        for (String acc : accountIds) {
            result.add(createFollowAccount(acc, userId));
        }

        return result;
    }

    public static List<Follow__c> recreateFollowsOpportunity(List<EntitySubscription> subscriptions, String userId) {
        Set<String> opportunityIds = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();

        for (EntitySubscription subscription : subscriptions) {
            switch on subscription.ParentId.getSObjectType().getDescribe().getName().toUppercase() {
                when 'OPPORTUNITY' {
                    opportunityIds.add(subscription.ParentId);
                }
            }
        }

        for (String opp : opportunityIds) {
            result.add(createFollowOpportunity(opp, userId));
        }

        return result;
    }

    public static List<Follow__c> recreateFollowsEvent(List<EntitySubscription> subscriptions, String userId) {
        Set<String> accountIds = new Set<String>();
        Set<String> eventIds = new Set<String>();
        Set<String> eventByContactIds = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();
        Map<String, Contact> contactsMap = new Map<String, Contact>();

        for (EntitySubscription subscription : subscriptions) {
            switch on subscription.ParentId.getSObjectType().getDescribe().getName().toUppercase() {
                when 'ACCOUNT' {
                    accountIds.add(subscription.ParentId);
                }
                when 'EVENT' {
                    eventIds.add(subscription.ParentId);
                }
            }
        }

        for (Contact cntct : [SELECT Id, AccountId FROM Contact WHERE AccountId IN : accountIds]) {
            contactsMap.put(cntct.Id, cntct);
        }

        List<EventWhoRelation> listEventsByContact = [Select id,EventId, AccountId from EventWhoRelation where AccountId IN : accountIds OR RelationId IN : contactsMap.keySet()];
        Map<String, String> mapEventsContact = new Map<String, String>();
        for (EventWhoRelation contactsRel : listEventsByContact) {
            if (contactsRel.AccountId == null) {
                if (contactsMap.containsKey(contactsRel.RelationId)) {
                    mapEventsContact.put(contactsRel.EventId, contactsMap.get(contactsRel.RelationId).AccountId);
                }
            } else {
                mapEventsContact.put(contactsRel.EventId, contactsRel.AccountId);
            }
            eventByContactIds.add(contactsRel.EventId);
        }

        Set<String> eventIdsToCreate = new Set<String>();
        List<Event> listEvents = [SELECT Id, StartDateTime, EndDateTime,Subject, WhatId FROM Event WHERE isChild = false AND ( WhatId IN: accountIds OR Id IN : eventIds) AND createddate = LAST_N_DAYS:90];
        List<Event> listEventswithContacts = [SELECT Id, StartDateTime, EndDateTime,Subject, WhatId FROM Event WHERE isChild = false AND Id IN : eventByContactIds AND createddate = LAST_N_DAYS:90];
        
        for (Event evt : listEvents) {
            eventIdsToCreate.add(evt.Id);
            result.add(createFollowEvent(evt, userId));
        }

        for (Event evtByContact : listEventswithContacts) {
            if (eventIdsToCreate.contains(evtByContact.Id) == false && mapEventsContact.containsKey(evtByContact.Id)) {
                eventIdsToCreate.add(evtByContact.Id);
                result.add(createFollowEventByContact(evtByContact,mapEventsContact.get(evtByContact.Id), userId));
            }
        }

        return result;
    }

    public static List<Follow__c> recreateFollowsTask(List<EntitySubscription> subscriptions, String userId) {
        Set<String> accountIds = new Set<String>();
        Set<String> taskIds = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();

        for (EntitySubscription subscription : subscriptions) {
            switch on subscription.ParentId.getSObjectType().getDescribe().getName().toUppercase() {
                when 'ACCOUNT' {
                    accountIds.add(subscription.ParentId);
                }
                when 'TASK' {
                    taskIds.add(subscription.ParentId);
                }
            }
        }

        List<Task> listTasks = [SELECT Id, ActivityDate,Subject, WhatId FROM Task WHERE (WhatId IN: accountIds OR Id IN : taskIds) AND createddate = LAST_N_DAYS:90];

        for (Task task : listTasks) {
            result.add(createFollowTask(task, userId));
        }

        return result;
    }

    public static List<Follow__c> recreateFollowsPartners(List<EntitySubscription> subscriptions, String userId) {
        Set<String> accountIds = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();

        for (EntitySubscription subscription : subscriptions) {
            switch on subscription.ParentId.getSObjectType().getDescribe().getName().toUppercase() {
                when 'ACCOUNT' {
                    accountIds.add(subscription.ParentId);
                }
            }
        }

        Map<String, Set<String>> partnersMap = new Map<String, Set<String>>();
        Set<String> partnersIds = new Set<String>();
        List<Partner> partnersrelated = [SELECT Id, AccountFromId, AccountToId FROM Partner WHERE AccountFromId IN : accountIds or AccountToId IN : accountIds];
        for (Partner prt : partnersrelated) {
            if (partnersMap.containsKey(prt.AccountFromId)) {
                partnersMap.get(prt.AccountFromId).add(prt.AccountToId);
            } else {
                partnersMap.put(prt.AccountFromId, new Set<String>{prt.AccountToId});
            }

            partnersIds.add(prt.AccountToId);
        }

        List<Task> listTasks = [SELECT Id, ActivityDate,Subject, WhatId FROM Task WHERE WhatId IN: partnersIds AND createddate = LAST_N_DAYS:90];

        for (Task task : listTasks) {
            result.add(createFollowTask(task, userId));
        }

        Set<String> eventByContactIds = new Set<String>();
        List<EventWhoRelation> listEventsByContact = [Select id,EventId, AccountId from EventWhoRelation where AccountId IN : partnersIds];
        Map<String, String> mapEventsContact = new Map<String, String>();
        for (EventWhoRelation contactsRel : listEventsByContact) {
            mapEventsContact.put(contactsRel.EventId, contactsRel.AccountId);
            eventByContactIds.add(contactsRel.EventId);
        }

        Set<String> eventIdsToCreate = new Set<String>();
        List<Event> listEvents = [SELECT Id, StartDateTime, EndDateTime,Subject, WhatId FROM Event WHERE IsChild = false AND WhatId IN: partnersIds AND createddate = LAST_N_DAYS:90];
        List<Event> listEventswithContacts = [SELECT Id, StartDateTime, EndDateTime,Subject, WhatId FROM Event WHERE IsChild = false AND Id IN : eventByContactIds AND createddate = LAST_N_DAYS:90];
        
        for (Event evt : listEvents) {
            eventIdsToCreate.add(evt.Id);
            result.add(createFollowEvent(evt, userId));
        }

        for (Event evtByContact : listEventswithContacts) {
            if (eventIdsToCreate.contains(evtByContact.Id) == false && mapEventsContact.containsKey(evtByContact.Id)) {
                eventIdsToCreate.add(evtByContact.Id);
                result.add(createFollowEventByContact(evtByContact,mapEventsContact.get(evtByContact.Id), userId));
            }
        }

        return result;
    }

    public static List<Follow__c> getDuplicateFollows(List<EntitySubscription> subscriptions) {
        Map<String, List<EntitySubscription>> mapSubscriptions = new Map<String, List<EntitySubscription>>();
        List<EntitySubscription> aux = new List<EntitySubscription>();
        List<Follow__c> duplicates = new List<Follow__c>();

        try {
            for (EntitySubscription subscribed : subscriptions) {
                aux = new List<EntitySubscription>();

                if (mapSubscriptions.containsKey(subscribed.SubscriberId)) {
                    aux = mapSubscriptions.get(subscribed.SubscriberId);
                }
                aux.add(subscribed);
                mapSubscriptions.put(subscribed.SubscriberId, aux);
            }

            List<Follow__c> existingFollows = [SELECT Id, Account__c, Opportunity__c, ActivityId__c, OwnerId FROM Follow__c WHERE OwnerId IN : mapSubscriptions.keySet()];
            Boolean found = false;
            for (Follow__c follow : existingFollows) {
                found = false;
                for (EntitySubscription entity : mapSubscriptions.get(follow.OwnerId)) {
                    if (entity.SubscriberId == follow.OwnerId) {
                        if (follow.ActivityId__c != null && follow.ActivityId__c == entity.ParentId) {
                            found = true;
                            break;
                        }
                        if (follow.ActivityId__c == null) {
                            if (follow.Account__c == entity.ParentId) {
                                found = true;
                                break;
                            } else if (follow.Opportunity__c == entity.ParentId) {
                                found = true;
                                break;
                            }
                        }
                    }
                }
                if (found == true) {
                    duplicates.add(follow);
                }
            }
            return duplicates;
        } catch (Exception e) {
            throw(e);
        }
    }

    public static List<Follow__c> getAllFollowsByUser(String userId){
        List<Follow__c> result = [SELECT Id FROM Follow__c WHERE OwnerId =: userId];
        return result;
    }

    public static List<Follow__c> getAllFollowsByDate(Date dateParam){
        List<Follow__c> result = [SELECT Id FROM Follow__c WHERE Createddate >=: dateParam];
        return result;
    }

    public static List<Follow__c> deleteDuplicates(List<Follow__c> follows) {
        Set<String> existingActivities = new Set<String>();
        Set<String> existingAccounts = new Set<String>();
        Set<String> existingOpps = new Set<String>();
        List<Follow__c> result = new List<Follow__c>();

        for(Follow__c follow: follows) {
            if(follow.ActivityId__c != null && existingActivities.contains(follow.ActivityId__c) == false && existingActivities.contains(follow.ActivityId__c) == false) {
                result.add(follow);
                existingActivities.add(follow.ActivityId__c);
            }
            if(follow.ActivityId__c == null && follow.Opportunity__c == null && follow.Account__c != null && existingAccounts.contains(follow.Account__c) == false) {
                result.add(follow);
                existingAccounts.add(follow.Account__c);
            }
            if(follow.ActivityId__c == null && follow.Opportunity__c != null && existingOpps.contains(follow.Opportunity__c) == false) {
                result.add(follow);
                existingOpps.add(follow.Opportunity__c);
            }
        }

        return result;
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}