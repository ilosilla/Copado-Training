/**
* @author 		Ivan Losilla
* @date 		June 2023
* @group 		OpportunityLink
* @description  Creates an OpportunityLink. Depending on the type, it's created on one way or another.
*/
@RestResource(urlMapping='/OpportunityLink/*')
global class RESTOpportunityLink {
    public class applicationException extends Exception {}

    @HttpGet global static void ping () {
        RestResponse res = RestContext.response;
        res.statusCode = 200;
        res.responseBody = Blob.valueOf('{"hola":"mundo"}');
    }

    @HttpPost global static void create () {
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        String bodyString = body.toString();
        OpportunityLinkDTO oppLink = parseOpportunityLink(bodyString);
        switch on oppLink.type {
            when 'TILEPLANNER' {
                TilePlanner.create(oppLink);
            }
        }
    }

    private static OpportunityLinkDTO parseOpportunityLink(String jsonString) {
        OpportunityLinkDTO oppLink = new OpportunityLinkDTO();
        try {
            oppLink = (OpportunityLinkDTO) JSON.deserializeStrict(jsonString , OpportunityLinkDTO.class);
        } catch(Exception e) {
            e.setMessage('ERROR - Invalid JSON OpportunityLink: ' + e.getMessage());
            throw e;
        }

        return oppLink;
    } // parseGoogleLead

    global class OpportunityLinkDTO { 
        global String name;
        global String externalId;
        global Id opportunityId;
        global String value1;
        global String type;
    } // class OpportunityLinkDTO
}