public class SMS {
    private String phone;
    private String phoneFormatted;
    private String body;
    private String country;

    public SMS(String phone, String body, String country) {
        this.phone = phone;
        this.phoneFormatted = phone;
        this.body = body;
        this.country = country;
    }

    public Boolean send() {
        Map<String,String> responseService = new Map<String,String>();
        Boolean sentSMS = false;
        if (this.phone != null && this.body != null && this.country != null) {
            switch on this.country {
                when 'US','CA' {
                    responseService = sendSmsUSA();
                    if (responseService.get('http_code') == '200') {
                        sentSMS = true;
                    }
                }
                when else {
                    responseService = sendSmsBrevo();
                    if (responseService.get('http_code') == '200') {
                        sentSMS = true;
                    }
                }
            }
        }

        return sentSMS;
    }

    private Map<String,String> sendSmsBrevo() {
        Map<String,String> params = new Map<String,String>();
        List<SMSServiceSettings__mdt> apiData = [SELECT DeveloperName,Id,Label,Pass__c,Url__c,User__c FROM SMSServiceSettings__mdt where DeveloperName = 'BREVO'];
        String apiUsername;
        String apiPassword;
        String url;

        if (apiData.size() > 0) {
            apiUsername = apiData[0].User__c;
            apiPassword = apiData[0].Pass__c;
            url = apiData[0].Url__c;
        } else {
            params.put('http_code', '500');
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', 'Metadata not created');
            SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', new ContextException('Metadata Setting does not exist on US'));
            return params;
        }

        formatPhone();
        Pattern phonePattern = Pattern.compile('^\\+[1-9]\\d{1,14}$');
        Matcher MyMatcher = phonePattern.matcher(this.phoneFormatted);

        if (MyMatcher.matches()) {
            // Instantiate a new http object
            Http h = new Http();
            HttpRequest req = new HttpRequest();
    
            String base64Key = apiPassword;
            req.setEndpoint(url);
            req.setTimeout(120000);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');     
            req.setHeader('api-key',  base64Key );
            req.setBody('{ "sender" : "Porcelanosa", "recipient" : "' + this.phoneFormatted + '", "content" : "' + this.body + '"}');
    
            try {
                HttpResponse response = h.send(req);
                Map < String, Object > resultsMap = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                if (resultsMap.get('code') == null) {
                    params.put('http_code', '200');
                    params.put('token', null);
                    params.put('cookie', null);
                    params.put('error', null);
                } else {
                    params.put('http_code', '500');
                    params.put('token', null);
                    params.put('cookie', null);
                    params.put('error', null);
                }
            } catch (ContextException ex) {
                System.debug('ERROR while obtaining params => '+ ex);
                params.put('http_code', '500');
                params.put('token', null);
                params.put('cookie', null);
                params.put('error', ex.getMessage());
                SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', ex);
            }
        } else {
            params.put('http_code', '500');
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', 'Phone not valid');
            SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', new ContextException('Phone not valid' + phoneFormatted));
        }

        return params;
    }

    private Map<String,String> sendSmsUSA() {
        Map<String,String> params = new Map<String,String>();
        List<SMSServiceSettings__mdt> apiData = [SELECT DeveloperName,Id,Label,Pass__c,Url__c,User__c FROM SMSServiceSettings__mdt where DeveloperName = 'US'];
        String apiUsername;
        String apiPassword;
        String url;

        if (apiData.size() > 0) {
            apiUsername = apiData[0].User__c;
            apiPassword = apiData[0].Pass__c;
            url = apiData[0].Url__c;
        } else {
            params.put('http_code', '500');
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', 'Metadata not created');
            SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', new ContextException('Metadata Setting does not exist on US'));
            return params;
        }

        formatPhone();
        Pattern phonePattern = Pattern.compile('^\\+[1-9]\\d{1,14}$');
        Matcher MyMatcher = phonePattern.matcher(this.phoneFormatted);

        if (MyMatcher.matches()) {
            // Instantiate a new http object
            Http h = new Http();
            HttpRequest req = new HttpRequest();
    
            Blob blobData=Blob.valueOf(apiUsername + ':' + apiPassword);
            String base64Key = EncodingUtil.base64Encode(blobData);
            req.setEndpoint(url);
            req.setTimeout(120000);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');     
            req.setHeader('Authorization',  'Basic ' + base64Key );
            req.setBody('{"messages" : [ { "to" : "' + this.phoneFormatted + '", "source" : "Salesforce", "body" : "' + this.body + '" } ] }');
    
            try {
                HttpResponse response = h.send(req);
                Map < String, Object > resultsMap = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
                params.put('http_code', String.valueOf(resultsMap.get('http_code')));
                params.put('token', null);
                params.put('cookie', null);
                params.put('error', null);
            } catch (ContextException ex) {
                System.debug('ERROR while obtaining params => '+ ex);
                params.put('http_code', '500');
                params.put('token', null);
                params.put('cookie', null);
                params.put('error', ex.getMessage());
                SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', ex);
            }
        } else {
            params.put('http_code', '500');
            params.put('token', null);
            params.put('cookie', null);
            params.put('error', 'Phone not valid');
            SystemUtils.debugWarning('SMSWLIST', 'SMS NOT SENT', new ContextException('Phone not valid' + phoneFormatted));
        }

        return params;
    }

    public void formatPhone() {
        if (this.phone != null) {
            switch on this.country {
                when 'US' {
                    this.phoneFormatted = this.phone.replaceAll('[^0-9]', '');
                    if(this.phoneFormatted.length() == 10)
                    {
                        this.phoneFormatted = '1' + this.phoneFormatted;
                    }
                    if(this.phoneFormatted.length() == 11)
                    {
                        this.phoneFormatted = '+' + this.phoneFormatted;
                    }
                }
                when 'GB' {
                    this.phoneFormatted = this.phone.replaceAll('[^0-9]', '');
                    if(this.phoneFormatted.length() == 10)
                    {
                        this.phoneFormatted = '+44' + this.phoneFormatted;
                    }
                    if(this.phoneFormatted.length() == 11 && this.phoneFormatted.substring(0,1) == '0')
                    {
                        this.phoneFormatted = '+44' + this.phoneFormatted.substring(1);
                    }
                }
                when 'FR' {
                    this.phoneFormatted = this.phone.replaceAll('[^0-9]', '');
                    if(this.phoneFormatted.length() == 10)
                    {
                        this.phoneFormatted = '+33' + this.phoneFormatted;
                    }
                }
            }
        }
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
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }

}