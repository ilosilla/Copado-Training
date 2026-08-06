/**
* @author 			Ramón Prades
* @date 			March 2021
* @group 			API
* @description 	    REST service to attach fiels to a SObject
*/
@RestResource(urlMapping='/oattachments/*')
global class RESTOAttachments {

    @HttpGet global static void get () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"rest-service":"oattachments service up and running!"}');
    } // get

    @HttpPost global static void post (List<OAttachmentDTO> files) {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        try {            
            OAttachmentsService.createAttachments(files);
            response.statusCode = 204;            
        } catch (Exception ex) {
            RESTError[] errors = new List<RESTError>();
            RESTError error = new RESTError(ex);
            error.target = request.requestURI;
            errors.add(error);
            response.statusCode = 400;
            response.addHeader('Content-Type', 'application/json');     
            response.responseBody = Blob.valueOf(JSON.serialize(errors));   
        }
    } // post

} // class