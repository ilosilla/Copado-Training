/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Commons
 * @description    Order common utility methods
 * ---
 * Version 1.0.0
 */
public class OrderCommons {
    
    public static Boolean isCollection(Order o) {
        return (o.Type == OrdersDomain.FREE_COLLECTION_TYPE || o.Type == OrdersDomain.COLLECTION_TYPE);
    }
    
}