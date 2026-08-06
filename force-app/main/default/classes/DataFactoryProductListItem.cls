/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		DataFactories   
* @description 	Data factory
*/
public class DataFactoryProductListItem {
    
    public static ProductListItem__c[] createCollectionCaseItems() {
        
        ProductListItem__c[] items = new List<ProductListItem__c>();
        
        if (Test.isRunningTest()) {
            Product2[] products = DataFactoryProduct.createProducts(null);
            Case c = DataFactoryCase.createCollections(1)[0];
            for (Integer i = 0; i<products.size(); i++) {
                ProductListItem__c item = new ProductListItem__c();
                item.Product__c = products[i].Id;
                item.Case__c = c.Id;
                item.Name__c = products[i].Name;
                item.ProductCode__c = products[i].ProductCode;
                item.Quantity__c = 1;
                item.Unit__c = products[i].Umv__c;
                items.add(item);
            }             
            insert items;
        }
        
        return items;                        

    }
} // class