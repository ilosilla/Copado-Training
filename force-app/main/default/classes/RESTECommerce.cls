/**
* @author 			Ramón Prades
* @date 			October-2020
* @group 			ECommerce
* @group-content 	../../ApexDocContent/ecommerce.htm
* @description 	    REST service to create an ECommerce Opportunity
*/
@RestResource(urlMapping='/ecommerce/samples/*')
global class RESTECommerce {

    @HttpGet global static void ping () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"hola":"mundo"}');
    }

    @HttpPost global static Opportunity create (Order order) {
        RestResponse response = RestContext.response;        
        Opportunity opp = null;
        try {
            opp = createSamplesOpportunity(order);
            response.statusCode = 201;
        } catch (ObjectExistsException ex) {
            response.statusCode = 409;
            response.responseBody = Blob.valueOf('Opportunity linked to sap order #' + order.Sap_Id__c + ' already exists!');                                
        }
        return opp;
    } // create

    @HttpPatch global static void changeStatus (Order order) {
        RestResponse response = RestContext.response;        
        try {
            response.statusCode = 200;
        } catch (ObjectNotFoundException ex) {
            response.statusCode = 409;
            response.responseBody = Blob.valueOf('Opportunity linked to sap order #' + order.Sap_Id__c + ' not found!');                                
        }        
    } // create


    /****************************************************************************************/        

    private static Opportunity createSamplesOpportunity(Order order) {
        ECommerceOpportunity eco = new ECommerceOpportunity(order);
        Opportunity opp = eco.getOpportunity();
        if (eco.ownerChanged) {
            update eco.account;
        }
        insert opp;
        return opp;
    } // createSamplesOpportunity        
} // class