public with sharing class NB2B_StockCallOutManagerHelper {
    
    public static void nebulaError(String messageError){
        Logger.error('The callout has failed due to the error: ' + messageError);
        Logger.saveLog();
    }
}