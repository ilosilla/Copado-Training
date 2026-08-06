/**
* @author 		Ramón Prades
* @date 		August 2021
* @group 		REST
* @description 	Generic web service to let external systems communicate events that change the state of salesforce objects. 
*               It is meant to simplfy the implementation of simple actions that aren't worth the development of a indivudual web service.
*/
@RestResource(urlMapping='/contactpointaddress/*')
global class RESTContactPointAddress {

    private static String fields = 'Id, AddressType, SAPId__c, Name, street, postalCode, city, stateCode, state, countryCode, country, ParentId, Parent.Name, Phone__c, Mobile__c, EMail__c, Disabled__c';

    @HttpGet global static void get () {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response; 
        
        String addressId = RESTContactPointAddress.getId(request.requestURI);        
        String sapId = '';    
         
        if (request.requestURI.ToLowerCase().contains('sapid')) {
            sapId = addressId;
            addressId = '';
        }
                
        response.statusCode = 200;        

        if (String.isNotBlank(addressId)) {
            String queryString = 'select ' + fields + ' from ContactPointAddress where Id = :addressId';
            ContactPointAddress[] address = Database.query(queryString);
            if (address.size() > 0 ) {
                String sjson = JSON.serialize(address[0]);
                response.addHeader('Content-Type', 'application/json');
                response.responseBody = Blob.valueOf(sjson);
            } else {
                response.statusCode = 404;
            }                
        } else if (String.isNotBlank(sapId)) {            
            String queryString = 'select ' + fields + ' from ContactPointAddress where SAPId__c = :sapId';
            ContactPointAddress[] address = Database.query(queryString);
            if (address.size() > 0 ) {
                String sjson = JSON.serialize(address[0]);
                response.addHeader('Content-Type', 'application/json');
                response.responseBody = Blob.valueOf(sjson);
            } else {
                response.statusCode = 404;
            }       
        } else {
            response.responseBody = Blob.valueOf('{"message":"Hi from ContactPointAddress rest service!"}');
        }
        
    } 

    /**
     * Creates or updates a contact point adddress
     * The json is like this one:
     * [{ "adress": {
     *   "Id": "8lW3N000000Cc2kUAC",
     *   "AddressType": "Shipping|Billing",
     *   "SAPId__c": "0005210326",
     *   "Name": "TEST ADDRESS CHANGED",
     *   "Street": "7 Boroline Road",
     *   "PostalCode": "07458",
     *   "City": "Saddle River",
     *   "StateCode": "NJ",    
     *   "CountryCode": "US",stret = 
     *   "ParentId": "0011x000017RzxBAAS",
     *   "Phone__c": "1323 1232",
     *   "Mobile__c": "6323 1232",
     *   "Email__c": "",
     *   "Disabled__c": false }]
     * }
     */
    @HttpPost global static void post (List<ContactPointAddress> addresses) {
        List<ContactPointAddress> result = new List<ContactPointAddress>();        
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;                
        try {
            for (ContactPointAddress address : addresses) {
                address = RESTContactPointAddress.updateAddressFromSAP(address);
                result.add(address);
            }
            upsert result;
            response.statusCode = 200;
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(JSON.serialize(result));                                
        } catch (ValidationException ex1) {
            RESTError error = new RESTError();
            error.errorCode = '400';
            error.message = ex1.getMessage();
            error.target = request.requestURI;
            response.statusCode = 400;
            response.addHeader('Content-Type', 'application/json');
            response.responseBody = Blob.valueOf(JSON.serialize(error));                                
        } 
    } // post

    /**
     * Syncronizes the addresses of an account
     *
     * URL: {{sforce-url}}/services/apexrest/contactpointaddress/account/<account_id>
     *
     * The json is:
     *
     * {
     *  "addresses": [{
     *       "addresstype": "D",
     *       "city": "Oxford",
     *       "countrycode": "GB",
     *       "customer": "0001088220",
     *       "email": "mara@bee.cxm",
     *       "name": "MARABESE",
     *       "phone": "111 222 111",
     *       "postalcode": "OX2 9NN",
     *       "sapid": "0001088220",
     *       "street": "9 Oxford Road",
     *       "street2": "Cumnor"
     *   }]
     *
     * 
     */
    @HttpPatch global static void patch (List<ContactPointAddress> addresses,  List<String> deletedId) {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;   
        String accountId = RESTContactPointAddress.getId(request.requestURI);        
        try {
            for (ContactPointAddress address : addresses) {
                address.parentId = accountId;
                address = RESTContactPointAddress.updateAddressFromSAP(address);
            }
            upsert addresses;
        if (deletedId != null) {
            RESTContactPointAddress.deleteAddressesFromSAP(deletedId);
        }
    } catch (ValidationException ex1) {
        RESTError error = new RESTError();
        error.errorCode = '400';
        error.message = ex1.getMessage();
        error.target = request.requestURI;
        response.statusCode = 400;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(JSON.serialize(error));                                
    } 

        response.statusCode = 200;
        response.addHeader('Content-Type', 'application/json');
        response.responseBody = Blob.valueOf(JSON.serialize(request.params));                                
    } // patch


    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static String getId(String uri) {
        String id = uri.substring(uri.lastIndexOf('/')+1);
        if (id.ToLowerCase() == 'contactpointadddress') {
            id = '';
        }
        return id;
    }
    
    /**
     * Validates and upserts a contact point address 
     */
    private static ContactPointAddress updateAddressFromSAP(ContactPointAddress address) {
        if (String.isBlank(address.Id) &&  String.isBlank(address.SAPId__c)) {
            throw new ValidationException('Required record id missing: Id or SAPId__c');
        }   
        if (String.isBlank(address.parentId)) {
            throw new ValidationException('Required field missing: parentId');
        }
        
        if (String.isBlank(address.Id)) {
            ContactPointAddress[] adr = [select Id from ContactPointAddress where SAPId__c = :address.SAPId__c];
            if (adr.size() > 0) {
                address.Id = adr[0].Id;
            }
        }
        if (GeoUtils.isDummyStateCode(address.CountryCode, address.StateCode)) {
            address.StateCode = '';
        }
        return address;
    }

    /**
     * Deletes contact point addresses
     */
    private static void deleteAddressesFromSAP(List<String> deletedIds) {
        
        if (deletedIds.size() > 0) {
            ContactPointAddress[] adrs = [select Id, SAPId__c from ContactPointAddress where SAPId__c = :deletedIds];
            for (ContactPointAddress adr :adrs) {
                adr.SAPId__c = '';
            }
            update adrs;
            delete adrs;
        }
    }

} // class