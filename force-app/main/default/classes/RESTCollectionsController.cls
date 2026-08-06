/**
 * @author         Ramón Prades
 * @date           October 2023
 * @description    REST OpenAPI controller (no auth required)
*/

@RestResource(urlMapping='/openapi/v1/collection/*')
global class RESTCollectionsController {

    @HttpGet 
    global static void approve() {
        // Use a GET because this is going to be invoed from a link in an email
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;        
        String caseId = URLCommons.getURLId(req.requestURI);
        Map<string, String> params = req.params;
        String approvedBy = params.get('approvedBy');

        if (String.isBlank(approvedBy)) {
            res.statusCode = 400;            
            res.responseBody = Blob.valueOf('Missing parameter "approvedBy"');
            return;
        }

        try {
            SAPCasesService.approveCollection((Id)caseId, (Id)approvedBy);
            res.statusCode = 204;    
        /*} catch(ObjectNotFoundException onf) {
            res.statusCode = 400;            
            res.responseBody = Blob.valueOf(onf.getMessage());*/
        } catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(ex.getMessage() );
        }        
    }
}