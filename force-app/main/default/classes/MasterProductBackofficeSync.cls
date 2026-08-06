/**
* @author 		Ramón Prades
* @date 		December 2024
* @group 		Products
* @description 	Syncs product related objects that are imported form SAP
* ----------------------------------------------------------------------------------------------------------------
*/
global class MasterProductBackofficeSync {

    Boolean syncItemGroups = true;
    Map<String, SObject> currentItemGroups; 
    T023T__x[] testItems = new List<T023T__x>();

    global MasterProductBackofficeSync() {
        this.currentItemGroups = this.readItemGroups();
    }

    global void setSyncItemGroups(Boolean value) {
        this.syncItemGroups = value;
    }

    public Integer sync() {
        return this.syncItemsObject();
    }

    public void setTestData(List<T023T__x> data) {
        if (Test.isRunningTest()) {
            this.testItems = data;
        }
    }
    
     /* ====================================================================================== */

     private Integer syncItemsObject() {
        Integer nrecords = 0;
        List<ItemGroup__c> newItems = new List<ItemGroup__c>();        
        List<T023T__x> sapItems = this.getSAPItems();
        for (T023T__x sapItem :sapItems) {
            if (!this.currentItemGroups.containsKey(sapItem.Matkl__c.toUpperCase())) {
                ItemGroup__c newItem = new ItemGroup__c();
                newItem.SAPGroup__c = sapItem.Matkl__c;
                newItem.Name = sapItem.Wgbez60__c;
                newItems.add(newItem);
                nRecords++;
                if (newItems.size() == 200) {
                    insert newItems;
                    newItems.clear();
                }
            }
        }
        if (newItems.size() > 0) {
            insert newItems;
        }
        return nRecords;
    }   

    private Map<String, SObject> readItemGroups() {
        SObject[] items = (List<SObject>) [select Id, Name, SAPGroup__c from ItemGroup__c];
        return TypeConversionCommons.listToMap(items, 'SAPGroup__c', true);
    }

    private List<T023T__x> getSAPItems() {
        String lang  = 'EN';       
        if (Test.isRunningTest()) {
            return this.testItems;
        } else {
            return [select ExternalId, Matkl__c, Spras__c, Wgbez60__c from T023T__x where Spras__c = :lang];
        }
    }

}