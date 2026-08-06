({
    getLabel: function(docType) {
        var label = "";        
        switch(docType) {
                
            case "SALES_QUOTE":
                label = $A.get("$Label.c.sap_sales_quote");
                break;

            case "SALES_ORDER":
                label = $A.get("$Label.c.sap_sales_order");
                break;

            case "SALES_INVOICE":
                label = $A.get("$Label.c.sap_sales_invoice");
                break;

            case "PURCHASE_ORDER":
                label = $A.get("$Label.c.sap_purchase_order");
                break;
                
            default:
            	label = $A.get("$Label.c.sap_document");      
                break;
        } // switch	     
        return label;        
	} // getlabel

})