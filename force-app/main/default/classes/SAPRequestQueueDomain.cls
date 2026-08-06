/**
 * @author         Ramón Prades
 * @date           July 2024
 * @layer          Domain
 * @description    descriptionSAP Request Queue domain class
*/
public class SAPRequestQueueDomain  extends zflib_TriggerDomainClass {  

    public override zflib_TriggerDomainClass cast() {
        return (SAPRequestQueueDomain) this;
    } 

    public override Type getSObjectType() {
        return SAPRequestQueueDomain.class;
    }

    public override void onAfterInsert() { 
        SAPRequestDispatcher.processQueue();
    }

    public override void onApplyDefaults() {  
        if (this.isInsert) {       
            for (SAPRequestQueue__c item : (List<SAPRequestQueue__c>) this.Records) {
                if (item.ActionRequested__c == 'CREATE' && !item.AllowDuplicates__c) {
                    item.UniqueKey__c = 'CREATE-' + item.RequesterID__c;               
                }
            }
        }
    }
    
} // class