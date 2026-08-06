/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Orders Selector 
*/
public class OrdersSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'Order';
    }

    protected override Set<String> getExcludedFields() {
        return new Set<String>{'ordermanagementreferenceidentifier'};
    }

    public List<Order> selectBySAPOrder(Set<String> sapNumbers){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Sap_Id__c IN :sapNumbers');
        return (List<Order>) Database.query( query.toSOQL() );
     }

}