/**
 * @author         Ramón Prades
 * @date           August 2024
 * @layer          Domain
 * @description    Order Item domain class
*/
public class OrderItemsDomain extends zflib_TriggerDomainClass {
    
    public OrderItemsDomain() {
        super();
    }

    public OrderItemsDomain(List<OrderItem> items) {
        super(items);
    }

    public override zflib_TriggerDomainClass cast() {
        return (OrderItemsDomain) this;
    } 

    public override Type getSObjectType() {
        return OrderItemsDomain.class;
    }

} // class