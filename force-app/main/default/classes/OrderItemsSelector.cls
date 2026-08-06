/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Orders Items Selector
 */
public class OrderItemsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'OrderItem';
    }    

    public List<OrderItem> selectByOrderId(Id orderId){
        return this.selectByOrderId(new Set<Id>{ orderId });
    }

    public List<OrderItem> selectByOrderId(Set<Id> orders){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('OrderId IN :orders');
        return (List<OrderItem>) Database.query(query.toSOQL());
    }

    protected override Set<String> getExcludedFields() {
        return new Set<String>{'reservedatlocationid'};
    }
    
    public override String getOrderBy(){
        return 'OrderId, LineNumber';
     }
    
}