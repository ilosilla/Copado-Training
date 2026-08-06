/**
 * @author         Ramón Prades
 * @date           August 2024
 * @layer          Services
 * @description    Order Item service layer
*/
public class OrderItemsService {
    
    /**
     * Deletes a list of items
     */
    public static List<OrderItem> deleteItems(List<OrderItem> items) {        
        List<OrderItem> listToDelete = new List<OrderItem>();
        if (items != null) {
            // If the items are more than one, and the first item has an Id, it means that the items were queried from the database
            for (OrderItem item : items) {
                if (item.Id != null && item.OrderId != null) {
                    listToDelete.add(item);
                }
            } 
            delete listToDelete;
        }
        return listToDelete;           
    }

} // class