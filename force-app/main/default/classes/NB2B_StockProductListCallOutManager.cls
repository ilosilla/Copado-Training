public with sharing class NB2B_StockProductListCallOutManager {
    
    private List<String> productCodeList;
    private String salesOrganization;

    public NB2B_StockProductListCallOutManager(List<String> productCodeList,String salesOrganization) {
        this.productCodeList = productCodeList;
        this.salesOrganization = salesOrganization;
    }
	@AuraEnabled
    public List <NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse> getCallout(){
        System.debug('NB2B_StockProductListCallOutManager getCallout');
        List <NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse> response;
        NB2B_StockProductListCallOut call = new NB2B_StockProductListCallOut(productCodeList,salesOrganization);

        try{
            response = call.callOut();
            System.debug('NB2B_StockProductListCallOutManager response: '+response);
        }catch(Exception e){
            System.debug('NB2B_StockProductListCallOutManager error: '+e.getMessage());
            NB2B_StockCallOutManagerHelper.nebulaError(e.getMessage());
        }
        return response;
    }

}