/**
* @author 			Ramón Prades
* @date 			November-2020
* @group 			SAP
* @group-content 	../../ApexDocContent/Accounts.htm
* @description 	    Class to connect to a web service in SAP
*/
public without sharing class SAPConnection {

    public final static String OPPORTUNITIES_SERVICE = '/api/opportunities';
    public final static String CUSTOMERS_SERVICE = '/api/customers';
    public final static String SALES_DOCUMENTS_SERVICE = '/api/salesdoc';    
    private final static String CREDENTIALS = 'callout:SAP';
    public final static String URL_TOKEN = '/api/customers/ping';    

    private String service;
    private String objectId;
    private String method;

    public void setService(String service) {
        this.service = service;
    }

    public void setObjectId(String objectId) {
        this.objectId = objectId;
    }


}