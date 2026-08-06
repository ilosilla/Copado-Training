/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		SAP
* @description 	Adapter class to provide plain field names to SAP invoice lines as read from Facturas_PosicionesSet__x.
*               So, fields like "vrkme" are published in the adapter as "salesUnit".
*               Also, we avoid the wording INVOICE in the property names because in a near future we might have a common interface
*               for quotes and orders too.
*/
public class SAPInvoiceLine {

    @AuraEnabled public String docNumber;
    @AuraEnabled public Integer docLine;
    @AuraEnabled public String orderNumber;
    @AuraEnabled public Integer orderLine;
    @AuraEnabled public String docCurrency;
    @AuraEnabled public Decimal docNetAmount;
    @AuraEnabled public Decimal docTaxAmount;
    @AuraEnabled public Decimal docTotalAmount;
    @AuraEnabled public Date deliveryDate;
    @AuraEnabled public String localCurrency;
    @AuraEnabled public Decimal localNetAmount;
    @AuraEnabled public Decimal localTaxAmount;
    @AuraEnabled public Decimal localTotalAmount;
    @AuraEnabled public String make;                  
    @AuraEnabled public String productName;
    @AuraEnabled public Decimal quantity;
    @AuraEnabled public String productCode;
    @AuraEnabled public Decimal squareMetres;
    @AuraEnabled public String salesUnit;
    @AuraEnabled public Product2 Product2;
    @AuraEnabled public Double mtsxbox = 0;
    @AuraENabled public Double pcsxbox = 0;

    public SAPInvoiceLine(Facturas_posicionesSet__x source) {
        this.orderNumber = source.aubel__c;
        if (source.aupos__c != null) {
            this.orderLine = Integer.valueOf(source.aupos__c);
        }
        this.docCurrency = source.Dcurr__c;
        this.docNetAmount = source.Dnet__c;
        this.docTaxAmount = source.Dtax__c;
        this.docTotalAmount = source.Dtotal__c;
        if (source.Fecha_Entrega__c != null) {
            this.deliveryDate = source.Fecha_Entrega__c.date();
        }
        this.localCurrency = source.Lcurr__c;
        this.localNetAmount = source.Lnet__c;
        this.localTaxAmount = source.Ltax__c;
        this.localTotalAmount = source.Ltotal__c;
        this.make = source.Make__c;
        this.productName = source.Name__c;
        this.docLine = Integer.valueOf(source.Orderlin__c);
        this.docNumber = source.Ordernum__c;
        this.quantity = source.Quantity__c;
        this.productCode = source.Sku__c;
        this.squareMetres = source.Sqmetres__c;
        this.salesUnit = source.Vrkme__c;
    }

    /**
     * Sets Product2 and apply some conversions
     */
    public void setProduct2(Product2 product) {
        this.Product2 = product2;        
    }
}