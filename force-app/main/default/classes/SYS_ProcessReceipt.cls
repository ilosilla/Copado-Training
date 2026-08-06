/**
 * @author         Ramón Prades
 * @date           October 2025
 * @layer          layer
 * @description    description
 *      Utility class that manages the unique execution registration
 *      mechanism (Process Receipt) to ensure that each integration
 *      or process identified by a (namespace, key) pair is executed
 *      only once. It allows:
 *            - Verifying if a receipt already exists in the database.
 *            - Creating a new receipt entry when processing starts.
 *            - Updating fields such as notes or success status.
 * 
 *       Design Notes:
 *          - The record is uniquely identified by the combination of:
 *              * Namespace__c (logical process group)
 *              * Key__c (unique key for each execution)
 *          - Typical usage pattern:
 *              SYS_ProcessReceipt receipt = new SYS_ProcessReceipt('CPI', 'ORDER-123');
 *              if (receipt.exists()) return; // already processed
 *              receipt.register();
 *              ... do work ...
 *              receipt.save(true, 'Order successfully integrated');
 *
 * -----------------------------------------------------------------------------
 */
public class SYS_ProcessReceipt {
    
    private SYS_ProcessReceipt__c receipt;
    
    public SYS_ProcessReceipt(String namespace, String dedupKey) {
        receipt = new SYS_ProcessReceipt__c();
        receipt.Namespace__c = namespace;
        receipt.DedupKey__c = dedupKey;
        receipt.Key__c = SYS_ProcessReceiptsDomain.buildKey(namespace, dedupKey);
    }   

    public Boolean exists() {
        SYS_ProcessReceipt__c[] results = new SYS_ProcessReceiptsSelector().selectByKey(new Set<String>{this.receipt.Key__c});
        return (results.size() > 0);
    }

    public SYS_ProcessReceipt__c save(Boolean success, String notes) {
        this.receipt.Success__c = success;
        this.receipt.Notes__c = notes;
        insert this.receipt;
        return this.receipt;
    }

}