/**
 * @author         Ramón Prades
 * @date           October 2025
 * @layer          System Utilities
 * @description    Access the process receipt
 * 
 * *TEST WITH SYS_ProcessReceiptsTest*
 * 
*/
public class SYS_ProcessReceiptsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'SYS_ProcessReceipt__c';
    }

    public SYS_ProcessReceipt__c[] selectByKey(Set<String> keys){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('key__c in :keys');
        return  Database.query(query.toSOQL());
    }

}