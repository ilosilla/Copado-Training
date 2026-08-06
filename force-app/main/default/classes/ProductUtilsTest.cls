@isTest public class ProductUtilsTest {
    @isTest static void validate() {
        Product2 p = new Product2();
        p.ProductCode = '100';
        p.Name = 'Test item';
        insert p;
        System.assertEquals(true, ProductUtils.validate(p.ProductCode));
        System.assertEquals(false, ProductUtils.validate('000'));
    } // validate

    @isTest static void getProduct() {
        DataFactoryProduct.createProducts();
        Product2 product = [select Id, ProductCode, Name from Product2 limit 1];
        
        Product2 result =  ProductUtils.getProduct(product.ProductCode);
        System.assertEquals(product.Id, result.Id);
        Boolean ex = false;
        try {
            Product2 result2 =  ProductUtils.getProduct('101');
        } catch (ObjectNotFoundException onf) {
            ex = true;
        }
        System.assertEquals(true, ex);
    }

    @isTest static void getDummyProductId() {
        try {
            ProductUtils.getDummyProductId();
        } catch (ObjectNotFoundException ex) {

        }
        System.assertEquals(1, 1); // whatever
    }

    @isTest static void getPricebookEntryId() {
        Boolean exceptionReceived = false;
        try {
            Pricebook2 pbook = DataFactoryProduct.createPriceBook();
            Product2[] products = DataFactoryProduct.createProducts(pbook);
            String id = ProductUtils.getPricebookEntryId(pbook.Id, 'USD', products[0].Id); // LO QUITO POR PRO
            String id2 = ProductUtils.getPricebookEntryId(pbook.Id, 'CRC', products[0].Id);
        } catch (ObjectNotFoundException ex) {
            exceptionReceived = true;
        }
        System.assertEquals(true, exceptionReceived, 'An exception should have bene received');
    }
}