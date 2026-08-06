/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OrderWrapper
     Created Date:      7/02/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Order Wrapper
                        *** Test con B2BCartToOrderDraftTest y NB2B_OrderControllerTest ***
------------------------------------------------------------------------------------------*/
@SuppressWarnings('PMD.ExcessiveParameterList')
global class NB2B_OrderWrapper {

    global String order_id;
    global String opportunity_id;
    global String created_at;
    global String state;
    global String reference;
    global String payment_method;
    global String currencyOrder; 
    global String carrier_code;
    global String shipping_method;
    global Boolean store_pickup;
    global String shipping_incl_tax;
    global String shipping_tax_amount;
    global String total_incl_tax;
    global String total_tax_amount;
    global String discount;
    global String sales_organization;
    global String sales_office;
    global String distribution_channel;
    global String delivery_date;
    global String coupon_code;
    global String delivery_instructions;
    global String comments;
    global String email;
    global Boolean autopick;
    public CustomerWP customer;
    global String order_lines_number;
    public List<OrderLineWP> order_lines;
    public AddressWP shipping_address;

    global NB2B_OrderWrapper(Order order, List<OrderItem> orderItems){

        this.order_id              = order.NB2B_OrderCode__c;
        this.opportunity_id        = order.OpportunityId;
        this.created_at            = order.CreatedDate  != null ? String.valueOf(order.CreatedDate) : null;
        this.state                 = 'Activated';
        this.reference             = order.Client_Reference__c;
        this.payment_method        = '';
        this.currencyOrder         = order.Currency__c;
        this.email			       = order.Account.Business_Email__c;
        this.shipping_address = new AddressWP();
        if(order.NBK_Warehouse_Address__c != null){
            this.shipping_address.sap_id = order.NBK_Warehouse_Address__c  != null ? order.NBK_Warehouse_Address__r.NBK_SAPId__c  : order.Account.SAP_Id__c;
        }else{
	        this.shipping_address.sap_id = order.NBK_Contact_Point_Address__c != null ? order.NBK_Contact_Point_Address__r.SAPId__c : order.Account.SAP_Id__c;            
        }
//        this.shipping_address.sap_id = order.NBK_Contact_Point_Address__c != null ? order.NBK_Contact_Point_Address__r.SAPId__c : order.Account.SAP_Id__c;

        //this.shipping_method       = 'bestway';//It is not essential, commented at the expense of future changes
        if(order.NB2B_Delivery_Method__c != null ){
	        if(order.NB2B_Delivery_Method__c != '3' ){
            	this.store_pickup = true;//New field
            }else{
                this.store_pickup = false;//New field
            }
            
        }else{
			this.store_pickup = order.NB2b_store_pickup__c;//New field            
        }
        this.autopick              = order.Autopick__c;
        this.shipping_incl_tax     = Nb2b_GlobalConstants.ZERO_VALUE;
        this.shipping_tax_amount   = Nb2b_GlobalConstants.ZERO_VALUE;
        this.total_incl_tax        = order.Amount__c != null ? String.valueOf(order.Amount__c) : '';
        this.total_tax_amount      = order.Tax__c != null ? String.valueOf(order.Tax__c) : '';
        this.discount              = Nb2b_GlobalConstants.ZERO_VALUE;
        this.sales_organization    = order.SalesOrg__c; 
        this.sales_office          = order.SalesOffice__c;
        this.distribution_channel  = order.Distribution_channel__c;
        if(order.DeliveryDate__c   != null && order.DeliveryDate__c > Date.today()){
            this.delivery_date     = order.DeliveryDate__c != null ? String.valueOf(order.DeliveryDate__c).replace('-', '.') : null;
        }else{
            Date d = Date.today().addDays(1);
            this.delivery_date     =  String.valueOf(d);
        }
        this.coupon_code           = null;
        this.delivery_instructions = order.Observations__c;
        
        //this.comments              = order.Observations__c;
        //Fill object Customer
        this.customer              = new CustomerWP();
        this.customer.sap_id       = order.Account.SAP_Id__c != null ? String.valueOf(order.Account.SAP_Id__c) : null;
        this.order_lines_number    = order.LineNo__c != null ? String.valueOF(order.LineNo__c) : null;
        //Fill in list of OrderItems
        this.order_lines           = new List<OrderLineWP>();
        for(OrderItem ordIt : orderItems){
            OrderLineWP mapItem          = new OrderLineWP();
            mapItem.line_number          = ordIt.LineNumber; 
            mapItem.order_item_id        = ordIt.Id;
            mapItem.product_sku          = ordIt.Product2.StockKeepingUnit;
            mapItem.is_sample            = order.NBK_Sample__c;
            mapItem.quantity             = ordIt.Quantity != null ? Integer.valueOf(ordIt.Quantity) : null;
            mapItem.quantity_unit        = ordIt.Product2.Umv__c != null ? Nb2b_GlobalConstants.UNITCONVERTOR.get(ordIt.Product2.Umv__c) : ordIt.Product2.Umv__c;
            mapItem.original_price       = ordIt.UnitPrice  != null ? String.valueOf(ordIt.UnitPrice) : null;
            mapItem.price_unit           = ordIt.Product2.Umv__c != null ? Nb2b_GlobalConstants.UNITCONVERTOR.get(ordIt.Product2.Umv__c) : ordIt.Product2.Umv__c;
            //mapItem.price_unit           = 'TODO';//Commented for invalid value, pending to know value per client
            mapItem.row_total_incl_tax   = ordIt.ListPrice != null ? String.valueOf(ordIt.ListPrice) : null;
            mapItem.row_total_tax_amount = ordIt.NB2B_TaxAmount__c != null ? String.valueOf(ordIt.NB2B_TaxAmount__c) : null;
            mapItem.discount             = Nb2b_GlobalConstants.ZERO_VALUE;
            mapItem.shade                = ordIt.NB2B_Shade__c;
            this.order_lines.add(mapItem);
        }
        
    }

    global NB2B_OrderWrapper(Order order, List<OrderItem> orderItems, String accSapId, Map<Id,Product2> productSkuMap){

        this.order_id              = order.NB2B_OrderCode__c;
        this.opportunity_id        = order.OpportunityId;
        this.created_at            = order.CreatedDate  != null ? String.valueOf(order.CreatedDate) : null;
        this.state                 = 'Activated';
        this.reference             = order.Client_Reference__c;
        this.payment_method        = '';
        this.currencyOrder         = order.Currency__c;
        this.shipping_address = new AddressWP();
        this.shipping_address.sap_id = order.NB2B_DeliveryCode__c;

        //this.shipping_method       = 'bestway';//It is not essential, commented at the expense of future changes
        this.autopick              = order.Autopick__c;
        this.store_pickup          = order.NB2b_store_pickup__c;//New field
        this.shipping_incl_tax     = Nb2b_GlobalConstants.ZERO_VALUE;
        this.shipping_tax_amount   = Nb2b_GlobalConstants.ZERO_VALUE;
        this.total_incl_tax        = order.Amount__c != null ? String.valueOf(order.Amount__c) : '';
        this.total_tax_amount      = order.Tax__c != null ? String.valueOf(order.Tax__c) : '';
        this.discount              = Nb2b_GlobalConstants.ZERO_VALUE;
        this.sales_organization    = order.SalesOrg__c; 
        this.sales_office          = order.SalesOffice__c;
        this.distribution_channel  = order.Distribution_channel__c;
        this.email				   = order.BillingEmailAddress;
        if(order.DeliveryDate__c   != null && order.DeliveryDate__c > Date.today()){
            this.delivery_date     = order.DeliveryDate__c != null ? String.valueOf(order.DeliveryDate__c).replace('-', '.') : null;
        }else{
            Date d = Date.today().addDays(1);
            this.delivery_date     =  String.valueOf(d);
        }
        this.coupon_code           = null;
        this.delivery_instructions = order.Observations__c;
        
        //this.comments              = order.Observations__c;
        //Fill object Customer
        this.customer              = new CustomerWP();
        this.customer.sap_id       = accSapId;
        this.order_lines_number    = order.LineNo__c != null ? String.valueOF(order.LineNo__c) : null;
        //Fill in list of OrderItems
        this.order_lines           = new List<OrderLineWP>();
        for(OrderItem ordIt : orderItems){
            OrderLineWP mapItem          = new OrderLineWP();
            mapItem.line_number          = ordIt.LineNumber; 
            mapItem.order_item_id        = ordIt.Id;
            mapItem.product_sku          = productSkuMap.get(ordIt.Product2Id).StockKeepingUnit;
            mapItem.is_sample            = false;
            mapItem.quantity             = ordIt.Quantity != null ? Integer.valueOf(ordIt.Quantity) : null;
            
            mapItem.quantity_unit        = productSkuMap.get(ordIt.Product2Id).Umv__c != null ? Nb2b_GlobalConstants.UNITCONVERTOR.get(productSkuMap.get(ordIt.Product2Id).Umv__c) : productSkuMap.get(ordIt.Product2Id).Umv__c;
            mapItem.original_price       = ordIt.UnitPrice  != null ? String.valueOf(ordIt.UnitPrice) : null;
            mapItem.price_unit           = productSkuMap.get(ordIt.Product2Id).Umv__c != null ? Nb2b_GlobalConstants.UNITCONVERTOR.get(productSkuMap.get(ordIt.Product2Id).Umv__c) : productSkuMap.get(ordIt.Product2Id).Umv__c;
            //mapItem.price_unit           = 'TODO';//Commented for invalid value, pending to know value per client
            mapItem.row_total_incl_tax   = ordIt.ListPrice != null ? String.valueOf(ordIt.ListPrice) : null;
            mapItem.row_total_tax_amount = ordIt.NB2B_TaxAmount__c != null ? String.valueOf(ordIt.NB2B_TaxAmount__c) : null;
            mapItem.discount             = Nb2b_GlobalConstants.ZERO_VALUE;
            mapItem.shade                = ordIt.NB2B_Shade__c;
            this.order_lines.add(mapItem);
        }
        
    }

    //Object Customer, 'customer' in JSON
    public class CustomerWP{
        public String sap_id;
    }
    public class AddressWP{
        public String sap_id;
    }
     //Object OrderItem, 'order_lines' in JSON
    public class OrderLineWP{
        public Integer line_number; 
        public String order_item_id;
        public String product_sku;
        public Boolean is_sample;
        public Integer quantity;
        public String quantity_unit;
        public String original_price;
        public String price_unit;
        public String row_total_incl_tax;
        public String row_total_tax_amount;
        public String discount;
        public String shade;
    }
}