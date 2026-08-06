@isTest
public  class MailChimpTest {

    @TestSetup static void makeData(){
        PorcelanosaSetting__c newSetting = new PorcelanosaSetting__c(isActive__c = true, key__c = 'MAILCHIMP', subkey__c = 'DES', value1__c = 'MailchimpDES', value2__c = 'cd088801f2');
        insert newSetting;
    }

    @istest
    static void okResponse() {
        QueueHttpMock mock = new QueueHttpMock();
        HttpResponse resFound = new HttpResponse();
        resFound.setHeader('Content-Type', 'application/json');
        resFound.setBody('{' +
            '"exact_matches": {' +
                '"members": [' +
                    '{' +
                        '"id": "f62826ba63c8c0a67e023d88fc09e324",' +
                        '"email_address": "test@email.com",' +
                        '"full_name": "Pato Donald",' +
                        '"status": "unsubscribed",' +
                        '"merge_fields": {' +
                            '"FNAME": "Pato",' +
                            '"LNAME": "Donald",' +
                            '"ADDRESS": "",' +
                            '"PHONE": "1122334455",' +
                            '"BIRTHDAY": ""' +
                        '},' +
                        '"tags_count": 1,' +
                        '"tags": [' +
                            '{' +
                                '"id": 1342,' +
                                '"name": "Salesforce"' +
                            '}' +
                        '],' +
                        '"list_id": "cd088801f2"' +
                    '}' +
                '],' +
                '"total_items": 1' +
            '}' +
        '}');
        resFound.setStatusCode(200);
        HttpResponse resNotFound = new HttpResponse();
        resNotFound.setHeader('Content-Type', 'application/json');
        resNotFound.setBody('{' +
            '"exact_matches": {' +
                '"members": [],' +
                '"total_items": 0' +
            '}' +
        '}');
        resNotFound.setStatusCode(200);
        HttpResponse resInsertUpdate = new HttpResponse();
        resInsertUpdate.setHeader('Content-Type', 'application/json');
        resInsertUpdate.setBody('{' +
                '"id": "f62826ba63c8c0a67e023d88fc09e324",' +
                '"email_address": "test@email.com",' +
                '"full_name": "Pato Donald",' +
                '"status": "unsubscribed",' +
                '"merge_fields": {' +
                    '"FNAME": "Pato",' +
                    '"LNAME": "Donald",' +
                    '"ADDRESS": "",' +
                    '"PHONE": "1122334455",' +
                    '"BIRTHDAY": ""' +
                '},' +
                '"tags_count": 1,' +
                '"tags": [' +
                    '{' +
                        '"id": 1342,' +
                        '"name": "Salesforce"' +
                    '}' +
                '],' +
                '"list_id": "cd088801f2"' +
        '}');
        resInsertUpdate.setStatusCode(200);
        
        mock.addResponse(resFound);
        mock.addResponse(resInsertUpdate);
        mock.addResponse(resFound);
        mock.addResponse(resInsertUpdate);
        mock.addResponse(resFound);

        mock.addResponse(resFound);
        mock.addResponse(resInsertUpdate);
        mock.addResponse(resFound);
        mock.addResponse(resInsertUpdate);
        mock.addResponse(resFound);
        
        mock.addResponse(resFound);
        mock.addResponse(resInsertUpdate);

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        MailChimpsService.MailchimpDTO chimpo1 = new MailChimpsService.MailchimpDTO();
        chimpo1.context = 'DES';
        chimpo1.email = 'emailTest@adsas.es';
        chimpo1.firstname = 'Test';
        chimpo1.lastname = 'Lasto' ;

        
        Test.startTest();
        System.assertEquals(true, MailchimpsService.addSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response not correct');
        System.assertEquals(true, MailchimpsService.cancelSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response not correct');
        System.assertEquals(false, MailchimpsService.isSubscribed(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response not correct');
        
        MailChimpsService.MailchimpDTO chimpo2 = new MailChimpsService.MailchimpDTO();
        chimpo2.context = 'DES';
        chimpo2.email = 'emailTest@adsas.es';
        chimpo2.firstname = 'Test';
        chimpo2.lastname = 'Lasto' ;

        System.assertEquals(true, MailchimpsService.addSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo2})[0], 'Response not correct');
        System.assertEquals(true, MailchimpsService.cancelSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo2})[0], 'Response not correct');
        System.assertEquals(false, MailchimpsService.isSubscribed(new List<MailChimpsService.MailchimpDTO>{chimpo2})[0], 'Response not correct');
        
        chimpo2.lastname = 'LastoTwo';
        System.assertEquals(true, MailchimpsService.updateData(new List<MailChimpsService.MailchimpDTO>{chimpo2})[0], 'Response not correct');
        Test.stopTest();   
    }

    @istest
    static void errorResponse() {
        QueueHttpMock mock = new QueueHttpMock();

        HttpResponse resError = new HttpResponse();
        resError.setHeader('Content-Type', 'application/json');
        resError.setBody('{' +
            '"type": "https://mailchimp.com/developer/marketing/docs/errors/",' +
            '"title": "Invalid Resource",' +
            '"status": 400,' +
            '"detail": "The resource submitted could not be validated. For field-specific details, see the \'errors\' array.",' +
            '"instance": "8a1928ca-1a6a-c8ee-cfb0-775f0b8d5954",' +
            '"errors": [' +
                '{' +
                    '"field": "email_address",' +
                    '"message": "This value should not be blank."' +
                '}' +
            ']' +
        '}');
        resError.setStatusCode(400);

        mock.addResponse(resError);
        mock.addResponse(resError);
        mock.addResponse(resError);

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        MailChimpsService.MailchimpDTO chimpo1 = new MailChimpsService.MailchimpDTO();
        chimpo1.context = 'DES';
        chimpo1.email = 'emailTest@adsas.es';
        chimpo1.firstname = 'Test';
        chimpo1.lastname = 'Lasto' ;

        System.assertEquals(false, MailchimpsService.addSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response should have been an error');
        System.assertEquals(false, MailchimpsService.cancelSubscription(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response should have been an error');
        System.assertEquals(false, MailchimpsService.isSubscribed(new List<MailChimpsService.MailchimpDTO>{chimpo1})[0], 'Response should have been an error');
    }
}