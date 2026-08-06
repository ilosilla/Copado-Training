/**
* @author 			Ivan Losilla
* @date 			November-2022
* @group 			Mailchimp
* @description 	    Manage the Mailchimp API.
*                   To use Mailchimp, we configure named credentials, each of one is set with the url to mailhcimp,
*                   and the TOKEN API of mailchimp, is set on the password field on the named credential.
*                   ! The TOKEN needed to use the API is set as the password on the name credential. The trick here: 
*                   https://salesforce.stackexchange.com/questions/217281/use-a-named-credential-with-api-key/217282#217282
*                   ? How to check the API Key on Mailchimp: https://tinyurl.com/44z9ae45
*                   It should be set on Porcelanosa Settings with the namedCredential name on value1 and the listId on value2.
*/

public class MailChimpHelper {
    private protected Integer TIMEOUT = 60000;
    
    private String namedCredential;
    public String id {get; private set; }
    public string listId {get; private set; }
    public String email;
    public String status;
    public String firstname = '';
    public String lastname = '';
    public String phone = '';
    public String language = 'en'; // accepted codes : https://mailchimp.com/es/help/view-and-edit-contact-languages/

    public MailChimpHelper(String email, String context) {

        Organization org = [Select Id, Name, IsSandbox from Organization];

        try {
            if (org.IsSandbox ) {
                context = 'DES';
            }
            PorcelanosaSetting setting = new PorcelanosaSetting('MAILCHIMP', context);
            if (setting.isActive == false) {
                throw new CallOutException('Setting no active');
            }
            this.namedCredential = setting.value1;
            this.listId = setting.value2;
            readFromEmail(email);
        } catch (Exception ex) {
            Logger.setScenario('SET MAILCHIMP CONFIG');
            Logger.error('Message: ' + ex.getMessage());
            Logger.saveLog();
        }
    }

    /**************** PUBLIC METHODS *******************/


    /* @description Given an email, search if the member exists on the mailchimp's list set */
    public void readFromEmail(String email) {
        try {
            if (canConnect()) {
                HttpResponse response = readFromEmailCall(email, this.listId, this.namedCredential, this.TIMEOUT);
                Integer statusCodeResponse = response.getStatusCode();
                
                switch on statusCodeResponse {
                    when 200 {
                        Map < String, Object > resultsMap = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                        Map<String,Object> exactMatches = (Map<String,Object>) resultsMap.get('exact_matches');
                        List<Object> members = (List<Object>) exactMatches.get('members');
                        Integer totalItems = (Integer) exactMatches.get('total_items');
                        if (totalItems == 1) {
                            parseFindResponse((Map<String,Object>)members[0]);
                        }
                    }
                }
            }
            this.email = email;
        } catch (Exception ex) {
            Logger.setScenario('FIND MAILCHIMP MEMBER');
            Logger.error('Message: ' + ex.getMessage());
            Logger.saveLog();
        }
    }
    
    /* @description Inserts a new member on the list */
    public Boolean insertMember() {
        try {
            if (canConnect()) {
                HttpResponse response = insertMemberCall(this.listId, this.namedCredential, this.timeout);
                Integer statusCodeResponse = response.getStatusCode();
                switch on statusCodeResponse {
                    when 200 {
                        Map < String, Object > resultsMap = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                        this.id = (String) resultsMap.get('id');
                        return true;
                    }
                }
            }
        } catch (Exception ex) {
            Logger.setScenario('INSERT MAILCHIMP MEMBER');
            Logger.error('Message: ' + ex.getMessage());
            Logger.saveLog();
        }
        return false;
    }
    
    /* @description Updates a new member on the list */
    public Boolean updateMember() {
        try {
            if (String.isNotBlank(this.id) && canConnect()) {
                HttpResponse response = updateMemberCall(this.listId, this.namedCredential, this.timeout);
                Integer statusCodeResponse = response.getStatusCode();
        
                switch on statusCodeResponse {
                    when 200 {
                        return true;
                    }
                }
            }
        } catch (Exception ex) {
            Logger.setScenario('UPDATE MAILCHIMP MEMBER');
            Logger.error('Message: ' + ex.getMessage());
            Logger.saveLog();
        }
        return false;
    }

    /* @description Parses the response qhen searching for an email on a list */
    private void parseFindResponse(Map<String,Object> jsonData) {
        try {
            this.id = (String) jsonData.get('id');
            this.email = (String) jsonData.get('email_address');
            this.listId = (String) jsonData.get('list_id');
            this.status = (String) jsonData.get('status');
            this.language = (String) jsonData.get('language');
            
            Map<String,Object> personData = (Map<String,Object>)jsonData.get('merge_fields');
            this.firstname = (String) personData.get('FNAME');
            this.lastname = (String) personData.get('LNAME');
            this.phone = (String) personData.get('PHONE');
        } catch (Exception ex) {
            Logger.setScenario('PARSE MAILCHIMP RESPONSE');
            Logger.error('Message: ' + ex.getMessage());
            Logger.saveLog();
        }
    }

    /* @description Checks if we have the data needed to connect to the API */
    private Boolean canConnect() {
        return (String.isNotBlank(this.namedCredential) && String.isNotBlank(this.listId));
    }

    // ****************** CALLOUTS *********************//

    // API Info: https://mailchimp.com/developer/marketing/api/search-members/search-members/
    public HttpResponse readFromEmailCall(String email, String listId, String namedCredential, Integer timeout) {
        String fieldsToGet='exact_matches.members.id,exact_matches.members.language,exact_matches.members.email_address,exact_matches.members.status,exact_matches.members.tags,exact_matches.members.merge_fields.fname,exact_matches.members.merge_fields.lname,exact_matches.members.list_id,exact_matches.total_items';
        String url = 'callout:' + namedCredential + '/search-members?query=' + email + '&list_id=' + listId + '&fields=' + fieldsToGet;
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setTimeout(timeout);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'multipart/form-data');
        req.setHeader('Authorization',  'Bearer {!$Credential.Password}' );
        HttpResponse response = h.send(req);
        return response;
    }

    // API Info: https://mailchimp.com/developer/marketing/api/list-members/add-member-to-list/
    public HttpResponse insertMemberCall(String listId, String namedCredential, Integer timeout) {
        String url = 'callout:' + namedCredential + '/lists/' + listId + '/members';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setTimeout(timeout);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization',  'Bearer {!$Credential.Password}' );
        Map<String, String> mergedFields = new Map<String, String>{'FNAME' => this.firstname,
                                                                    'LNAME' => this.lastname,
                                                                    'PHONE' => this.phone };
        Map<String, Object> body = new Map<String, Object>{
                                            'email_address' => this.email,
                                            'status' => this.status,
                                            'language' => this.language,
                                            'merge_fields' => mergedFields};
        req.setBody(JSON.serialize(body));
        HttpResponse response = h.send(req);
        return response;
    }

    // API Info: https://mailchimp.com/developer/marketing/api/list-members/update-list-member/
    public HttpResponse updateMemberCall(String listId, String namedCredential, Integer timeout) {
        String url = 'callout:' + namedCredential + '/lists/' + listId + '/members/' + this.id;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setTimeout(timeout);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization',  'Bearer {!$Credential.Password}' );
        Map<String, String> mergedFields = new Map<String, String>{'FNAME' => this.firstname,
                                                                    'LNAME' => this.lastname,
                                                                    'PHONE' => this.phone };
        Map<String, Object> body = new Map<String, Object>{'status' => this.status,
                                                            'language' => this.language,
                                                            'merge_fields' => mergedFields};
        req.setBody(JSON.serialize(body));
        HttpResponse response = h.send(req);
        return response;
    }

    
}