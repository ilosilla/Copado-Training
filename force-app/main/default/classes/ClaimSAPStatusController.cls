/**
 * @author         Ramón Prades
 * @date           March 2025
 * @layer          Controller
 * @description    claimSAPStatus
*/
public class ClaimSAPStatusController {
    
    @AuraEnabled public static OrderStatusDTO getOrderStatus(Id orderId) {
        OrderStatusDTO dto = null;
        SAPRequestQueue__c[] items = [
            select Id, RequesterId__c, Message__c, Status__c, toLabel(Status__c) StatusLabel, CreatedDate, SAPKey__c  
                from SAPRequestQueue__c 
                where RequesterId__c = :orderId
                order by CreatedDate desc
            ];
        if (items.size() > 0) {
            dto = new OrderStatusDTO();
            SAPRequestQueue__c item = items[0];     
            dto.requestId = item.Id;       
            dto.orderId = item.RequesterID__c;
            dto.requestStatus = item.Status__c;
            dto.requestStatusLabel = (String) item.get('StatusLabel');
            dto.errorMessage = item.Message__c;
            dto.sapKey = item.SAPKey__c;
            dto.hasError = (dto.requestStatus == 'ERROR' || dto.requestStatus == 'EXCEPTION');
            if (!dto.hasError && dto.requestStatus == 'QUEUED') {
                // Add a warning if the order is at least 10 minutes as QUEUED
                if (Datetime.now() >= item.CreatedDate.addMinutes(10)) {
                    dto.errorMessage = System.Label.claim_label_020;
                }
            }            
        }
        return dto;
    }

    public class OrderStatusDTO {
        @AuraEnabled public Id orderId { get; set; }
        @AuraEnabled public Id requestId { get; set; }
        @AuraEnabled public String requestStatus { get; set; }
        @AuraEnabled public String requestStatusLabel { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public String sapKey { get; set; }
        @AuraEnabled public Boolean hasError { get; set; }
    }
}