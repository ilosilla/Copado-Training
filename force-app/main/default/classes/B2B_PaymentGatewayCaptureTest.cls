@isTest public with sharing class B2B_PaymentGatewayCaptureTest {

    @testSetup private static void makeData() {
        PORSAStoreSettings__c storeSettings = new PORSAStoreSettings__c();
        storeSettings.Name = 'US_DEALERS';
        storeSettings.Secret__c = 'C8CnCpx4kFuxBofxUJFqnS26L2XXXX';
        storeSettings.RedirectTo__c = 'https://porsa.dummy.com/sforce-rpr/openapi/v2/payment-gateway-response/';
        insert storeSettings;
        DataFactoryECommerce factory = new DataFactoryECommerce();
        factory.buildEcommerce();    
        factory.createCart();
    }

    @isTest private static void testHandle() {
        RestRequest request = new RestRequest();
        String inputFields = 'REQ_QUOTE_ID=a4wRR000000SduTYAS&REQ_AMOUNT=14061&REQ_CURRENCY=USD&REQ_TIMESTAMP=20260223041338&REQ_TYPE=redirect_form&REQ_CUSTOMER_ID=001RR00000ifl5pYAA&REQ_CUSTOMER_NAME=John+Smith&REQ_CUSTOMER_SURNAME=IMPERIAL+TILE+%26+STONE+INC.&'
                        + 'REQ_CUSTOMER_MAIL=rprades%40porcelanosagrupo.com&REQ_BILLING_STREET=7211+Whitsett+Avenue&REQ_BILLING_CITY=Los+Angeles&REQ_BILLING_STATE=CA&REQ_BILLING_POSTALCODE=91605&REQ_BILLING_COUNTRY=US&'
                        + 'REQ_RESPONSE_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-response%2F&R'
                        + 'EQ_CAPTURE_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-capture%2F&'
                        + 'REQ_ERROR_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-error%2F&REQ_SOCIETY=610&REQ_B2B=1&'
                        + 'REQ_SALES_ORGANIZATION=603&REQ_CUSTOMER_PHONENUMBER_MOBILE=8187648453&REQ_CUSTOM_FIELD1=99ef927ff64b3efb209a4d8664b6b432&RESULT_CODE=00&RESULT=Processed&MESSAGE=Approved&MERCHANT=b2bTest&'
                        + 'PAID_AMOUNT=14061&PAID_CURRENCY=USD&TIMESTAMP=20260223121401&PAYMENT_ID=772&PAYMENT_GATEWAY=cardknox&PAYMENT_METHOD=card&PAYMENT_CARD=Visa&PAYMENT_CARD_LAST_NUMBERS=1111&'
                        + 'SIGNED_FIELD_NAMES=REQ_QUOTE_ID%2CREQ_AMOUNT%2CREQ_CURRENCY%2CREQ_TIMESTAMP%2CREQ_TYPE%2CREQ_CUSTOMER_ID%2CREQ_CUSTOMER_NAME%2CREQ_CUSTOMER_SURNAME%2CREQ_CUSTOMER_MAIL%2CREQ_BILLING_STREET%2C'
                        + 'REQ_BILLING_CITY%2CREQ_BILLING_STATE%2CREQ_BILLING_POSTALCODE%2CREQ_BILLING_COUNTRY%2CREQ_RESPONSE_URL_OVERRIDE%2CREQ_CAPTURE_URL_OVERRIDE%2CREQ_ERROR_URL_OVERRIDE%2CREQ_SOCIETY%2CREQ_B2B%2C'
                        + 'REQ_SALES_ORGANIZATION%2CREQ_CUSTOMER_PHONENUMBER_MOBILE%2CREQ_CUSTOM_FIELD1%2CRESULT_CODE%2CRESULT%2CMESSAGE%2CMERCHANT%2CPAID_AMOUNT%2CPAID_CURRENCY%2CTIMESTAMP%2CPAYMENT_ID%2CPAYMENT_GATEWAY%2C'
                        + 'PAYMENT_METHOD%2CPAYMENT_CARD%2CPAYMENT_CARD_LAST_NUMBERS%2CSIGNED_FIELD_NAMES';
        
        PORSAStoreSettings__c storeSettings = PORSAStoreSettings__c.getInstance('US_DEALERS');
        Map<String,String> fields = convertToMap(inputFields);
        String signature = B2B_PaymentGatewayCapture.calculateSignature(fields.get('SIGNED_FIELD_NAMES'), fields, storeSettings.Secret__c);
        fields.put('SIGNATURE', signature);
        inputFields += '&SIGNATURE=' + signature;
        request.requestBody = Blob.valueOf(inputFields);

        // Crea el payment request
        WebCart cart = [SELECT Id, AccountId FROM WebCart LIMIT 1];
        PaymentRequest__c paymentRequest = new PaymentRequest__c();
        paymentRequest.RetryCount__c = 0;
        paymentRequest.Token__c = fields.get('REQ_CUSTOM_FIELD1');                
        paymentRequest.CartId__c = cart.Id;
        paymentRequest.Account__c = cart.AccountId;
        paymentRequest.Amount__c = 100;
        paymentRequest.CurrencyIsoCode = 'USD';
        paymentRequest.PONumber__c = 'PO9999';
        paymentRequest.PaymentGateway__c = 'PORSA_GATEWAY';
        paymentRequest.StartedAt__c = System.now();
        paymentRequest.Status__c = 'WAITING_PAYMENT';
        paymentRequest.Type__c = 'PAYMENT';
        paymentRequest.User__c = UserInfo.getUserId();   
        paymentRequest.CreditCardSurcharge__c = 10;
        paymentRequest.CreditCardSurchargePct__c = 2.5;             
        insert paymentRequest;        
        
        Test.startTest();
        Integer statusCode = B2B_PaymentGatewayCapture.handle(request);
        Test.stopTest();    
        System.assertEquals(204, statusCode, 'Expected status code 204');
    }

    @isTest private static void testResponse() {
        RestRequest request = new RestRequest();
        String inputFields = 'REQ_QUOTE_ID=a4wRR000000SduTYAS&REQ_AMOUNT=14061&REQ_CURRENCY=USD&REQ_TIMESTAMP=20260223041338&REQ_TYPE=redirect_form&REQ_CUSTOMER_ID=001RR00000ifl5pYAA&REQ_CUSTOMER_NAME=John+Smith&REQ_CUSTOMER_SURNAME=IMPERIAL+TILE+%26+STONE+INC.&'
                        + 'REQ_CUSTOMER_MAIL=rprades%40porcelanosagrupo.com&REQ_BILLING_STREET=7211+Whitsett+Avenue&REQ_BILLING_CITY=Los+Angeles&REQ_BILLING_STATE=CA&REQ_BILLING_POSTALCODE=91605&REQ_BILLING_COUNTRY=US&'
                        + 'REQ_RESPONSE_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-response%2F&R'
                        + 'EQ_CAPTURE_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-capture%2F&'
                        + 'REQ_ERROR_URL_OVERRIDE=https%3A%2F%2Fporcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com%2Fsforce-rpr%2Fopenapi%2Fv2%2Fpayment-gateway-error%2F&REQ_SOCIETY=610&REQ_B2B=1&'
                        + 'REQ_SALES_ORGANIZATION=603&REQ_CUSTOMER_PHONENUMBER_MOBILE=8187648453&REQ_CUSTOM_FIELD1=99ef927ff64b3efb209a4d8664b6b432&RESULT_CODE=00&RESULT=Processed&MESSAGE=Approved&MERCHANT=b2bTest&'
                        + 'PAID_AMOUNT=14061&PAID_CURRENCY=USD&TIMESTAMP=20260223121401&PAYMENT_ID=772&PAYMENT_GATEWAY=cardknox&PAYMENT_METHOD=card&PAYMENT_CARD=Visa&PAYMENT_CARD_LAST_NUMBERS=1111&'
                        + 'SIGNED_FIELD_NAMES=REQ_QUOTE_ID%2CREQ_AMOUNT%2CREQ_CURRENCY%2CREQ_TIMESTAMP%2CREQ_TYPE%2CREQ_CUSTOMER_ID%2CREQ_CUSTOMER_NAME%2CREQ_CUSTOMER_SURNAME%2CREQ_CUSTOMER_MAIL%2CREQ_BILLING_STREET%2C'
                        + 'REQ_BILLING_CITY%2CREQ_BILLING_STATE%2CREQ_BILLING_POSTALCODE%2CREQ_BILLING_COUNTRY%2CREQ_RESPONSE_URL_OVERRIDE%2CREQ_CAPTURE_URL_OVERRIDE%2CREQ_ERROR_URL_OVERRIDE%2CREQ_SOCIETY%2CREQ_B2B%2C'
                        + 'REQ_SALES_ORGANIZATION%2CREQ_CUSTOMER_PHONENUMBER_MOBILE%2CREQ_CUSTOM_FIELD1%2CRESULT_CODE%2CRESULT%2CMESSAGE%2CMERCHANT%2CPAID_AMOUNT%2CPAID_CURRENCY%2CTIMESTAMP%2CPAYMENT_ID%2CPAYMENT_GATEWAY%2C'
                        + 'PAYMENT_METHOD%2CPAYMENT_CARD%2CPAYMENT_CARD_LAST_NUMBERS%2CSIGNED_FIELD_NAMES';
        request.requestBody = Blob.valueOf(inputFields);
        Test.startTest();
        String result = B2B_PaymentGatewayCapture.responsePage(request);
        Test.stopTest();
        Assert.isNotNull(result, 'SOmething expected');
    }

    @isTest private static void testError1() {
        // Crea el payment request
        WebCart cart = [SELECT Id, AccountId FROM WebCart LIMIT 1];
        PaymentRequest__c paymentRequest = new PaymentRequest__c();
        paymentRequest.RetryCount__c = 0;
        paymentRequest.Token__c = '99ef927ff64b3efb209a4d8664b6b432';                
        paymentRequest.CartId__c = cart.Id;
        paymentRequest.Account__c = cart.AccountId;
        paymentRequest.Amount__c = 100;
        paymentRequest.CurrencyIsoCode = 'USD';
        paymentRequest.PONumber__c = 'PO9999';
        paymentRequest.PaymentGateway__c = 'PORSA_GATEWAY';
        paymentRequest.StartedAt__c = System.now();
        paymentRequest.Status__c = 'WAITING_PAYMENT';
        paymentRequest.Type__c = 'PAYMENT';
        paymentRequest.User__c = UserInfo.getUserId();   
        paymentRequest.CreditCardSurcharge__c = 10;
        paymentRequest.CreditCardSurchargePct__c = 2.5;             
        insert paymentRequest; 
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('RESULT_CODE=500&RESULT=Error&MESSAGE=The+q+u+o+t+e++i+d+must+not+be+greater+than+25+characters.&REQ_CUSTOM_FIELD1=99ef927ff64b3efb209a4d8664b6b432');
        Test.startTest();
        String result = B2B_PaymentGatewayCapture.errorPage(request);
        Test.stopTest();
        Assert.isNotNull(result, 'SOmething expected');
    }

    @isTest private static void testError2() {
        // Crea el payment request
        WebCart cart = [SELECT Id, AccountId FROM WebCart LIMIT 1];
        PaymentRequest__c paymentRequest = new PaymentRequest__c();
        paymentRequest.RetryCount__c = 0;
        paymentRequest.Token__c = '99ef927ff64b3efb209a4d8664b6b432';                
        paymentRequest.CartId__c = cart.Id;
        paymentRequest.Account__c = cart.AccountId;
        paymentRequest.Amount__c = 100;
        paymentRequest.CurrencyIsoCode = 'USD';
        paymentRequest.PONumber__c = 'PO9999';
        paymentRequest.PaymentGateway__c = 'PORSA_GATEWAY';
        paymentRequest.StartedAt__c = System.now();
        paymentRequest.Status__c = 'WAITING_PAYMENT';
        paymentRequest.Type__c = 'PAYMENT';
        paymentRequest.User__c = UserInfo.getUserId();   
        paymentRequest.CreditCardSurcharge__c = 10;
        paymentRequest.CreditCardSurchargePct__c = 2.5;             
        insert paymentRequest; 
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf('RESULT_CODE=00&RESULT=OK&MESSAGE=The+q+u+o+t+e++i+d+must+not+be+greater+than+25+characters.&REQ_CUSTOM_FIELD1=99ef927ff64b3efb209a4d8664b6b432');
        Test.startTest();
        String result = B2B_PaymentGatewayCapture.errorPage(request);
        Test.stopTest();
        Assert.isNotNull(result, 'SOmething expected');
    }


    private static Map<String, String> convertToMap(String input) {
        Map<String, String> result = new Map<String, String>();
        for (String pair : input.split('&')) {
            List<String> keyValue = pair.split('=');
            if (keyValue.size() == 2) {
                result.put(keyValue[0], keyValue[1]);
            }
        }
        return result;
    }
}