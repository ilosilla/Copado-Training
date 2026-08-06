@isTest public class NB2B_InventoryCheckoutTest {
	
    @isTest private static void syncCheckInventory() {
        try{
            NB2B_InventoryCheckout.syncCheckInventory(null);
        }catch(Exception e){
            System.assertEquals('A cart id must be included to B2BSyncCheckInventory', e.getMessage());
        }
    }
}