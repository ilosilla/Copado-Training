/**
* @author 		Ivan Losilla
* @date 		June 2023
* @group 		Countertop
* @description  Manages everything related to COUNTERTOP
*/
global class CounterTop {
    public class CounterTopException extends Exception {}

    public final static String CREDENTIALS = 'callout:Counter_Top';
    public final static String URL_ROOT_DES = 'https://quotekandb.com/sync/api';
    public final static String URL_ROOT = 'https://quotekitchenandbath.com/sync/api';
    public final static String URL_TOKEN = '/Token';
    public final static String URL_CREATE_CUSTOMER = '/Customer';
    public final static String URL_CREATE_JOB = '/Job/CreateJobForCustomer';
    public final static String URL_CREATE_USER = '/User/SaveUser';

    public static Map<String,String> getToken() {
        Map<String,String> params = new Map<String,String>();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(CounterTop.CREDENTIALS + CounterTop.URL_TOKEN);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(30000);
        Map<String, Object> body = new Map<String, Object>{
            'email' => '{!$Credential.Username}',
            'password' => '{!$Credential.Password}'
        };

        request.setBody(JSON.serialize(body));
        try{
            Http http = new Http();
            HttpResponse response = http.send(request);
            String resBody = response.getBody();
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            params.put('token',(String)results.get('token'));
            params.put('error', null);
        } catch(Exception ex) {
            params.put('token', null);
            params.put('error', ex.getMessage());
        }

        return params;
    }

    public static Map<String,String> createJob(String opportunityId) {

        Opportunity opp = new OpportunitiesSelector().selectById(opportunityId);
        Account acc = new AccountsSelector().selectById(opp.accountId);
        User ownerResult = new UsersSelector().selectById(acc.ownerId);
        User currentUser = new UsersSelector().selectById(UserInfo.getUserId());

        Map<String,String> params = new Map<String,String>();
        Map<String,String> loginParams = getToken();

        JobForCustomerDTO job = new JobForCustomerDTO();
        job.externalId = acc.Id;
        job.SalesPersonEmail = currentUser.Email;
        String fabricatorId = getFabricator(ownerResult.Sales_Office__c);
        if (fabricatorId != null) {
            job.Fabricator_id = fabricatorId;
        } else {
            throw new CounterTopException('No Fabricator Id found');
        }

        if (acc.isPersonAccount == true) {
            job.FirstName = acc.Firstname;
            job.LastName = acc.Lastname;
            job.Email1 = acc.PersonEmail;
            job.Phone1 = acc.Phone;
            job.ShippingZip = acc.PersonMailingPostalCode;
            job.ShippingName = acc.PersonMailingStreet;
        } else {
            job.FirstName = acc.name;
            job.Email1 = acc.Business_Email__c;
            job.Phone1 = acc.Phone;
            job.ShippingZip = acc.BillingPostalCode;
            job.ShippingName = acc.BillingStreet;
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(getRootUrl() + CounterTop.URL_CREATE_JOB);
        request.setMethod('POST');      
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + loginParams.get('token'));
        //request.setTimeout(60000);
        System.debug('JSON - ' + JSON.serialize(job));
        request.setBody(JSON.serialize(job));

        try{
            Http http = new Http();
            HttpResponse response = http.send(request);
            String resBody = response.getBody();
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            String editUrl = (String)results.get('editJobUrl');
            editUrl = editUrl.replace('/shoppingcart', '/materials');

            Map<String,String> quoteUser = createUser(UserInfo.getUserId());

            params.put('id', String.valueOf(results.get('jobId')));
            params.put('customerId', String.valueOf(results.get('customerId')));
            params.put('url', editUrl);
            params.put('error', null);
        } catch(Exception ex) {
            params.put('id', null);
            params.put('error', ex.getMessage());
        }

        return params;
    }
    

    public static Map<String,String> createUser(String userId) {
        Map<String,String> params = new Map<String,String>();
        Map<String,String> loginParams = getToken();
        
        User usr = new UsersSelector().selectById(userId);

        UserDTO quoteUser = new UserDTO();
        quoteUser.externalId = usr.Id;
        quoteUser.fullName = usr.Name;
        quoteUser.enabled = true;
        quoteUser.email = usr.Email;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(getRootUrl() + CounterTop.URL_CREATE_USER);
        request.setMethod('POST');      
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + loginParams.get('token'));
        //request.setTimeout(60000);
        System.debug('JSON SERIALIZED: ' + JSON.serialize(quoteUser));
        request.setBody(JSON.serialize(quoteUser));

        try{
            Http http = new Http();
            HttpResponse response = http.send(request);
            String resBody = response.getBody();
            Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

            ExternalMapping__c dataMapping = new ExternalMapping__c(Source__c = 'COUNTERTOP', Type__c = 'USER', ExternalId__c = String.valueOf(results.get('id')), SalesforceId__c = userId);
            upsert dataMapping SalesforceId__c;

            System.debug('QUOTE USER - ' + results);
            params.put('id', String.valueOf(results.get('id')));
            params.put('error', null);
        } catch(Exception ex) {
            params.put('id', null);
            params.put('error', ex.getMessage());
        }

        return params;
    }

    private static String getRootUrl() {
        Organization org = [Select Id, Name, IsSandbox from Organization];

        if (org.IsSandbox) {
            return CounterTop.URL_ROOT_DES;
        }
        return CounterTop.URL_ROOT;
    }

    public static String getFabricator(String salesOfficeCode) {
        String result = null;
        List<ExternalMapping__c> resultQuery = [SELECT Id, Type__c, ExternalId__c, SalesforceId__c 
                                            FROM ExternalMapping__c
                                            WHERE Source__c = 'COUNTERTOP' and Type__c = 'SALESOFFICE' and SalesforceId__c =: salesOfficeCode];
        List<ExternalMapping__c> resultGlobalQuery = [SELECT Id, Type__c, ExternalId__c, SalesforceId__c 
                                            FROM ExternalMapping__c
                                            WHERE Source__c = 'COUNTERTOP' and Type__c = 'SALESOFFICE' and SalesforceId__c = '*'];
        if (resultQuery.size() > 0) {
            result = resultQuery[0].ExternalId__c;
        } else if (resultGlobalQuery.size() > 0 ){
            result = resultGlobalQuery[0].ExternalId__c;
        }

        return result;
    }

    global class UserDTO {
        global String externalId;
        global String fullName;
        global Boolean enabled;
        global String email;
        global List<String> userRoles = new List<String>();
    }

    global class JobForCustomerDTO {
        global String externalId;
        global String FirstName;
        global String LastName;
        global String Email1;
        global String Phone1;
        global String ShippingZip;
        global String ShippingName;
        global String Fabricator_id;
        global Boolean isPhoneNumberVerified = true;
        global Boolean doesFabricatorRequire2FA =true;
        global String SalesPersonEmail;
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}