/**
 * @author         Ramón Prades
 * @date           June 2024
 * @layer          Commons
 * @description    Common methods related to basic pricing operations
*/
public class PricingCommons {
    
    public static Map<Id, PricebookEntry> getPricebookEntries(Id pricebookId, String currencyCode, Set<Id> productIds) {
        List<PricebookEntry> entries = new PricebookEntriesSelector().selectByPricebook(pricebookId, currencyCode, productIds);
        Map<Id, PricebookEntry> entriesMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry entry : entries) {
            entriesMap.put(entry.Product2Id, entry);
        }        
        return entriesMap;
    }
}