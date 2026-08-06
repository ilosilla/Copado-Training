/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		SAP
* @description 	Adapter class to provide plain field names to SAP invoices as read from Facturas_CabecerasSet__x.
*               So, fields like "Ordernum__c" are published in teh adapter as "docNumber".
*               Also, iwe avoid the wording INVOICE in the property names because in a near future we might have a common interface
*               for quotes and orders too.
*   
*/
public class SAPInvoiceHeader {
    // Classification properties
    @AuraEnabled public final String docClass = 'INV';
    @AuraEnabled public final Boolean isInvoice = true;
    @AuraEnabled public final Boolean isOrder = false;
    @AuraEnabled public final Boolean isQuote = false;

    // Class properties
    @AuraEnabled public String accountId;
    @AuraEnabled public String SAPCustomer;
    @AuraEnabled public String company;
    @AuraEnabled public Boolean isCredit;
    @AuraEnabled public String docCurrency;
    @AuraEnabled public Date deliveryDate;
    @AuraEnabled public String distributionChannel;
    @AuraEnabled public Decimal docNetAmount;
    @AuraEnabled public Decimal docTaxAmount;
    @AuraEnabled public Decimal docTotalAmount;
    @AuraEnabled public String localCurrency;
    @AuraEnabled public Decimal localNetAmount;
    @AuraEnabled public Decimal localTaxAmount;
    @AuraEnabled public Decimal localTotalAmount;
    @AuraEnabled public Boolean isOpen;
    @AuraEnabled public Date docDate;
    @AuraEnabled public String docNumber;
    @AuraEnabled public Boolean isPaid;
    @AuraEnabled public String docType;
    @AuraEnabled public String reference;
    @AuraEnabled public String SAPRep1;
    @AuraEnabled public String SAPRep2;
    @AuraEnabled public String salesOffice;
    @AuraEnabled public String salesOrg;
    @AuraEnabled public String opportunityId;
    @AuraEnabled public String salesZone;

    public SAPInvoiceHeader(Facturas_cabeceraSet__x source) {
        this.accountId = source.Account__c;
        this.SAPCustomer = source.BillTo__c;
        if (String.isBlank(this.accountId)) {
            this.accountId = this.getAccountFromSAPCode(this.SAPCustomer);
        }
        this.company = source.Company__c;
        this.isCredit = (source.credit__c == 'X');
        this.docCurrency = source.Dcurr__c;
        if (source.Ddate__c != null) {
            this.deliveryDate = source.Ddate__c.date();
        }
        this.distributionChannel = source.Distchannel__c;
        this.docNetAmount = source.Dnet__c;
        this.docTaxAmount = source.Dtax__c;
        this.docTotalAmount = source.Dtotal__c;
        this.localCurrency = source.Lcurr__c;
        this.localNetAmount = source.Lnet__c;
        this.localTaxAmount = source.Ltax__c;
        this.localTotalAmount = source.Ltotal__c;
        this.isOpen = (source.OpenF__c == 'X');
        if (source.Orderdate__c != null) {
            this.docDate = source.Orderdate__c.date();
        }
        this.docNumber = source.Ordernum__c;
        this.isPaid = (source.Paid__c == 'X');
        this.docType = source.Ordertype__c;
        this.reference = source.Refer__c;
        this.SAPRep1 = source.Repo1__c;
        this.SAPRep2 = source.Repo2__c;
        this.salesOffice = source.SALESOFFIC__c;
        this.salesOrg = source.Salesorg__c;
        this.opportunityId = source.Sfopportunity__c;
        this.salesZone =  source.Szone__c;
    }    

    private String getAccountFromSAPCode(String sapId) {
        String res;
        if (String.isNotBlank(sapId)) {
            Account[] accs = [select Id, SAP_Id__c from Account where SAP_Id__c = :sapId.leftPad(10, '0')];
            if (accs.size() > 0) {
                res = accs[0].Id;
            }
        }
        return res;
    }
}