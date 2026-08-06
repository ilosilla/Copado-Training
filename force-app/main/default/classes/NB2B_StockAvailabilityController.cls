/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_StockAvailabilityController
     Created Date:      03/05/2022
     Author:            Ignacio Galindo Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Class to call stock´s WS to show in aura component
------------------------------------------------------------------------------------------*/
public class NB2B_StockAvailabilityController {
	@AuraEnabled
    public static StockWrapper checkStock(String recordId, String salesOrg){
        System.debug('NB2B_StockAvailabilityController checkStock start');
        StockWrapper wrapper = new StockWrapper();
        NB2B_StockCallOutManager stockManager;
        try{
            if(recordId != null && salesOrg != null){
                Product2 prod = [Select id, StockKeepingUnit from Product2 where id=:recordId Limit 1];
                stockManager = new NB2B_StockCallOutManager(prod.StockKeepingUnit,salesOrg );
                wrapper.responseStock = stockManager.getCallout();
                if(wrapper.responseStock != null){
                    wrapper.isCorrect = true;
                }
            }else{
                wrapper.isCorrect = false;
            }
            
        }catch(Exception e){
           System.debug('NB2B_StockAvailabilityController checkStock Exception :' + e); 
           wrapper.isCorrect = false;
           return wrapper;
        }
        System.debug('NB2B_StockAvailabilityController checkStock return'); 
        return wrapper;
    }
    
    public class StockWrapper{
        @AuraEnabled 
        public Boolean isCorrect;
        @AuraEnabled 
        public List <NB2B_StockCallOut.NB2B_StockCallOutResponse> responseStock;
    }
}