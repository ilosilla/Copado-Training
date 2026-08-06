/**
 * @author         Ramón Prades
 * @date           June 2024
 * @layer          Service
 * @description    This class deals with the assignation of a pricebook to an order
*/
public class SalesPricebooksService {

    public static final String ORDER_REPLACEMENT_TYPE = 'Z051';
    public static final String ORDER_STANDARD_TYPE = 'ZW04'; 
    public static final String ORDER_FREE_COLLECTION_TYPE = 'Z018_F';

    /**
     * Retrieves the list of applicable pricebooks for a given sales order.
     */
    public static List<Pricebook2> getOrderPricebooks(Order theOrder) {
        // Ensures all required fields are present
        if (String.isBlank(theOrder.Type)) {
            throw new RequiredFieldException('Order.Type');
        }
        List<Pricebook2> books = new List<Pricebook2>();
        try {
            if (theOrder.Type == ORDER_REPLACEMENT_TYPE) {
                books.add(getClaimsPricebook(theOrder.CurrencyIsoCode));
            } else if (theOrder.Type == ORDER_FREE_COLLECTION_TYPE) {
                books.add(getClaimsPricebook(theOrder.CurrencyIsoCode));
            } else {
                books.add(getRetailPricebook(theOrder.SalesOrg__c));
            }
        } catch(ObjectNotFoundException onf) {
            books.clear();
        }
        return books;
    }

    /**
     * Static method to retrieve a claims pricebook, throwing an ObjectNotFound exception if no pricebook is found.
     */
    public static Pricebook2 getClaimsPricebook(String currencyIsoCode) {
        if (String.isBlank(currencyIsoCode)) {
            throw new RequiredFieldException('currencyIsoCode');
        }
        return new PricebooksSelector().selectClaimsPricebook(currencyIsoCode);
    }

    /**
     * Static method to retrieve a retail pricebook, throwing an ObjectNotFound exception if no pricebook is found.
     */
    public static Pricebook2 getRetailPricebook(String salesOrg) {
        return new PricebooksSelector().selectSalesOrgReference(salesOrg);
    }

}