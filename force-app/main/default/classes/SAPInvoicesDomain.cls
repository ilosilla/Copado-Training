/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		SAP
* @description 	SAP Invoices domain class
*/
public class SAPInvoicesDomain extends zflib_DomainClass {

    /**
     * Searches the Product2 and apply conversions to invoice lines
     */
    public static void applyProduct2ToLines(SAPInvoiceLine[] lines) {
        String[] pcodes = new List<String>();
        for(SAPInvoiceLine line : lines) {
            if (!pcodes.contains(line.productCode)) {
                pcodes.add(line.productCode);
            }
        }
        /*****
        if (pcodes.size() > 0) {
            List<Product2> products = new ProductsSelector().selectByProductCode(pcodes);
        }
        Map<String, Product2> productsMap = new Map<String, Product2>();
        for (Product2 product : products) {
            productsMap.put(product.ProductCode, product);
        }
        for(SAPInvoiceLine line : lines) {
            if (productsMap.containsKey(line.productCode)) {
                line.setProduct2(productsMap.get(line.productCode));
            }
        }
        ****/
    } //




    public static Integer foolTest() {
        String lorem = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        lorem += 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut quis tellus nec lectus elementum bibendum. Nulla facilisi.';
        return lorem.length();
    }
    


}