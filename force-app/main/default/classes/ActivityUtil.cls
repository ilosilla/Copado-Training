/**
* @service Hecho por NTS
*/
public class ActivityUtil {}
// public class ActivityUtil 
// {
//     private static Map<Id,Queue_metadata__mdt> qMap
//     {
//         get
//         {
//             if ( qMap == null)  qMap    =   new Map<Id,Queue_metadata__mdt>();
//             return              qMap;
//         }
//         private set;
//     }

//     private static Map<Id,Case> caseMap
//     {
//         get
//         {
//             if (caseMap == null)    caseMap    =   new Map<Id,Case>();
//             return                  caseMap;
//         }
//         private set;
//     }

//     private static Map<Id,Case>   cases2Update
//     {
//         get
//         {
//             if ( cases2Update == null) cases2Update = new Map<Id,Case>();
//             return cases2Update;
//         }
//         private set;
//     }   

//     /**
//     *   Creates the Data Structures necessary for the processing of the info.
//     *   Only the Activities related with Cases whose Owner is not a Queue should be processed
//     *   Only the Activities with the Notify_Owner__c field set to true should be processed
//     **
//     *  @author  ugonzalez
//     *  @date    20/07/2018
//     *  @param   newList   →   Contains the Trigger.New
//     *  @param   oldMap    →   Contains the Trigger.Old
//     */
//     public static void loadInfo ( List<SObject> newList, map<Id,SObject> oldMap)
//     {
//         Set<String> caseSet  =   new Set<String>();
//         Set<String> ownerSet =   new Set<String>();
//         String cPrefix       =   Schema.SObjectType.Case.getKeyPrefix();

//         for ( SObject o: newList )
//         {
//             if (    (Boolean) o.get('Notify_Owner__c')  
//                     &&  o.get('Notify_Owner__c') != oldMap.get(o.Id).get('Notify_Owner__c') 
//                     &&  ( (String) o.get('WhatId') ).startsWith(cPrefix) 
//                )
//             {   // Acaba de marcarse la notificación y Es un Caso
//                     caseSet.add( (String) o.get('WhatId') );
//             }
//         }

//         Schema.SObjectType uId =    User.getSObjectType();
//         for ( Case c : [SELECT Id, OwnerId FROM Case WHERE Id in :caseSet])
//         {
//             if (    c.OwnerId != null   &&  c.OwnerId.getSObjectType() == uId ) 
//             {   // El propietario del Caso no es una Cola
//                 ownerSet.add(c.OwnerId);
//                 caseMap.put(c.Id, c);
//             }
//         }

//         for ( Queue_metadata__mdt qmdt : [Select Id, User__c, Queue__c, Queue_others__c from Queue_metadata__mdt where User__c in : ownerSet])
//         {
//             if (qmdt.User__c != null && qmdt.User__c != '') qMap.put(qmdt.User__c, qmdt);
//         }        
//     }


//     /**
//     *   Based on the info calculated on the loadInfo() method, it processes only those Activities related to the Cases meeting the criteria.
//     *   The process will update the Owner of each case to the Personal Queue of each Agent
//     **
//     *  @author  ugonzalez
//     *  @date    20/07/2018
//     *  @param   newList   →   Contains the Trigger.New
//     */
//     public static void updateOwner2Cases( List<SObject> newList )
//     {
//         for ( SObject o: newList )
//         {
//             if  (   caseMap.containsKey( (String) o.get('WhatId') ) 
//                     &&  qMap.containsKey( caseMap.get( (String) o.get('WhatId') ).OwnerId ) 
//                     &&  !cases2Update.containsKey( (String) o.get('WhatId') ) 
//                 )
//             {
//                 cases2Update.put
//                 (
//                     (String) o.get('WhatId'),
//                     new Case
//                     (
//                         ID      =   (String) o.get('WhatId'), 
//                         OwnerId =   qMap.get( caseMap.get( (String) o.get('WhatId') ).OwnerId ).Queue__c
//                     )
//                 );
//             }
//         }
//     }

//     /**
//     *   Method for carrying out all the DML's related with this trigger
//     **
//     *  @author  ugonzalez
//     *  @date    20/07/2018
//     */
//     public static void doDML()
//     {
//         if ( !cases2Update.isEmpty() )
//         {
//             update cases2Update.values();
//             cases2Update.clear();
//         }
//     }
// }