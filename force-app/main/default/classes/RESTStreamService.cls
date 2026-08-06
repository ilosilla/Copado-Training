/**
* @author 			Ramón Prades
* @date 			March 2021
* @group 			API
* @description 	    REST service to receive and process a text stream
*/
@RestResource(urlMapping='/stream/*')
global class RESTStreamService {

    @HttpGet global static void get () {
        RestResponse response = RestContext.response;        
        response.statusCode = 200;
        response.responseBody = Blob.valueOf('{"rest-service":"stream-service up and running!"}');
    } // get

    @HttpPost global static void post (StreamDTO stream) {
        SystemLog logger = new SystemLog('REST-STREAM');
        RestResponse response = RestContext.response;        
        Type parserType = Type.forName(stream.agent);
        try {
            logger.addInfo('Stream Process Requested');
            logger.setInputData(JSON.serializePretty(stream));
            AbstractStreamParser parser = (AbstractStreamParser) parserType.newInstance();
            parser.content = stream.content;
            parser.fileName = stream.fileName;
            parser.parentId = stream.parentId;    
            parser.parse();
            String jsonResult = parser.execute();
            response.responseBody = Blob.valueOf(jsonResult);   
            response.statusCode = 200;
            logger.addInfo('Stream processed succesfully');
        } catch (Exception ex) {
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('[RESTStreamService] ERROR: ' + ex.getMessage());   
            logger.addError(ex);
        }
        logger.saveLog(true);
    } // post

    global class StreamDTO { 
        global String fileName;
        global String agent;
        global String parentId;
        global String content;
    }

} // class