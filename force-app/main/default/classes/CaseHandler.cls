/**
 * Trigger Handler for the Case SObject. This class implements the ITrigger
 * interface to help ensure the trigger code is bulkified and all in one place.
* @author daguzman-NTS
* @date 02/05/2018
* @service Hecho por NTS
*/


public class CaseHandler {}
// public class CaseHandler implements ITrigger
// {
//     // Constructor
//     public CaseHandler() {}
 
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
        
//     }

//     /* These methods ara called for records to be processed during a BEFORE 
//      * trigger.
//      */
//     public void beforeInsert(list<SObject> newList)
//     {
//         system.debug('*1 '+newList);
//         CaseUtil.relateToAccountContactCaseManagementEntitlement(newList,null);
//         system.debug('*2 '+newList);
//         CaseUtil.getCustomerState((List<Case>)newList,null);
//         system.debug('*3 '+newList);
//     }
    
//     public void beforeUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {        
//         CaseUtil.getCustomerState((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.registerLastStatusChange((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.relateToAccountContactCaseManagementEntitlement(newList,(Map<Id,Case>)oldMap);
//         CaseUtil.serviceAccomplishCloseCase((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.reopenReturnToProblemIdentification((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.updateServiceDoneReschedulable((List<Case>)newList,(Map<Id,Case>)oldMap);

//         CaseUtil.completeFinalMilestone((List<Case>)newList,(Map<Id,Case>)oldMap); // ¿NO NECESARIO?
//     }
    
//     public void beforeDelete(map<Id,SObject> oldMap)
//     {
//        CaseUtil.calculateTotalPriceSentMaterialsSubcases(null,(Map<Id,Case>)oldMap);
//     }
    
//     /**
//      * These methods ara called for records to be processed during a AFTER 
//      * trigger.
//      */ 
//     public void afterInsert(list<SObject> newList)
//     {
        
//         CaseUtil.calculateTotalPriceSentMaterialsSubcases((List<Case>)newList,null);
//         CaseUtil.createAccountCaseManagementEntitlement((List<Case>)newList);
//     }
     
//     public void afterUpdate(list<SObject> newList, map<Id,SObject> oldMap)
//     {

//         CaseUtil.updateParentStatus((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.calculateTotalPriceSentMaterialsSubcases((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.reopenChildCases((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.closeChildCases((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.splitProductCasesFromParent((List<Case>)newList,(Map<Id,Case>)oldMap);

//         //Task autocomplete
//         CaseUtil.completeDeliveryDate((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.completeServiceDate((List<Case>)newList,(Map<Id,Case>)oldMap);        
//         CaseUtil.completeCustomerFeedback((List<Case>)newList,(Map<Id,Case>)oldMap);
//         CaseUtil.completeTechnicianFeedback((List<Case>)newList,(Map<Id,Case>)oldMap);
        
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
        
//     }



// }