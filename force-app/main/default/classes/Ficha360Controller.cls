public class Ficha360Controller {
	private static final String SAP_PATH_2 = '/api/zcli/';
    private final static String SAP_PATH_3 = '/api/customers/ping';
    private static List<String> labelsAux_FirstCall, labelsAux_SecondCall;
    private static Object stateAux_FirstCall, stateAux_SecondCall;
    
    @AuraEnabled (cacheable=true)
    public static List<Map<String,String>> getSalesOrgs(String recordId){
        // Devuelve una lista de opciones de picklist de SalesOrgs filtradas por las salesOrg del usuario y de la cuenta (recordID)
		List<Map<String,String>> returnObject = new List<Map<String,String>>();
        
        Account acc = [SELECT SAP_Id__c FROM Account WHERE Id =: recordId];
        
        if( String.isBlank(acc.SAP_Id__c) ){
            Map<String,String> mapa = new Map<String,String>();
            mapa.put('ERROR', Label.Ficha360_Credit_Status_Unavaileble);
            returnObject.add(mapa);
            
        } else {
            String salesOrgText = [SELECT Sales_Org__c FROM User WHERE Id =: UserInfo.getUserId()].Sales_Org__c;
            List<Sales_Relationship__c> salesRelList = [SELECT Sales_Org__c FROM Sales_Relationship__c WHERE Account_Org__c =: recordId];
            
            Schema.DescribeFieldResult fieldResult = Sales_Relationship__c.Sales_Org__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            
            // Formatearlo para el componente.
            for( Schema.PicklistEntry pickListVal : ple){
                String pLValue = pickListVal.getValue();
                
                if( salesOrgText.contains( pLValue ) ){
                    for(Sales_Relationship__c salesRel : salesRelList){
                        if(pLValue == salesRel.Sales_Org__c){
                            Map<String,String> mapa = new Map<String,String>();
                            mapa.put('label', pickListVal.getLabel());
                            mapa.put('value', pickListVal.getValue());
                            returnObject.add(mapa);
                            break;
                        }
                    }
                }
            }
            
            if(returnObject.isEmpty()){
                Map<String,String> mapa = new Map<String,String>();
                mapa.put('ERROR', Label.Ficha360_SalesOrg_Mismatch);
                returnObject.add(mapa);
            }
            
        }
        
        System.debug('ple: ' + returnObject);
        
        return returnObject;
    }
    
    @AuraEnabled(continuation=true)
    public static Object getTableInfo(String recordId, String salesOrg) {
        labelsAux_FirstCall = null;
        stateAux_FirstCall = null;
        labelsAux_SecondCall = null;
        stateAux_SecondCall = null;
        
        // Busca el Sap Id y despues valida el input
        Account acc = [SELECT SAP_Id__c FROM Account WHERE Id =: recordId];
        
        if(acc.SAP_Id__c == null){
            return new SAPWS_Utility.SapResponse(false,null,Label.Ficha360_Credit_Status_Unavaileble,null,null,null);
        }
        
        if(String.isBlank(salesOrg)){
            return new SAPWS_Utility.SapResponse(false,null,Label.Ficha360_Select_a_Sales_Org,null,null,null);
        }
        
        // Ejecuta la request que busca el token y cookie de SAP
        // Pone a la funcion checkValidToken como callback, pone un timeout de 1 min y le pasa datos  al callback en state
        Continuation con = new Continuation(30);
        con.continuationMethod='checkValidToken';
        con.state= new List<String>{acc.SAP_Id__c, salesOrg};
        con.addHttpRequest(getParams());
        
        return con;
    }
    
    @AuraEnabled(continuation=true)
    public static Object checkValidToken(List<String> labels, Object state) {
        labelsAux_FirstCall = labels;
        stateAux_FirstCall = state;
        return checkValidToken();
    }
    
    
    // Callback para getTableInfo
    @AuraEnabled(continuation=true)
    public static Object checkValidToken() {
        
        // Obtiene la respues de la request, usa el indice 0 porque solo se hizo una request
        HttpResponse response = Continuation.getResponse(labelsAux_FirstCall[0]);
        
        Object responseObject;
        List<String> stateList = (List<String>) stateAux_FirstCall;
        
        Map<String,String> params = new Map<String,String>();
        params.put('token',response.getHeader('x-csrf-token'));
        params.put('cookie',response.getHeader('Set-Cookie'));

        if(params.get('token') == null || params.get('cookie') == null){
            // Si el token o el cookie no son validos retorna una respuesta con error
            String errorMessage = Label.Unexpected_Error + Label.Missing_Headers;             
            responseObject = new SAPWS_Utility.SapResponse(false,null,errorMessage,null,null,null);
            System.debug('errorMessage=> '+errorMessage);
            
        }else{
            // Si el token y coockie son validos entonces agrega el SAP Id y la Sales Org a los parametros de la proxima llamada
            params.put('salesOrg', stateList[1]);
            params.put('sapId', stateList[0]);
            
            // Invoca una segunda request para obtener los datos de la tabla 360
            Continuation con = new Continuation(75);
            con.continuationMethod='returnTableInfo';
            con.addHttpRequest( getRequest(params) );
            responseObject = con;
        }
        
        System.debug('responseObject: ' + responseObject);
        return responseObject;
    }
    
    @AuraEnabled
    public static Object returnTableInfo(List<String> labels, Object State) {
        labelsAux_SecondCall = labels;
        stateAux_SecondCall = state;
        return returnTableInfo();
    }
    
    // Callback para el request de los datos de la tabla
    @AuraEnabled
    public static Object returnTableInfo() {
        HttpResponse res = Continuation.getResponse(labelsAux_SecondCall[0]);
        Object responseObject;
        
        System.debug('code: '+res.getStatusCode()+' . Body: '+res.getBody());
        
        if (res.getStatusCode() >= 500) {
            String errorMessage = Label.Unexpected_Error + res.getStatusCode() + ' - ' + res.getStatus();
            
            if(res.getStatusCode() == 2000){
                errorMessage += '. \n' + Label.Ficha360_Timeout;
            }
            
            responseObject = new SAPWS_Utility.SapResponse(false,res.getStatusCode(),errorMessage,null,null,null);
            System.debug('code 50x errorMessage=> '+errorMessage);
        }else if(res.getStatusCode() != 200 && res.getStatusCode() != 201 && res.getStatusCode() != 204) {
            SAPWS_Utility.SapResponse sapResponse = (SAPWS_Utility.SapResponse)JSON.deserialize(res.getBody(), SAPWS_Utility.SapResponse.class);
            sapResponse.success = false;
            responseObject = sapResponse;
            System.debug('NOK errorMessage=> '+res.getStatusCode() + ' - ' + res.getStatus());
        }else{
            responseObject = new SAPWS_Utility.SapResponse(true,res.getStatusCode(),null,null,null,res.getBody());
        }
        
        System.debug('responseObject: ' + responseObject);
        return responseObject;
    }
    
    // Arma la request que solicita el Token y el cookie
    private static HttpRequest getParams(){
        System.debug('START getParams');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SAP'+SAP_PATH_3); // using named credentials
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-CSRF-Token', 'Fetch');
        System.debug('req => '+req);
        
        return req;
        
    }
    
    // Arma la request que solicita los datos de la tabla
    private static HttpRequest getRequest(Map<String, String> params){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SAP' + SAP_PATH_2 + params.get('salesOrg') + '?sap=' + params.get('sapId'));
        req.setMethod('GET');
        Map<String, String> body = new Map<String, String>{'language' => UserInfo.getLanguage()};
        req.setBody(JSON.serialize(body));

        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-CSRF-Token', params.get('token'));
        req.setHeader('cookie', params.get('cookie'));
        
        return req;
    }
 
}