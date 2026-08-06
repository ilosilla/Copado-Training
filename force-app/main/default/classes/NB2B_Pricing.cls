/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_Pricing
     Created Date:      16/02/2022
     Author:            Ignacio G. Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Pricing calculation not necessary yet
------------------------------------------------------------------------------------------*/
public  with sharing class NB2B_Pricing {
    // This invocable method only expects one ID
    @InvocableMethod(callout=true label='Price the cart' description='Runs a synchronous version of pricing' category='B2B Commerce')
    public static void syncPricing(List<ID> cartIds) {
        // Clase para validar precios a través de servicios externos
        if (cartIds == null || cartIds.size() != 1) {
            String errorMessage = 'A cart id must be included to B2BSyncPricing'; // Get wording from doc!!!
            // Sync non-user errors skip saveCartValidationOutputError
            throw new CalloutException (errorMessage);
        }
    }
}