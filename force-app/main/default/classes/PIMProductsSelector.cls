/**
 * @author         Ramón Prades
 * @date           November 2025
 * @layer          Selector
 * @description    Selector para acceso a PIMProduct__c
*/
public class PIMProductsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'PIMProduct__c';
    }

     public List<PIMProduct__c> selectByProductId(Set<Id> productIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Product__c IN :productIds');
        return (List<PIMProduct__c>) Database.query( query.toSOQL() );
     }

}