/**
* @service Hecho por NTS
*/
public class ActivityHandler {}
// public class ActivityHandler implements ITrigger
// {
//     // Constructor
//     public ActivityHandler() {}
 
//     /**
//      * bulkBefore
//      *
//      * These methods are called prior to execution of a BEFORE or AFTER trigger. Use this to cache
//      * any data required into maps prior execution of the trigger.
//      * Any new SOQL operation should be included in these methods (bulkBefore or bulkAfter)
//      */
//     public void bulkBefore(list<SObject> newList, map<Id,SObject> oldMap)
//     {
        
//     }
    
//     public void bulkAfter(list<SObject> newList, map<Id,SObject> oldMap)
//     {
//         if ( Trigger.isUpdate ) ActivityUtil.loadInfo( newList, oldMap );
//     }

//     /* These methods ara called for records to be processed during a BEFORE 
//      * trigger.
//      */
//     public void beforeInsert(list<SObject> newList)
//     {
        
//     }
    
//     public void beforeUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {
        
//     }
    
//     public void beforeDelete(map<Id,SObject> oldMap)
//     {
       
//     }
    
//     /**
//      * These methods ara called for records to be processed during a AFTER 
//      * trigger.
//      */ 
//     public void afterInsert(list<SObject> newList)
//     {
       
//     }
     
//     public void afterUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {
//         ActivityUtil.updateOwner2Cases(newList);
//     }
     
//     public void afterDelete(map<Id,SObject> oldMap)
//     {
        
//     }
     
//     /**
//      * andFinally
//      *
//      * This method is called once all records have been processed by the trigger. Use this
//      * method to accomplish any final operations such as creation or updates of other records.
//      * Any new DML operation should be included in this method
//      */
//     public void andFinally()
//     {
//         ActivityUtil.doDML();
//     }
// }