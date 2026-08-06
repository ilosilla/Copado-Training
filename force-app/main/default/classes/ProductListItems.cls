/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		Leads
* @description 	Domain class for Product List Item object
*/
public class ProductListItems {

    private List<ProductListItem__c> records;
    
    /**
     * Constructor
     */
    public ProductListItems(List<ProductListItem__c> records) {
        this.records = records;
    } // Constructor


}