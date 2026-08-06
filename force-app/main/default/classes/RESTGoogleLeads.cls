/**
* @author 		Ramón Prades
* @date 		November 2022
* @group 		Leads
* @description  Creates a lead from a google ad. See more details about google ads in https://developers.google.com/google-ads/webhook/docs/implementation
*/
@RestResource(urlMapping='/googlelead/*')
global class RESTGoogleLeads {
    
    private static String setting_key = 'GOOGLE_AD';
    private static String google_key;
    private static String google_domain;
    private static String logName = 'GOOGLE_LEAD';
    
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String subkey = getSubKey(req.requestURI);
        res.statusCode = 200;
        res.addHeader('Content-Type', 'application/json');     
        res.responseBody = Blob.valueOf('{"hey":"google from " *' + subkey + '*}');   
    } // get
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Blob body = req.requestBody;
        String bodyString = body.toString();

        SystemLog log = new SystemLog(logName);      
        log.setInputData(bodyString);

        try {    
            RESTGoogleLeads.google_domain = getSubKey(req.requestURI);
            PorcelanosaSetting setting = new PorcelanosaSetting(RESTGoogleLeads.setting_key, RESTGoogleLeads.google_domain);
            RESTGoogleLeads.google_key = setting.value1;  
            JSONLead glead = parseGoogleLead(bodyString);
            LeadsService.Request request = googleToRequest(glead);
            LeadsService.GoogleFields fields = new LeadsService.GoogleFields();
            fields.googleLeadId = glead.lead_id;
            fields.googleFormId = glead.form_id;
            fields.googleCampaignId = glead.campaign_id;
            fields.isTest = glead.is_test;            
            fields.googleDomain = RESTGoogleLeads.google_domain;
            fields.defaultUserId = UserUtils.getUserIdFromEmail(setting.value2);
            Lead lead = LeadsService.createGoogleAdLead(request, fields);
            log.addInfo('Google lead received and created with Id ' + lead.Id);
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(lead));   
        } catch (Exception ex) {
            log.addError(ex);
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(ex.getTypeName() + ': ' + ex.getMessage());
        }
        log.saveLog();
    } // post

    /* <<<<<<<<<<<<<<<<<<<<< PRIVATE METHODS >>>>>>>>>>>>>>>>>>>>> */

    @testVisible private static String getSubKey(String uriString) {    
        String uri = uriString.toUpperCase().removeEnd('/');
        Integer index = uri.lastIndexOf('/');
        if (index >= 0) {
            uri = uri.substring(index);
        }
        index = uri.lastIndexOf('?');
        if (index >= 0) {
            uri = uri.substring(0, index);
        }
        return uri.remove('/');
    }

    private static JSONLead parseGoogleLead(String jsonString) {
        JSONLead glead = new JSONLead();
        try {
            glead = (JSONLead) JSON.deserializeStrict(jsonString , JSONLead.class);
            if (glead.is_test == null) {
                glead.is_test = false;
            }
        } catch(Exception e) {
            e.setMessage('Invalid JSON Lead: ' + e.getMessage());
            throw e;
        }

        if (glead.google_key != RESTGoogleLeads.google_key) {
            throw new ParseException('Invalid key ' + glead.google_key);
        }
        return glead;
    } // parseGoogleLead

    private static LeadsService.Request googleToRequest(JSONLead glead) {
        LeadsService.Request leadData = new LeadsService.Request();
        String fullName;
        for(UserLeadColumnData column: glead.user_column_data) {
            if (String.IsNotBlank(column.column_id)) {
                switch on column.column_id.toUpperCase() {
                    when 'EMAIL' {
                        leadData.email = column.string_value;
                    }
                    when 'PHONE_NUMBER' {
                        leadData.mobile = column.string_value;
                    }
                    when 'FIRST_NAME' {
                        leadData.firstName = column.string_value;
                    }
                    when 'LAST_NAME' {
                        leadData.lastName = column.string_value;
                    }
                    when 'COMPANY_NAME' {
                        leadData.company = column.string_Value;
                    }
                    when 'STREET_ADDRESS' {
                        leadData.street = column.string_Value;
                    }
                    when 'POSTAL_CODE' {
                        leadData.postCode = column.string_value.toUpperCase();
                    }
                    when 'CITY' {
                        leadData.town = column.string_Value;
                    }
                    when 'REGION' {
                        leadData.state = column.string_Value;
                    }
                    when 'COUNTRY' {
                        leadData.countryCode = column.string_Value;
                    }
                    when 'PRODUCT' {
                        leadData.comments = column.string_Value;
                    }
                    when 'PREFERRED_CONTACT_METHOD' {
                        leadData.preferredContactMethod = column.string_Value;
                    }
                    when 'PREFERRED_CONTACT_TIME' {
                        leadData.preferredContactTIme = column.string_Value;
                    }
                    when 'FULL_NAME' {
                        // Name
                        fullName = column.string_value;
                    }            
                } // switch
            }
            if (String.IsBlank(leadData.lastName)) {
                splitFullName(leadData, fullName);
            }
        }
        return leadData;
    }

    private static void splitFullName(LeadsService.Request leadData, String fullName) {
        if (!String.IsBlank(fullName)) {
            List<String> parts = fullName.split(' ');
            if (parts.size() > 1) {
                leadData.LastName = parts[parts.size()-1];
                parts.remove(parts.size() -1);
            }
            leadData.FirstName = String.join(parts, ' ');
        }
    }

    global class JSONLead {
        public string lead_id;
        public string api_version;
        public string form_id;
        public string campaign_id;
        public string adgroup_id;
        public string creative_id;
        public string gcl_id;
        public string google_key;
        public Boolean is_test = false;
        public List<UserLeadColumnData> user_column_data;
    } // inner class JSONLead
}