/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		Cases
* @description  Services to create cases related to a SAP document (mainly invoices)
*/
public class SAPOrderCreator {
    // Class properties
    public Boolean isCredit = false;
    public String sapCustomer;
    public String sapInvoice;
    public String orderReason;
    public Boolean applyRestockingFee = false;
    public Date orderDate = System.today();
    public Date deliveryDate;
    public String deliverTo;
    public String reference;
    public OrderItem[] items;
    public String jsonString { get; private set;}
    public String orderNumber;
    public Boolean success = true;
    public String errorMessage;
    public String warehouse;
    public Boolean storePickup = false;
    
    // Private properties
    private String operationType;
    private String operationDescription;
    private Decimal restockingCharges;

    public SAPOrderCreator() {
        items = new List<OrderItem>();
        this.orderNumber = null;
        this.success = false;
        this.errorMessage = '';
    }

    public String create() {
        SystemLog logger = new SystemLog('ORDER');
        logger.setTag('SAPOrderCreator.create');        
        this.jsonString = this.buildJSON();        
        logger.setInputData(this.jsonString);
        logger.saveLog();
        SAPProxy proxy = new SAPProxy(SAPProxy.ORDERS_V2_SERVICE);
        proxy.method = 'POST';
        proxy.inputJSON = this.jsonString;
        if (proxy.connectToSAP()) {
            logger.addInfo('Se ha recibido el JSON ' + proxy.receivedJSON);
            this.parseReceivedJSON(proxy.receivedJSON);
            logger.setSummary('Order created');
            logger.saveLog(true);
        } else {
            logger.addError('Error creating the order!');
            List<SAPProxy.SAPResponse> responses = proxy.getResponse();
            List<String> messages = new List<String>();
            for (SAPProxy.SAPResponse response : responses) {
                if (!response.success) {
                    messages.add(response.error.message);
                    logger.addError('Error message: ' + response.error.message);                    
                }
            }
            if (messages.size() == 0) {
                messages.add('Unknown error received when creating the order in SAP');
            }            
            logger.setSummary('Error creating order');
            SystemLog.writeLog(JSON.serialize(logger));
            throw new ErrorListException(messages);
        }
        return '0';
    }

    public Decimal getRestockingCharges() {
        return this.restockingCharges;
    }


    //----------------------------------------------------------

    private void parseReceivedJSON(String rjson) {
        // The service returns the order number in the field "number" but this is a reserved word in apex so we have to change it
        String cooked = rjson.replace('"number"', '"orderNumber"');
        cooked = cooked.replace('"NUMBER"', '"orderNumber"');
        cooked = cooked.replace('"Number"', '"orderNumber"');
        List<SAPResponse> results =  (List<SAPResponse>) JSON.deserialize(cooked, List<SAPResponse>.class);
        if (results.size() > 0) {
            this.success = results[0].success;
            if (this.success) {
                this.orderNumber = results[0].orderNumber;
                this.restockingCharges = results[0].RestockingCharges;
            } else if (results[0].error != null) {
                this.errorMessage = results[0].error.message;
            }
        } 
    }

    private String buildJSON() {

        this.setOperationType();

        JSONGenerator jsonGen = JSON.createGenerator(true);
        jsonGen.writeStartArray();              // Staert of main array
        jsonGen.writeStartObject();             // start of main object
        jsonGen.writeFieldName('order');        
        jsonGen.writeStartObject();             // start of order

        // Header
        jsonGen.writeStringField('operationType', this.operationType);
        jsonGen.writeStringField('operationDescription', this.operationDescription);
        jsonGen.writeStringField('requestedBy', String.valueOf(this.sapCustomer));
        jsonGen.writeDateField('date', this.orderDate);
        jsonGen.writeStringField('email', UserInfo.getUserEmail());
        jsonGen.writeStringField('reference', String.valueOf(this.sapInvoice));
        jsonGen.writeStringField('invoice', String.valueOf(this.sapInvoice));
        if (this.storePickup) {
            jsonGen.writeBooleanField('storePickup', this.storePickup);
        }
        if (String.isNotBlank(this.warehouse)) {
            jsonGen.writeStringField('warehouse', String.valueOf(this.warehouse));
        }
        jsonGen.writeBooleanField('applyRestockingCharges', this.applyRestockingFee);
        if (this.orderReason != null) {
            jsonGen.writeStringField('orderReason', String.valueOf(this.orderReason));
        }
        if (this.deliveryDate != null) {
            jsonGen.writeDateField('deliverydate', this.deliveryDate);
        }
        if (this.deliverTo != null) {
            jsonGen.writeStringField('deliverTo', this.deliverTo);
        }

        // Items
        jsonGen.writeFieldName('items');
        jsonGen.writeStartArray();              // Array of items
        for (OrderItem item : this.items ) {
            jsonGen.writeStartObject();
            jsonGen.writeStringField('lineRef', String.valueOf(item.lineReference));
            jsonGen.writeStringField('productCode', item.productCode);
            jsonGen.writeStringField('unit', item.unitCode);
            //jsonGen.writeNumberField('quantity', item.quantity);
            jsonGen.writeStringField('quantity', String.valueOf(item.quantity));
            jsonGen.writeEndObject();
        }
        jsonGen.writeEndArray();                // End of array of items
        jsonGen.writeEndObject();               // End of order 
        jsonGen.writeEndObject();               // End of main object
        jsonGen.writeEndArray();                // End of main array   
        return jsonGen.getAsString();

    } // buildJSON

    /*
     * 00 - Standard Order
     * 01 - Consignment Order
     * 02 - Consignment Sale
     * 10 - Customer Return
     */
    private void setOperationType() {
        if (this.isCredit) {
            this.operationType = '10';
            this.operationDescription = 'Customer Return';
        } else {
            this.operationType = '00';
            this.operationDescription = 'Standard Order';
        }
    } // setOperationType

    //------------------------------------------------------------------------------
    public class OrderItem {
        public Integer lineReference;       // Invoice line credited (for credits only)
        public String productCode;
        public String unitCode;
        public Double quantity;
    }

    private class SAPError {
        private String id;
        private String type;
        private String message;
    }

    public class SAPResponse {
        public Integer index;
        public Boolean success;
        public String orderNumber;
        public String dellivery;
        public SAPError error;
        public Decimal RestockingCharges;
    }


    
} // class