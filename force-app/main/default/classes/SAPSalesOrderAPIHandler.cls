/**
 * @author         Ramón Prades
 * @date           April 2024
 * @group          SAP
 * @description    Parses the response received from SAP when a sales order is created 
 * 
 * Translation Prefix: tr0005
 * 
 */
public class SAPSalesOrderAPIHandler extends SAPAbstractAPIHandler {

    private static final String DEFAULT_SUPPORT_MAIL = 'ramon.prades@gmail.com'; //salesforce@porcelanosagrupo.com';
    private static final String SETTING_KEY = 'ERROR-MANAGEMENT';
    private static final String SETTING_SUBKEY = 'ORDER-ACTIVATION-ERROR';


    public override String getServiceName() {
        return SAPProxy.ORDERS_V2_SERVICE;
    }

    public override SAPAbstractAPISerializer getSerializer() {
        SAPSalesOrderSerializer ser = new SAPSalesOrderSerializer();
        ser.setEmail(UserInfo.getUserEmail());
        return (SAPAbstractAPISerializer) ser;
    }

    public override String processResponse(Id requesterId, Integer httpStatusCode, String response) {
        String sapOrderNumber = '';
        SuccessDTO[] dtos = (List<SuccessDTO>) JSON.deserialize(transformResponse(response), List<SuccessDTO>.class);
        if (dtos.size() > 0) {
            sapOrderNumber = dtos[0].OrderNumber;            
            OrdersService.setSAPOrderNumber(requesterId, sapOrderNumber);
            this.emailUser(requesterId, sapOrderNumber);
        }
        return sapOrderNumber;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public override void processError(Id requesterId, Integer httpStatusCode, String message, String details) {
        String supportMail = '';
        try {
            PorcelanosaSetting setting = new PorcelanosaSetting(SETTING_KEY, SETTING_SUBKEY);
            supportMail = setting.value1;
        } catch (ObjectNotFoundException onf) {
            supportMail = DEFAULT_SUPPORT_MAIL;
        }
        Order order = (Order) new OrdersSelector().selectSingle(requesterId);
        String url = '';
        if (this.sapRequest?.Id != null) {
            url = SystemCommons.getObjectURL(this.sapRequest.Id);
        } 
        String moreDetails = details + '<br/> SAP_Request__c: ' +  url;
        List<String> addresses = new List<String>{supportMail};
        User[] owners = [select Id, FirstName, Email from User where Id = :this.sapRequest?.OwnerId];
        if (owners.size() > 0) {
            addresses.add(owners[0].Email);
        }
        String subject = System.label.tr0005_021.replace('{0}', order.OrderNumber);
        String body = System.label.tr0005_022
                            .replace('{0}', (this.sapRequest.Owner.FirstName ?? ''))
                            .replace('{1}', order.OrderNumber)
                            .replace('{2}', '[' + String.valueOf(httpStatusCode) + '] ' + message)
                            .replace('{3}', moreDetails);

        Mail m = new Mail();
        m.setTo(addresses);
        m.setSubject('[SAPRequestQueue] ' + subject);
        m.setHtml(body);
        m.send();
    }

    private void emailUser(Id requesterId, String sapOrderNumber) {
        Order order = (Order) new OrdersSelector().selectSingle(requesterId);
        String url = SystemCommons.getObjectURL(order.Id);
        List<String> addresses = new List<String>{this.sapRequest.Owner?.Email};
        String subject = System.label.tr0005_023.replace('{0}', order.OrderNumber);
        String body = System.label.tr0005_024.replace('{0}', (this.sapRequest?.Owner?.FirstName ?? ''));
        body = body.replace('{1}', url);
        body = body.replace('{2}', order?.OrderNumber ?? '0');
        body = body.replace('{3}', sapOrderNumber ?? '');
        Mail m = new Mail();
        m.setTo(addresses);
        m.setSubject('[SAPRequestQueue] ' + subject);
        m.setHtml(body);
        m.send();

    }

    public override String parseErrors(Id requestedId, String response) {
        String message = '';
        ErrorDTO[] errors = (List<ErrorDTO>) JSON.deserialize(this.transformResponse(response), List<ErrorDTO>.class);
        if (errors.size() > 0) {
            message = errors[0].Error.Message;
        }
        return message;
    }

    private String transformResponse(String response) {
        return response.replace('"NUMBER"', '"orderNumber"');        
    }

    public class SuccessDTO {
        public Integer Index;
        public Boolean Success;
        public String OrderNumber;
        public String Delivery;
        public Decimal RestockingCharges;
        public String SourceOrderID;
    }

    public class ErrorDTO {
        public Integer Index;
        public Boolean Success;
        public String SourceOrderID;
        public RESTError Error;    
    }

    public class RESTError {
        public String ID;
        public String Type;
        public String Message;
    }

}