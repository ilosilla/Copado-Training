/**
* @service Hecho por NTS
*/
public class EmailMessageUtil {}
// public class EmailMessageUtil 
// {
//     /**
//     *   - Cretes the global maps that are going to be used throwgh the class
//     **
//     *  @author jurretabizkaia
//     *  @date 17/07/2018
//     */

//     private static Map<Id,Case> caseMap
//     {
//         get
//         {
//             if (caseMap == null) caseMap = new Map<Id,Case>();
//             return caseMap;
//         }
//         private set;
//     }

//     private static Map<Id,Queue_metadata__mdt> queueMetadataMap
//     {
//         get
//         {
//             if ( queueMetadataMap == null) queueMetadataMap = new Map<Id,Queue_metadata__mdt>();
//             return queueMetadataMap;
//         }
//         private set;
//     }

//     private static List<Case>   cases2Update
//     {
//         get
//         {
//             if ( cases2Update == null) cases2Update = new List<Case>();
//             return cases2Update;
//         }
//         private set;
//     }    


//     /**
//     *   - Fills the structures generated above by querying the required info (cases and queue metadata)
//     **
//     *  @author jurretabizkaia
//     *  @date 17/07/2018
//     *  @where Bulk After 
//     */

//     public static void loadInfo (list<EmailMessage> newList)
//     {   
//         Set <String> partenIdSet    =   new Set<String>(); 
//         Set <String> ownerIdSet     =   new Set<String>();

//         for (EmailMessage em : newList)
//         {
//             if (em.parentId != null && em.incoming) 
//             {
//                 partenIdSet.add( em.parentId);
//             }
//         }

//         // 2 - Query ownerId (users) from cases
//         for (Case c : [Select Id, OwnerId from Case where id in : partenIdSet])
//         {
//             if (c.OwnerId != null && c.OwnerId.getSObjectType() == user.getSObjectType()) 
//             {
//                 ownerIdSet.add(c.OwnerId);
//                 caseMap.put(c.Id, c);
//             }
//         }

//         // 3 - Query queue (queue metadata) from users
//         for (Queue_metadata__mdt qmdt : [Select Id, User__c, Queue__c, Queue_others__c from Queue_metadata__mdt where User__c in : ownerIdSet])
//         {
//             if (qmdt.User__c != null && qmdt.User__c != '') queueMetadataMap.put(qmdt.User__c, qmdt);
//         }
//     }

//     /**
//     *   - Goes through all the emails, and validates if their cases ownerIDs are users. 
//     *  If so, looks up the user in the metadata type, and changes the owner of the case to 
//     *  the queue related to that user.
//     **
//     *  @author jurretabizkaia
//     *  @date 17/07/2018
//     *  @param caseMap Map<Id,Case>, queueMetadataMap Map<Id,Queue_metadata__mdt>
//     *  @where After Insert
//     */
//     public static void assignQueue(list<EmailMessage> newList)
//     {   
//         for (EmailMessage em : newList)
//         {
//             if ( caseMap.containsKey(em.parentId) && queueMetadataMap.containsKey ( caseMap.get(em.parentId).OwnerId ) ) 
//             {
//                 cases2Update.add
//                 (
//                     new Case
//                     (
//                         ID = em.parentId, 
//                         OwnerId = queueMetadataMap.get(caseMap.get(em.parentId).OwnerId). Queue__c
//                     )
//                 );
//             }
//         }
//     }


//     public static void doDML()
//     {
//         if ( !cases2Update.isEmpty() )
//         {
//             update cases2Update;
//             cases2Update.clear();
//         }
//     }
// }