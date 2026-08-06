@isTest public with sharing class B2B_PLPControllerTest {


    @isTest(SeeAllData=true) private static void test001() {
        // --- Setup ---
        DataFactoryEcommerce factory = new DataFactoryEcommerce();
        factory.buildEcommerce();    
        factory.createCart();
        // B2B_CommerceCartAdapter.CommerceCartData cartData = B2B_CommerceCartAdapter.getCartData(factory.StoreId, cart.Id);

        List<B2B_PLPController.PLPProductRefDTO> productRefs = new List<B2B_PLPController.PLPProductRefDTO>();
        for (Product2 p : factory.Products) {
            B2B_PLPController.PLPProductRefDTO ref = new B2B_PLPController.PLPProductRefDTO();
            ref.productId = p.Id;
            ref.sku = p.StockKeepingUnit;
            productRefs.add(ref);
        }
        
        Test.startTest();
        B2B_PLPController.PLPContextDTO dto = B2B_PLPController.getPLPContext(factory.buyerGroupId, 'USD', true, false);
        dto.stockEnabled = true;
        List<B2B_PLPController.PLPItemDTO> items = B2B_PLPController.loadPLPData(dto, productRefs);
        Test.stopTest();
        Assert.isNotNull(items, 'Items should not be null');
    }


}