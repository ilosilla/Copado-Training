public with sharing class NB2B_StockCallOutManager {
    
    private String productCode;
    private String salesOrganization;

    public NB2B_StockCallOutManager(String productCode,String salesOrganization) {
        this.productCode=productCode;
        this.salesOrganization=salesOrganization;
    }
	@AuraEnabled
    public List <NB2B_StockCallOut.NB2B_StockCallOutResponse> getCallout(){
        
        List <NB2B_StockCallOut.NB2B_StockCallOutResponse> response;
        NB2B_StockCallOut call= new NB2B_StockCallOut(productCode,salesOrganization);

        try{
            response = call.callOut();
        }catch(Exception e){
            NB2B_StockCallOutManagerHelper.nebulaError(e.getMessage());
        }
        return response;
    }

}