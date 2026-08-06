/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Orders Selector 
*/
public class PaymentRequestsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'PaymentRequest__c';
    }

    public PaymentRequest__c selectByCartId(Id cartId){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('CartId__c = :cartId');
        PaymentRequest__c[] results = (List<PaymentRequest__c>) Database.query(query.toSOQL());
        if (results.isEmpty()) {
            return null;
        }
        return results[0];
     }

    public PaymentRequest__c selectByToken(String token){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Token__c = :token');
        PaymentRequest__c[] results = (List<PaymentRequest__c>) Database.query(query.toSOQL());
        if (results.isEmpty()) {
            return null;
        }
        return results[0];
     }

}