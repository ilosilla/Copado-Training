public  with sharing class NB2B_GenericCheckoutStep {
    
    @InvocableMethod(callout=true label='Generic Checkout Class' description='Runs a synchronous' category='B2B Commerce')
    public static void syncPricing(List<ID> cartIds) {
        System.debug('NB2B_GenericCheckoutStep syncPricing start');
        // Clase para validar precios a través de servicios externos
        if (cartIds == null || cartIds.size() != 1) {
            String errorMessage = 'A cart id must be included to Generic Checkout Class'; // Get wording from doc!!!
            // Sync non-user errors skip saveCartValidationOutputError
            throw new CalloutException (errorMessage);
        }
    }
}