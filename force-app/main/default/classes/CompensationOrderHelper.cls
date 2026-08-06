/**
 * @author         Ramón Prades
 * @date           August 2024
 * @layer          Services
 * @description    Helper to create a good will compensation credit
 * 
 * Translation prefix: tr0005_3xx
*/
public with sharing class CompensationOrderHelper {

    public static final String COMPENSATION_PRODUCT = 'S_INDEMNIZ_PROD';

    private Id caseId;    
    private Order order;
    private OrderItem orderItem;
    private OrderItemTaxLineItem orderItemTax;

    private Id compensationProductId = null;


    public CompensationOrderHelper(Id caseId) {
        this.caseId = caseId;
    }

    public void setCompensationProductId(Id productId) {
        this.compensationProductId = productId;
    }

    public Id create() {

        // Order header
        Case c = new CasesSelector().selectById(new Set<Id>{this.caseId})[0];
        this.order = new Order();
        this.order.Version__c = OrdersDomain.VERSION2;
        this.order.Type = OrdersDomain.CREDIT_REQUEST_TYPE;
        this.order.AccountId = c.AccountId;
        this.order.SalesOrg__c = c.SalesOrg__c;
        this.order.Distribution_channel__c = c.DistributionChannel__c;
        this.order.ReferredInvoice__c = c.SAPInvoice__c;
        this.order.CurrencyIsoCode = c.CurrencyIsoCode;
        this.order.Status = OrdersDomain.STATUS_DRAFT;
        this.order.Typology__c = c.Liability__c;
        this.order.PONumber = 'CLAIM ' + c.CaseNumber;

        // Searches te ID of the compensation product
        if (this.compensationProductId == null) {
            Product2[] pids = [select Id from Product2 where StockKeepingUnit = :COMPENSATION_PRODUCT];                        
            if (pids.size() == 0) {
                throw new ContextException(System.Label.tr0005_305.replace('{0}', COMPENSATION_PRODUCT)); // Compensation product {0} not found
            }
            this.compensationProductId = pids[0].Id;
        }

        // Order items
        Decimal percent = TaxCommons.getSalesOrgTax(this.order.SalesOrg__c);
        String unit = 'UN';
        Decimal netAmount = c.Compensation__c / (1 + percent / 100) ; 
        Decimal taxAmount = c.Compensation__c - netAmount;
        this.orderItem = new OrderItem();
        this.orderItem.Product2Id = this.compensationProductId;
        this.orderItem.CustomName__c = 'CLAIM ' + c.CaseNumber + '-' + this.order.ReferredInvoice__c;
        this.orderItem.Quantity = 1;
        this.orderItem.SalesUnit__c = unit;
        this.orderItem.UnitPrice = netAmount;
        this.orderItem.UnitPriceUnitCode__c = unit;
        this.orderItem.ListPrice = netAmount;
        this.orderItem.ListPriceUnitCode__c = unit;
        this.orderItem.ReferredLine__c = c.SAPInvoiceLine__c;

        // @TODO - Gestionar impuestos en OrderItemTaxLineItem
        this.orderItemTax = new OrderItemTaxLineItem();
        this.orderItemTax.Amount = taxAmount;
        this.orderItemTax.TaxEffectiveDate = System.today();        
        this.orderItemTax.Type = 'Estimated';
        this.orderItemTax.Name = 'VAT';        

        this.validate();

        OrdersService.saveOrder(this.order, new List<OrderItem>{this.orderItem});

        this.orderItemTax.OrderItemId = this.orderItem.Id;
        insert this.orderItemTax;

        /*
        String[] errors = result.get(this.order.Id);
        if (errors.size() > 0) {
            throw new ErrorListException(errors);
        }
        */

        this.order.Status = OrdersDomain.STATUS_ACTIVATED;
        update this.order;

        return this.order.Id;
    }

    private void validate() {
        Sales_Org__c org = new SalesOrgsSelector().selectBySAPId(new Set<String>  {this.order.SalesOrg__c})[0];        
        // Validate currency
        if (org.CurrencyIsoCode != this.order.CurrencyIsoCode) {
            throw new ValidationException(System.Label.tr0005_306.replace('{0}', org.CurrencyIsoCode)); // Wrong currency. {0} expected.
        }

    }

}