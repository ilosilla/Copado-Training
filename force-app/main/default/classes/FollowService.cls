/**
* @author Ivan Losilla
* @date January 2025
* @group Follows
* @test FollowServiceTest
*/
public class FollowService {
    /**
     * @description Refresh all followed objects given an user. Deletes all current ones, and create everything again
     */
    public static void recreateFollowsByUser(String userId) {
        savepoint sp = database.setsavepoint();

        List<Follow__c> followsToDelete = Follow.getAllFollowsByUser(userId);
        delete followsToDelete;

        List<Follow__c> result = new List<Follow__c>();

        try {
            List<EntitySubscription> listSubscriptions = [SELECT id,ParentId, SubscriberId FROM EntitySubscription WHERE SubscriberId =: userId];
            result.addAll(Follow.recreateFollowsAccount(listSubscriptions, userId));
            result.addAll(Follow.recreateFollowsOpportunity(listSubscriptions, userId));
            result.addAll(Follow.recreateFollowsEvent(listSubscriptions, userId));
            result.addAll(Follow.recreateFollowsTask(listSubscriptions, userId));
            result.addAll(Follow.recreateFollowsPartners(listSubscriptions, userId));

            result = Follow.deleteDuplicates(result);

            insert result;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }
    }

    /**
     * @description Refresh all followed objects after a date given. Deletes all follows crated after the date, and creates it again
     */
    public static List<Follow__c> recreateFollows(List<EntitySubscription> subscriptions) {
        savepoint sp = database.setsavepoint();

        List<Follow__c> result = new List<Follow__c>();
        Map<String, List<EntitySubscription>> mapSubscriptions = new Map<String, List<EntitySubscription>>();
        List<EntitySubscription> aux = new List<EntitySubscription>();

        try {
            for (EntitySubscription subscribed : subscriptions) {
                aux = new List<EntitySubscription>();

                if (mapSubscriptions.containsKey(subscribed.SubscriberId)) {
                    aux = mapSubscriptions.get(subscribed.SubscriberId);
                }
                aux.add(subscribed);
                mapSubscriptions.put(subscribed.SubscriberId, aux);
            }

            for (String userId : mapSubscriptions.keySet()) {
                result.addAll(Follow.recreateFollowsAccount(mapSubscriptions.get(userId), userId));
                result.addAll(Follow.recreateFollowsOpportunity(mapSubscriptions.get(userId), userId));
                result.addAll(Follow.recreateFollowsEvent(mapSubscriptions.get(userId), userId));
                result.addAll(Follow.recreateFollowsTask(mapSubscriptions.get(userId), userId));
            }

            return result;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }
    }

    /**
     * @description Creates the follow needed given a new events created
     */
    public static void eventsCreated(List<Event> evts) {
        savepoint sp = database.setsavepoint();
        Set<String> accounts = new Set<String>();
        Map<String, Set<String>> accountSubscribers = new Map<String, Set<String>>();
        List<Follow__c> newEventFollows = new List<Follow__c>();
        Set<String> aux = new Set<String>();
        Set<String> eventIds = new Set<String>();

        try {
            for (Event evt : evts) {
                eventIds.add(evt.Id);
                if (evt.WhatId != null) {
                    accounts.add(evt.WhatId);
                }
            }

            List<EventWhoRelation> listRelations = [SELECT id, eventid, accountid from EventWhoRelation where eventId IN : eventIds];
            Map<String, String> mapEventsContact = new Map<String, String>();
            for (EventWhoRelation relation : listRelations) {
                mapEventsContact.put(relation.eventid, relation.accountId);
                accounts.add(relation.accountId);
            }
            List<EntitySubscription> follows = [SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN : accounts];
        
            for (EntitySubscription follow : follows) {
                aux = new Set<String>();
                if (accountSubscribers.containsKey(follow.ParentId)) {
                    aux = accountSubscribers.get(follow.ParentId);
                }
                aux.add(follow.SubscriberId);
                accountSubscribers.put(follow.ParentId, aux);
            }

            for (Event evt : evts) {
                if (evt.isChild == false) {
                    if (mapEventsContact.containsKey(evt.Id)) {
                        if (accountSubscribers.containsKey(mapEventsContact.get(evt.Id))) {
                            for (String subscriber : accountSubscribers.get(mapEventsContact.get(evt.Id))) {
                                newEventFollows.add(Follow.createFollowEventByContact(evt,mapEventsContact.get(evt.Id),subscriber));
                            }
                        }
                    } else {
                        if (accountSubscribers.containsKey(evt.WhatId)) {
                            for (String subscriber : accountSubscribers.get(evt.WhatId)) {
                                newEventFollows.add(Follow.createFollowEvent(evt,subscriber));
                            }
                        }
                    }
                }
            }

            insert newEventFollows;
        } catch (Exception e) {
            database.rollback(sp);
        }
    }

    /**
     * @description Updates the Event Follows needed
     */
    public static void eventsUpdated(List<Event> newValues) {
        savepoint sp = database.setsavepoint();
        Set<String> eventIds = new Set<String>();
        Map<String, Set<String>> followsOwnersMap = new Map<String, Set<String>>();

        try {
            for (Event event : newValues){
                eventIds.add(event.Id);
            }
    
            List<Follow__c> followsToDelete = [SELECT Id, ActivityId__c, Account__c, TaskDate__c, OwnerId FROM Follow__c WHERE ActivityId__c IN : eventIds];
            Set<String> auxList = new Set<String>();
            for (Follow__c follow : followsToDelete) {
                auxList = new Set<String>();
                if (followsOwnersMap.containsKey(follow.ActivityId__c)) {
                    auxList = followsOwnersMap.get(follow.ActivityId__c);
                }
                auxList.add(follow.OwnerId);
                followsOwnersMap.put(follow.ActivityId__c, auxList);
            }

            delete followsToDelete;

            eventsCreated(newValues);
            
        } catch (Exception e) {
            database.rollback(sp);
        }
    }


    /**
     * @description Creates the follow needed given a new tasks created
     */
    public static void tasksCreated(List<Task> tsks) {
        savepoint sp = database.setsavepoint();
        Set<String> accounts = new Set<String>();
        Map<String, Set<String>> accountSubscribers = new Map<String, Set<String>>();
        List<Follow__c> newTaskFollows = new List<Follow__c>();
        Set<String> aux = new Set<String>();

        try {
            for (Task tsk : tsks) {
                if (tsk.WhatId != null) {
                    accounts.add(tsk.WhatId);
                }
            }
            List<EntitySubscription> follows = [SELECT id, ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN : accounts];
        
            for (EntitySubscription follow : follows) {
                aux = new Set<String>();
                if (accountSubscribers.containsKey(follow.ParentId)) {
                    aux = accountSubscribers.get(follow.ParentId);
                }
                aux.add(follow.SubscriberId);
                accountSubscribers.put(follow.ParentId, aux);
            }

            for (Task tsk : tsks) {
                if (accountSubscribers.containsKey(tsk.WhatId)) {
                    for (String subscriber : accountSubscribers.get(tsk.WhatId)) {
                        newTaskFollows.add(Follow.createFollowTask(tsk,subscriber));
                    }
                }
            }

            insert newTaskFollows;
        } catch (Exception e) {
            database.rollback(sp);
        }
    }

    /**
     * @description Creates again the follows with the data updated
     */
    public static void tasksUpdated(List<Task> newValues) {
        savepoint sp = database.setsavepoint();
        Set<String> taskIds = new Set<String>();
        Map<String, Set<String>> followsOwnersMap = new Map<String, Set<String>>();

        try {
            for (Task task : newValues){
                taskIds.add(task.Id);
            }
    
            List<Follow__c> followsToDelete = [SELECT Id, ActivityId__c, Account__c, TaskDate__c, OwnerId FROM Follow__c WHERE ActivityId__c IN : taskIds];
            Set<String> auxList = new Set<String>();
            for (Follow__c follow : followsToDelete) {
                auxList = new Set<String>();
                if (followsOwnersMap.containsKey(follow.ActivityId__c)) {
                    auxList = followsOwnersMap.get(follow.ActivityId__c);
                }
                auxList.add(follow.OwnerId);
                followsOwnersMap.put(follow.ActivityId__c, auxList);
            }

            List<Follow__c> result = new List<Follow__c>();
            for (Task tsk : newValues) {
                if (followsOwnersMap.containsKey(tsk.Id)) {
                    for (String owner : followsOwnersMap.get(tsk.Id)) {
                        result.add(Follow.createFollowTask(tsk,owner));
                    }
                }
            }
            delete followsToDelete;
            insert result;
        } catch (Exception e) {
            database.rollback(sp);
        }
    }

    /**
     * @description Given an user, deletes all follow records
     */
    public static void deleteUnfollowedByUser(String userId) {
        List<Follow__c> follows = Follow.getUnfollowedByUser(userId);
        delete follows;
    }
}