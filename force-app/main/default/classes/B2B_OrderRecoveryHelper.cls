/**
 * @author         Ramón Prades
 * @date           February 2026
 * @layer          B2B
 * @description    Creates a record in B2B_OrderRecovery__c when an error occurs after payment is captured
 */
public without sharing class B2B_OrderRecoveryHelper {

    private B2B_OrderRecovery__c recoveryRecord;
    
    public B2B_OrderRecoveryHelper() {
        this.recoveryRecord = new B2B_OrderRecovery__c();
    }

    public B2B_OrderRecoveryHelper withAccountId(String accountId) {
        this.recoveryRecord.AccountId__c = accountId;
        return this;
    }

    public B2B_OrderRecoveryHelper withCartId(String cartId) {
        this.recoveryRecord.CartId__c = cartId;
        return this;
    }

    public B2B_OrderRecoveryHelper withCartJson(String cartJson) {
        this.recoveryRecord.CartJSON__c = cartJson;
        return this;
    }

    public B2B_OrderRecoveryHelper withPaymentJson(String paymentJson) {
        this.recoveryRecord.PaymentJSON__c = paymentJson;
        return this;
    }

    public B2B_OrderRecoveryHelper withAuxJson(String auxJson) {
        this.recoveryRecord.AuxJSON__c = auxJson;
        return this;
    }

    public B2B_OrderRecoveryHelper withPaymentRequestId(Id paymentRequestId) {
        this.recoveryRecord.PaymentRequest__c = paymentRequestId;
        return this;
    }

    public B2B_OrderRecoveryHelper withStoreId(String storeId) {
        this.recoveryRecord.StoreId__c = (String) storeId;
        return this;
    }

    public B2B_OrderRecoveryHelper withErrorMessage(String errorMessage) {
        this.recoveryRecord.ErrorMessage__c = errorMessage;
        return this;
    }

    public B2B_OrderRecoveryHelper save() {
        Mail m  = new Mail();
        m.setGeneric();
        m.setTo(new List<String>{'rprades@porcelanosagrupo.com'});        
        
        try {
            insert this.recoveryRecord;
            m.setSubject('[B2B CRITICAL ERROR ] Order recovery record created with id ' + this.recoveryRecord.Id);
            m.setHtml('<hr/>' +  URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Account/' + this.recoveryRecord.Id + '/view' 
                + '<hr/><br/><br/>Data saved:<br/>' 
                + JSON.serializePretty(this.recoveryRecord
            ));
        } catch (Exception e) {
            m.setSubject('[B2B CRITICAL ERROR] Order recovery record NOT created');
            m.setHtml('Error saving order recovery record: ' + e.getMessage() + '<br/>' + e.getStackTraceString() + '<br/><br/>Data that was attempted to save:<br/>' + JSON.serializePretty(this.recoveryRecord));
        } finally {
            m.send();
        }
        return this;
    }

}