/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		System Utilitiers
* @description 	Trigger for Process Receipt
*
* *TEST WITH SYS_ProcessReceiptsTest*
*
*/
public class SYS_ProcessReceiptsDomain extends zflib_TriggerDomainClass {

    public static String buildKey(String namespace, String dedupKey) {
        return namespace?.toUpperCase() + '-' + dedupKey?.toUpperCase();
    }
    
    public SYS_ProcessReceiptsDomain() {
        super();
    }

    public SYS_ProcessReceiptsDomain(List<SYS_ProcessReceipt__c> receipts) {
        super(receipts);
    }

    public override zflib_TriggerDomainClass cast() {
        return (SYS_ProcessReceiptsDomain) this;
    } 

    public override Type getSObjectType() {
        return SYS_ProcessReceiptsDomain.class;
    }

    public override void onBeforeInsert() { 
        for (SYS_ProcessReceipt__c receipt : (List<SYS_ProcessReceipt__c>)this.Records) {
            receipt.Key__c = buildKey(receipt.Namespace__c, receipt.DedupKey__c);
            receipt.Name = (receipt.Name ?? receipt.Namespace__c);
        }
    }
}