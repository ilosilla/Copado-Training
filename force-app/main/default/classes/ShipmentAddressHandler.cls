/**
 * Trigger Handler for the ShipmentAddress SObject. This class implements the ITrigger
 * interface to help ensure the trigger code is bulkified and all in one place.
* @author gmiranda - NTS
* @date 09/05/2018
*/

/**
* @service Hecho por NTS
*/

public class ShipmentAddressHandler {}
// public class ShipmentAddressHandler implements ITrigger
// {
//     // Constructor
//     public ShipmentAddressHandler() {}
 
//     /**
//      * bulkBefore
//      *
//      * These methods are called prior to execution of a BEFORE or AFTER trigger. Use this to cache
//      * any data required into maps prior execution of the trigger.
//      * Any new SOQL operation should be included in these methods (bulkBefore or bulkAfter)
//      */
//     public void bulkBefore(list<SObject> newList, map<Id,SObject> oldMap)
//     {
//         /*
//         AccountUtil.loadData(newList, (Map<Id, Account>)oldMap);
//         */
        
//     }
    
//     public void bulkAfter(list<SObject> newList, map<Id,SObject> oldMap)
//     {
//         /*
//         AccountUtil.loadData(newList, (Map<Id, Account>)oldMap);
//         */
//     }

//     /* These methods ara called for records to be processed during a BEFORE 
//      * trigger.
//      */
//     public void beforeInsert(list<SObject> newList)
//     {
//         /*
//         AccountUtil.methodA(newList, null);
//         AccountUtil.methodB(newList);
//         ...
//         */
//     }
    
//     public void beforeUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {
        
//     }
    
//     public void beforeDelete(map<Id,SObject> oldMap)
//     {
//         /*
//         AccountUtil.methodA(null, (Map<Id, Account>)oldMap);
//         AccountUtil.methodB(oldMap);
//         ...
//         */
//     }
    
//     /**
//      * These methods ara called for records to be processed during a AFTER 
//      * trigger.
//      */ 
//     public void afterInsert(list<SObject> newList)
//     {
//         system.debug('handler--');
//         ShipmentAddressUtil.updatePrimaryShipmentAddress((List<Shipment_Address__c>)newList,null);    
//     }
     
//     public void afterUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {
//     	ShipmentAddressUtil.updatePrimaryShipmentAddress((List<Shipment_Address__c>)newList,(Map<Id,Shipment_Address__c>)oldMap);
        
//     }
     
//     public void afterDelete(map<Id,SObject> oldMap)
//     {
//         /*
//         AccountUtil.methodA(null, (Map<Id, Account>)oldMap);
//         AccountUtil.methodB((Map<Id, Account>)oldMap);
//         ...
//         */
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
//         /*
//         AccountUtil.methodA();
//         AccountUtil.methodB();
//         ...
//         */
//     }



// }