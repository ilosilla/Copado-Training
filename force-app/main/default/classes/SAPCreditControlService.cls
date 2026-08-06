/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Services
 * @description    Acceso a los servicios de credit control de SAP
*/
public class SAPCreditControlService {
    
    public static CreditResultDTO retrieveCreditStatus(String accountId, String salesOrg) {

        Account acc = [SELECT Id, SAP_Id__c FROM Account WHERE Id = :accountId LIMIT 1];
        String serviceUrl = SAPCPIProxy.CREDIT_ENDPOINT.replace('{customer-id}', acc.SAP_Id__c).replace('{sales-org}', salesOrg);        
        SAPCPIProxy proxy = new SAPCPIProxy(serviceUrl);
        proxy.setMethod('GET');
        CreditResultDTO result = new CreditResultDTO();
        try {
            String response = proxy.callCPI();
            result = (CreditResultDTO) JSON.deserialize(response, CreditResultDTO.class);                        
            // SANDBOX
            // result.blockedByOverdueItems = true;
            // result.globalCreditOk = false;
            // result.creditCommitted = 15000;
        } catch (HttpException hex) {
            throw hex;
        }

        return result;
    }

    public class CreditResultDTO {
        // Identification
        @AuraEnabled public String  customerCode;
        @AuraEnabled public String  companyCode;

        // Credit classification
        @AuraEnabled public String  creditCategory;
        @AuraEnabled public String  currencyCode;

        // Credit figures
        @AuraEnabled public Decimal creditLimit;
        @AuraEnabled public Decimal creditCommitted;
        @AuraEnabled public Decimal creditUtilizationRate;

        // Global status
        @AuraEnabled public Boolean globalCreditOk;
        @AuraEnabled public Boolean financeBlock;
        @AuraEnabled public Boolean requiresDeposits;

        // Blocking reasons
        @AuraEnabled public Boolean blockedByUnpaidItems;
        @AuraEnabled public Boolean blockedByOverdueItems;
        @AuraEnabled public Boolean blockedByOverdueOthers;
        @AuraEnabled public Boolean blockedByCreditLimit;

        // Human-readable status
        @AuraEnabled public String  creditStatus;
        }
}