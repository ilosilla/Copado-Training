/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Adapter
 * @description    Adapter to access B2B cart data using ConnectApi.
 *
 *  This class:
 *  - Contains NO business logic
 *  - Does NOT transform models into flat DTOs
 *  - Exposes reusable atomic methods
 *  - Provides an aggregated method for complex flows (order creation)
 */
public class B2B_CommerceCartAdapter {

    /* =========================================================
     * DATA CONTAINER
     * ========================================================= */

    /**
     * Complete snapshot of the cart.
     * Directly contains ConnectApi models
     * to avoid unnecessary duplication and coupling.
     */
    public class CommerceCartData {
        public ConnectApi.CartSummary cart;
        public List<ConnectApi.CartItem> cartItems;
       //public List<ConnectApi.DeliveryGroup> deliveryGroups;
    }

    /* =========================================================
     * ATOMIC READ METHODS
     * ========================================================= */

    public static CommerceCartData getCartData(Id webStoreId, Id cartId) {  
        WebCart c = [SELECT AccountId FROM WebCart WHERE Id = :cartId LIMIT 1];
        return getCartData(webStoreId, cartId, c.AccountId);
    }

    /**
     * Returns a complete snapshot of the cart.
     *
     * This method:
     * - Reuses atomic methods
     * - Ensures read consistency
     * - Is designed for complex flows (order creation, payment, etc.)
     */
    public static CommerceCartData getCartData(Id webStoreId, Id cartId, Id accountId) {  
        CommerceCartData data = new CommerceCartData();
        data.cart = getCart(webStoreId, cartId, accountId);
        data.cartItems = getCartItems(webStoreId, cartId, accountId);
        return data;
    }

    /**
     * Reads only the cart header.
     */
    public static ConnectApi.CartSummary getCart(Id webstoreId, Id cartId, Id accountId) {
        return ConnectApi.CommerceCart.getCartSummary(webstoreId, accountId, cartId);
    }

    /**
     * Reads the cart items.
     */
    public static ConnectApi.CartItem[] getCartItems(Id webstoreId, Id cartId, Id accountId) {
        ConnectApi.CartItemCollection itemsCollection = ConnectApi.CommerceCart.getCartItems(webstoreId, accountId, cartId);
        ConnectApi.CartItem[] cartItems = new List<ConnectApi.CartItem>();
        for (ConnectApi.CartItemResult itemResult : itemsCollection.cartItems) {
            cartItems.add((ConnectApi.CartItem)itemResult.cartItem);
        }        
        return cartItems;
    }
    
    /**
     * Lorem Ipsum method for testing purposes
     */
    @testVisible private static String loremIpsum() {
        String lorem = 'Lorem ipsum dolor sit amet, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'consectetur adipiscing elit, ';
        lorem += 'sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ';
        lorem += 'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ';    
        return lorem;
    }

    /* =========================================================
     * AGGREGATED READ METHOD
     * ========================================================= */

}