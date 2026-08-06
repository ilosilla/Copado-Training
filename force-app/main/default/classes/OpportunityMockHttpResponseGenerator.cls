/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			03-04-2019
Description:    Mock Response Generator para los test que involucran la clase UpdateOpportunityActor
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/
@isTest
global class OpportunityMockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        System.debug('Body: ' + req.getBody());
        
        // Optionally, only send a mock response for a specific endpoint and method.
        HttpResponse res = new HttpResponse();
        
        // Para obtener los token y cookies necesarios al utilizar la clase SAPWS_Utility
        if ( req.getMethod().equals('GET') ){
            if(req.getEndpoint() == 'callout:SAP/api/customers/ping'){
            	res.setHeader('x-csrf-token', 'token churro');
            	res.setHeader('set-cookie', 'cookie churrito');
            	res.setStatusCode(200);
            	res.setHeader('Content-Type', 'application/json');
            }
        }
       	// Verifica que el en caso de estar enviando datos a sap estos tengan el formato apropiado
       	// Si todo esta bien retorna codigo 204 que correponde a un body vacio.
       	// Si el formato del body no es correcto se devuelve codigo 400 "bad input"
        if ( req.getMethod().equals('PUT') ){
            
            if( String.isBlank(req.getBody()) ){
                res.setStatusCode(400);
            } else {
                
                try{
                    Map<String, Object> sapWrapper = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
                    
                    // Si la oportunidad es nula o la lista de oportunity actors es nula o vacia se devuelve un codigo de error.
                    if(sapWrapper.get('opportunity') == null || sapWrapper.get('opportunityActorsList') == null ){
                           res.setStatusCode(400);
                       } else {
                           Map<String, Object> opp = (Map<String, Object>) sapWrapper.get('opportunity');
                           
                           if(opp.get('SalesOrg') == null || opp.get('Channel') == null){
                               res.setStatusCode(400);
                           } else {
                               res.setStatusCode(204);
                           }
                           
                       }
                    
                } catch (Exception ex){
                    System.debug('Opportunity Mock error: ' + ex.getMessage() );
                    res.setStatusCode(400);
                }
                
            } 
        }
        
        System.debug('MOCK res=> ' +res);
       	 
        return res;
    }
}