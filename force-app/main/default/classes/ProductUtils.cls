/**
* @author 		Ramón Prades
* @date 		January 2022
* @group 		Utils
* @description 	Utility method for Product2 object 
*/
public class ProductUtils {

    /**
     * Validates a SAP product code exists on Product2
     */
    public static Boolean validate(String code) {
        Product2[] ps = [select Id, Name from Product2 where ProductCode = :code ];
        return (ps.size() > 0);
    } // validate

    /**
     * Reads a product 
     */
    public static Product2 getProduct(String sapCode) {
        Product2[] products = [select fields(STANDARD), Umv__c, Umb__c, UmbKg__c, UmbCj__c, UmbMt2__c, UmbPal__c, Marca__c
            from Product2 where ProductCode = :sapCode];
        if (products.size() > 0) {
            return products[0];
        } else {
            throw new ObjectNotFoundException();
        }
    } // getProduct

    /**
     * Returns the dummy product id
     */
    public static Id getDummyProductId() {
        Product2 p = ProductUtils.getProduct(SystemSettings.dummyProduct);
        return p.Id;
    } // getDummyProductId

    /**
     * Returns a Pricebook Entry Id
     */
    public static Id getPricebookEntryId(Id pricebook2Id, String currencyIsoCode, Id product2Id) {
        PricebookEntry[] entries = [select Id from PricebookEntry where pricebook2Id = :pricebook2Id 
                                    and Product2Id = :product2Id 
                                    and currencyIsoCode = :currencyIsoCode];
        if (entries.size() > 0) {
            return entries[0].Id;
        } else {
            throw new ObjectNotFoundException('Product ' + product2Id + ' not found in pricebook ' + pricebook2Id + ' and currency ' + currencyIsoCode);
        }
    } // getPricebookEntryId


} // class