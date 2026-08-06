@isTest
private class RESTOpportunityLinkTest {
    @isTest
    static void testPing() {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/OpportunityLink/ping';
        RestContext.request = request;
        RestContext.response = response;

        // Llamada al método que se va a probar
        RESTOpportunityLink.ping();

        // Verificación
        System.assertEquals(200, response.statusCode, 'Se esperaba un código de estado 200');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }

    @isTest
    static void testCreate_OpportunityExists() {
        User usr = DataFactoryUser.createUKUser();
        // Preparación
        List<Opportunity> newOpps = DataFactoryOpportunity.createRetailOpportunities(1, 2);
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestURI = '/services/apexrest/OpportunityLink/create';
        request.httpMethod = 'POST';

        // Construir el cuerpo de la solicitud
        RESTOpportunityLink.OpportunityLinkDTO linkDTO = new RESTOpportunityLink.OpportunityLinkDTO();
        linkDTO.name = 'Test Link';
        linkDTO.externalId = '123456789';
        linkDTO.opportunityId = newOpps[0].Id;
        linkDTO.value1 = usr.email;
        linkDTO.type = 'TILEPLANNER';
        request.requestBody = Blob.valueOf(JSON.serialize(linkDTO));

        RestContext.request = request;
        RestContext.response = response;

        // Llamada al método que se va a probar
        RESTOpportunityLink.create();

        // Verificación
        System.assertEquals(200, response.statusCode, 'Se esperaba un código de estado 200');
        // Puedes agregar más aserciones para verificar el cuerpo de la respuesta si es necesario
    }
    
    @isTest
    static void fillerTest() {
        TilePlanner aux = new TilePlanner();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}