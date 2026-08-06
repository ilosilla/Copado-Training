/**
 * @author         Ramón Prades
 * @date           September 2023
 * @group          Orders
 * @description    Order Delivery Groups Selector
 */
public without sharing class OrderDeliveryGroupsSelector extends zflib_SObjectSelector_v2 {
    
    public override String getTypeName() {
        return 'OrderDeliveryGroup';
    }    

    public OrderDeliveryGroup selectByOrderId(Id orderId){
        List<OrderDeliveryGroup> groups = selectByOrderId(new Set<Id>{orderId});
        return groups.isEmpty() ? null : groups[0];
    }

    public List<OrderDeliveryGroup> selectByOrderId(Set<Id> orders){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('OrderId IN :orders');
        return (List<OrderDeliveryGroup>) Database.query(query.toSOQL());
    }

    public override String getOrderBy(){
        return 'OrderId';
     }
}