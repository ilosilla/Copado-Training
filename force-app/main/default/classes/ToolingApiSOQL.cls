public class ToolingApiSOQL{
    
    public static String restGet(String endPoint, String method, String sessionId){
        Http h = new Http();
        HttpRequest hr = new HttpRequest();
        hr.setTimeout(60000);
        hr.setEndpoint('callout:SFToken' + endPoint);
        hr.setMethod(method);
        HttpResponse r = h.send(hr);
        return r.getBody();
    }
    
    public static String toolingAPISOQL(String query){
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return restGet( '/services/data/v41.0/tooling/query?q=' + (query.replace(' ', '+'))
                       ,
                       'GET', UserInfo.getSessionId());
    }
    
    public static String getLayoutNameForCurrentUserProfile(Id recordId, String recordTypeId){
        // Cambio 21/08/19: Si el parametro recordTypeId es nulo entonces se toma el record type id de la cuenta.
        // Esto es para poder mostrar un layout distinto al layout actual que tiene la cuenta para el cambio record Type
        String recTypeId = String.isEmpty(recordTypeId) ? [SELECT RecordTypeId FROM Account WHERE Id = :recordId].RecordTypeId : recordTypeId;
        String body = toolingAPISOQL('SELECT Layout.Name FROM ProfileLayout WHERE ProfileId = \'' + UserInfo.getProfileId() + '\' AND RecordTypeId = \'' + recTypeId + '\'');
        System.debug(LoggingLevel.ERROR, '@@@ v: ' + body );
        String name = body.substringBetween('"Name":"', '"');
        //System.debug(LoggingLevel.ERROR, '@@@ v: ' + name );
        System.debug('name ' + name);
        return name;
    }
    
}