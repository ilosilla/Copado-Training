/**
 * @author         Ramón Prades
 * @date           August 2024
 * @layer          Helper
 * @description    Helper class to perform comSAP relatedon tasks on orders
*/
public class SAPOrdersHelper {

    public static List<String> validateOrderForSAP(Order order, Sales_Org__c salesOrg) {
        String[] errors = new List<String>();
        if (order.Version__c != OrdersDomain.VERSION2) {
            return errors;
        } 
        if (salesOrg == null) {
            errors.add('Sales organization not found');
        } else if (String.isNotBlank(salesOrg?.RedirectTo__c)) {
            errors.add('Sales Organization ' + salesOrg.SalesOrg__c + ' does snot accept new orders'); 
        }
        if (order.Status != OrdersDomain.STATUS_ACTIVATED) {
            errors.add('Order status should be "Activated"');
        }
        if (order.SAP_Id__c != null) {
            errors.add('Order is already in SAP');
        } 
        if (String.IsBlank(order.SalesOrg__c)) {
            errors.add('The Sales Organization is required');
        }        
        if (String.IsBlank(order.Distribution_Channel__c)) {
            errors.add('The Distribution Channel is required');
        }         
        if (AccountUtil.getSAPId(order.accountId) == null) {
            errors.add('The account does not exist in SAP');
        }
        if (salesOrg != null && order.CurrencyIsoCode != salesOrg.CurrencyIsoCode) {
            errors.add(String.format('Wrong currency. Order currency is {0}, expected {1}.', new List<Object>{order.CurrencyIsoCode, salesOrg.CurrencyIsoCode}));
        }
        return errors;
    }
}