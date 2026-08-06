/**
 * @author         Ramón Prades
 * @date           February 2026
 * @layer          B2B
 * @description    EThis the class executed from the 
*/
@SuppressWarnings('PMD.UnusedLocalVariable, PMD.EmptyCatchBlock')
public with sharing class B2B_PaymentGatewayCapture {    

    private static final String LOG_SCENARIO = 'PAYMENT_GATEWAY_CAPTURE';

    public static Integer handle(RestRequest req) {  
        Boolean ok = false;     
        String message = '';

        SystemLog log = new SystemLog(LOG_SCENARIO);
        log.setSummary('Payment received');
        log.setInputData(req.requestBody.toString());

        try {            
            PORSAStoreSettings__c storeSettings = PORSAStoreSettings__c.getInstance('US_DEALERS');
            Map<String, String> fields = parseReceivedFields(req);
            log.addInfo('Response from payment received');

            String token = fields.get('REQ_CUSTOM_FIELD1') ?? '0';
            if (token == '0') {
                message = 'Missing token in the received data';
                log.addError(message);
                log.saveLog(true);
                return 204; // Devolvemos 204 para no provocar retries del proveedor, aunque el log registre el error
            }
            // Validate signature
            String expectedSignature = fields.get('SIGNATURE');
            String signedFields = fields.get('SIGNED_FIELD_NAMES');
            String signature = B2B_PaymentGatewayCapture.calculateSignature(signedFields, fields, storeSettings.Secret__c);
            if (expectedSignature != signature) {
                message = 'Invalid signature. Expected: ' + expectedSignature + ', Calculated: ' + signature;
                log.addError(message);
            } else {
                log.addInfo('Signature validated successfully');
            }
            
            B2B_PaymentsService.ReceivedPaymentDTO paymentInfo = new B2B_PaymentsService.ReceivedPaymentDTO();
            paymentInfo.amount = Decimal.valueOf(fields.get('PAID_AMOUNT') ?? '0') / 100;
            paymentInfo.currencyCode = fields.get('PAID_CURRENCY');
            paymentInfo.method = fields.get('PAYMENT_METHOD');
            paymentInfo.cardName = fields.get('PAYMENT_CARD');
            paymentInfo.cardLast4Digits = fields.get('PAYMENT_CARD_LAST_NUMBERS');
            paymentInfo.transactionId = fields.get('PAYMENT_ID');
            
            // Update payment request record
            log.addInfo('Sending payment info to Payments Service: ' + JSON.serialize(paymentInfo));
            PaymentRequest__c payment = B2B_PaymentsService.updatePaymentFromResponse(token, paymentInfo);            
            log.addInfo('Payment updated succesfully to status ' + payment.Status__c);
            String paymentUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Account/' + payment.Id + '/view';
            log.addInfo('Payment link: ' + paymentUrl);

            // And create the order 
            Order order = B2B_CommerceOrdersService.createOrderFromPayment(payment);
            log.addInfo('Order created successfully with id ' + order.Id);
            String orderUrl = URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Order/' + order.Id + '/view';
            log.addInfo('Order link: ' + orderUrl); 
            log.saveLog(true);  
        } catch (Exception e) {
            // Incluso si falla el log, devolvemos 204 para no provocar tormenta de retries del proveedor.
            log.addError(e); 
            SystemLog.writeLog(JSON.serialize(log));        
        }
        return 204;
    }

    public static String responsePage(RestRequest req) {
        Map<String, String> fields = parseReceivedFields(req);
        String token = fields.get('REQ_CUSTOM_FIELD1') ?? '0';
        return buildRedirectPage(token);
    }

    public static String errorPage(RestRequest req) {
        String token = '';
        Map<String, String> fields = parseReceivedFields(req);
        PaymentRequest__c request = B2B_PaymentGatewayCapture.getPaymentFromFields(fields);
        if (fields.get('RESULT') == 'ERROR') {
            token = 'ERR';
            SystemLog log = new SystemLog(LOG_SCENARIO);
            log.setSummary('Payment error received');
            log.setInputData(req.requestBody.toString());
            log.addError('Payment gateway reported an error');
            log.addError('Received fields: ' + JSON.serializePretty(fields));
            log.saveLog(true);
            if (request != null) {
                request.Status__c = B2B_PaymentsService.FAILED_STATUS;
                request.ErrorMessage__c = fields.get('ERROR_MESSAGE') ?? '';
                try {
                    update request;
                    token = request.Token__c;
                } catch (Exception ignore) {
                }
            }
        } else {
            // It has to be the user cancelled the payment
            token = 'CAN';
            SystemLog log = new SystemLog(LOG_SCENARIO);
            log.setSummary('Payment cancelled by user');
            log.setInputData(req.requestBody.toString());
            log.addWarning('Payment gateway reported a cancellation by the user');
            log.addWarning('Received fields: ' + JSON.serializePretty(fields));        
            log.saveLog(true);
            if (request != null) {
                request.Status__c = B2B_PaymentsService.CANCELLED_STATUS;
                request.ErrorMessage__c = '';
                try {
                    update request;
                    token = request.Token__c;
                } catch (Exception ignore) {
                }
            }
        }        
        return buildRedirectPage(token);
    }

    private static Map<String, String> parseReceivedFields(RestRequest req) {
        Map<String, String> result = new Map<String, String>();
        String body = req.requestBody.toString() ?? '';
        try {
            if (String.isNotBlank(body)) {
                for (String pair : body.split('&')) {
                    if (String.isBlank(pair)) {
                        continue;
                    }
                    List<String> kv = pair.split('=', 2);
                    String k = EncodingUtil.urlDecode(kv[0], 'UTF-8');
                    String v = (kv.size() > 1) ? EncodingUtil.urlDecode(kv[1], 'UTF-8') : '';
                    result.put(k, v);
                }
            }
        } catch(Exception ignore) {}
        return result;
    }

    /*
     * Gets a signature for a given list of fields
     */
    @testVisible private static String calculateSignature(String signedFields, Map<String, String> fields, String secret) {        
        List<String> signed = signedFields.split(',');
        // Build data-to-sign in the exact order: key=value,key=value,...
        List<String> parts = new List<String>();
        for (String key : signed) {
            parts.add(key + '=' + (fields.containsKey(key) && fields.get(key) != null ? fields.get(key) : ''));
        }
        String dataToSign = String.join(parts, ',');

        // HMAC-SHA256 + Base64
        Blob mac = Crypto.generateMac('HmacSHA256', Blob.valueOf(dataToSign), Blob.valueOf(secret));
        return EncodingUtil.base64Encode(mac);
    }

    /**
     * Gets the payment request from the fields received
     */
    private static PaymentRequest__c getPaymentFromFields(Map<String, String> fields) {
        PaymentRequest__c[] requests = new List<PaymentRequest__c>();
        String token = fields.get('REQ_CUSTOM_FIELD1');
        if (token == null) {
            String pid = fields.get('REQ_QUOTE_ID');
            if (String.isNotBlank(pid)) {
                requests = [SELECT Id, Name, Token__c FROM PaymentRequest__c WHERE Id = :pid];
            }
        } else {
            requests = [SELECT Id, Name, Token__c FROM PaymentRequest__c WHERE Token__c = :token];
        }
        if (requests.size() > 0) {
            return requests[0];
        }
        return null;
    }

    /*
     * Builds the html page to redirect to the b2b repsonse handler with the payment result (success or error)
     */
    private static String buildRedirectPage(String token) {
        PORSAStoreSettings__c storeSettings = PORSAStoreSettings__c.getInstance('US_DEALERS');
        String sep = storeSettings.RedirectTo__c.contains('?') ? '&' : '?';
        String landingUrl = storeSettings.RedirectTo__c  + sep + 'token=' + EncodingUtil.urlEncode(token, 'UTF-8');        
        return
            '<!doctype html>' +
            '<html>' +
            '<head><meta charset="utf-8"></head>' +
            '<body>' +
            '  <script>' +
            '    window.location.replace(\'' + landingUrl + '\');' +
            '  </script>' +
            '  Redirecting…' +
            '</body>' +
            '</html>';
    }

}