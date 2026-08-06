@isTest public class NB2B_CheckoutGenericTest {
    @isTest public static void PricingFailed() {
        try{
            NB2B_Pricing.syncPricing(null);
        }catch(Exception e){
            System.assertEquals(e.getMessage(), 'A cart id must be included to B2BSyncPricing');
        }
    }
    
    @isTest public static void NB2B_ConfirmPriceFailed() {
        try{
            NB2B_ConfirmPrice.syncPricing(null);
        }catch(Exception e){
            System.assertEquals(e.getMessage(), 'A cart id must be included to NB2B_ConfirmPrice');
        }
    }
    @isTest public static void NB2B_GenericCheckoutStepFailed() {
        try{
            NB2B_GenericCheckoutStep.syncPricing(null);
        }catch(Exception e){
            System.assertEquals(e.getMessage(), 'A cart id must be included to Generic Checkout Class');
        }
    }
    
}