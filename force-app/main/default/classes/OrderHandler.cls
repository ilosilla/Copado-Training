/**
* @author 		Ramón Prades
* @date 		April 2021
* @group 		Triggers
* @description 	Trigger handler for Orders (used for ecommerce samples opportunity creation)
* @deprecated Abril 2022 No se utilizan los Orders para nada
*/
public class OrderHandler {}
// public class OrderHandler implements ITrigger2{
    
//     // Variable member that stores the identifiers
//     // User with works our business logic
//     private List<Opportunity> oppListToInsert = new List<Opportunity>();
//     private set<Id> orderIds;
//     private Id recordTypeEcommerce;
    
//     /*
// 		* bulkBefore
// 		*
// 		* This method is called prior to execution of a BEFORE trigger. Use this to cache
// 		* any data required into maps prior execution of the trigger.
// 	*/
//     public void bulkBefore(){}
    
//     /*
// * bulkAfter
// *
// * This method is called prior to execution of an AFTER trigger. Use this to cache
// * any data required into maps prior execution of the trigger.
// */
//     public void bulkAfter(){
//         if(Trigger.isInsert){
//             orderIds = Trigger.newMap.keySet();
//             recordTypeEcommerce = [SELECT Id FROM RecordType WHERE DeveloperName = 'Project_retail'].ID;
//         }
//     }
    
//     /**
// * beforeDelete
// *
// * This method is called iteratively for each record to be deleted during a BEFORE
// * trigger.
// */
//     public void beforeDelete(SObject so){}
    
//     /*
// * beforeInsert
// *
// * This method is called iteratively for each record to be inserted during a BEFORE
// * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
// */
//     public void beforeInsert(SObject so){}
    
//     /*
// * beforeUpdate
// *
// * This method is called iteratively for each record to be updated during a BEFORE
// * trigger.
// */
//     public void beforeUpdate(SObject oldSo, SObject so){}
    
//     /*
// * afterInsert
// *
// * This method is called iteratively for each record inserted during an AFTER
// * trigger. Always put field validation in the 'After' methods in case another trigger
// * has modified any values. The record is 'read only' by this point.
// */
//     public void afterInsert(SObject so){
//         Order newOrder = (Order) so;
//         Opportunity newOpp = OrderUtils.createEcommerceOpportunity(newOrder, recordTypeEcommerce);
//         if (newOpp != new Opportunity()) {
//             oppListToInsert.add( newOpp );
//         }
//     }
    
//     /*
// * afterUpdate
// *
// * This method is called iteratively for each record updated during an AFTER
// * trigger.
// */
//     public void afterUpdate(SObject oldSo, SObject so){}
    
//     /*
// * afterDelete
// *
// * This method is called iteratively for each record deleted during an AFTER
// * trigger.
// */
//     public void afterDelete(SObject so){}
    
//     /**
// * andFinally
// *
// * This method is called once all records have been processed by the trigger. Use this 
// * method to accomplish any final operations such as creation or updates of other records.
// */
//     public void andFinally(){
//         System.debug('oppListToInsert: ' + oppListToInsert);
//         try{
//             Insert oppListToInsert;
//         } catch(Exception ex){
//             System.debug('Order Trigger Exception: ' + ex.getMessage());
//         }
        
//         Map<Id, String> oppMap = new Map<Id, String>();
        
//         for(Opportunity opp: oppListToInsert){
//             // We get the Id of the Order or the Sap Order code
//             oppMap.put(opp.Id, opp.Name.substringAfter('#'));
//         }
//         List<Order> ordersToUpdate = [SELECT ID, Name, OrderNumber,SAP_Id__c, OpportunityId FROM Order WHERE Id IN : orderIds];
//         for(Order ord : ordersToUpdate ){
            
//             for(Id key: oppMap.keySet()){
                
//                 if(oppMap.get(key) == ord.OrderNumber || oppMap.get(key) == ord.SAP_Id__c){
//                     ord.OpportunityId = key;
//                 }
//             }
//         }
        
//         update ordersToUpdate;
        
//         System.Debug ('Order trigger executed');
        
//     }    
// }