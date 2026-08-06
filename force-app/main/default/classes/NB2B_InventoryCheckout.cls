/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_InventoryCheckout
     Created Date:      16/02/2022
     Author:            Ignacio G. Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Inventory calculation not necessary yet
------------------------------------------------------------------------------------------*/
// This class verifies that there is sufficient inventory to cover the buyer's order
global with sharing class NB2B_InventoryCheckout {
    // This invocable method only expects one ID
    @InvocableMethod(callout=true label='Ensure sufficient inventory' description='Runs a synchronous version of check inventory' category='B2B Commerce')
    public static void syncCheckInventory(List<ID> cartIds) {
        System.debug('NB2B_InventoryCheckout syncCheckInventory starts');
        // Validate the input
        if (cartIds == null || cartIds.size() != 1) {
            String errorMessage = 'A cart id must be included to B2BSyncCheckInventory';
            // Sync non-user errors skip saveCartValidationOutputError
            throw new IllegalArgumentException (errorMessage);
        } 
    }
}