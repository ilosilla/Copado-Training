/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		DataFactories   
* @description 	Data factory toc reate E-Commerce structures (Store, Products, EntitlementPolicies, etc)
*/
public with sharing class DataFactoryECommerce {

    public Id StoreId;
    public Id CartId;
    public Id AccountId;
    public Id BuyerGroupId;
    public Id PricebookId;
    public String CurrencyIsoCode = 'USD';
    public List<Product2> Products;
    
    public DataFactoryECommerce() {
        if (!Test.isRunningTest()) {
            throw new ContextException('This class can only be executed in test mode');
        }
    }

    public void buildEcommerce() {
        Account acc = DataFactoryAccount.createAccounts(1)[0];
        this.AccountId = acc.Id;

        // Crea la tienda
        WebStore store = this.createStore('US TEST STORE');
        this.StoreId = store.Id;

        // Habilita el buyer account
        BuyerAccount buyerAcc = new BuyerAccount();
        buyerAcc.BuyerId = acc.Id;
        buyerAcc.IsActive = true;
        buyerAcc.Name = 'Buyer Account for ' + acc.Name;
        insert buyerAcc;

        // Crea el Buyer GRoup
        BuyerGroup buyerGroup = this.createBuyerGroup('US BUYER GROUP');
        CommerceEntitlementPolicy policy = this.createEntitlementPolicy('US ENTITLEMENT POLICY');
        //this.createEntitlementProduct(policy.Id, products[0].Id);
        this.buyerGroupId = buyerGroup.Id;

        // Asocia el buyer group a la store
        WebStoreBuyerGroup wsGroup = new WebStoreBuyerGroup();
        wsGroup.BuyerGroupId = buyerGroup.Id;
        wsGroup.WebStoreId = store.Id;
        insert wsGroup;

        // Crea el Commerce Entitlement Buyer Group
        CommerceEntitlementBuyerGroup ceg = new CommerceEntitlementBuyerGroup();
        ceg.BuyerGroupId = buyerGroup.Id;
        ceg.CurrencyIsoCode = 'USD';
        ceg.PolicyId = policy.Id;
        insert ceg;

        // Asocia la cuenta al Buyer Group
        BuyerGroupMember bgMember = new BuyerGroupMember();
        bgMember.BuyerId = acc.Id;
        bgMember.BuyerGroupId = buyerGroup.Id;
        insert bgMember;

        // Activa el Price Book de la tienda
        DataFactoryProduct.ignoreStandardPriceBook = true;
        Pricebook2 pbook = DataFactoryProduct.createPricebook();        
        //Pricebook2 pbook = [select Id, IsStandard from Pricebook2 where IsStandard = false limit 1];

        WebStorePricebook wspb = new WebStorePricebook();
        wspb.WebStoreId = store.Id;
        wspb.Pricebook2Id = pbook.Id;
        wspb.IsActive = true;
        insert wspb;
        this.PricebookId = pbook.Id;

        // Asocia el Price Book al Buyer Group
        BuyerGroupPricebook bgpb = new BuyerGroupPricebook();
        bgpb.BuyerGroupId = buyerGroup.Id;
        bgpb.Pricebook2Id = pbook.Id;
        bgpb.IsActive = true;
        insert bgpb;

        this.Products = DataFactoryProduct.createProducts(pbook);
        for (Product2 p : this.Products) {
            this.createEntitlementProduct(policy.Id, p.Id);
        }

    }
 
    public WebStore createStore(String storeName) {
        WebStore store = new WebStore();
        store.Name = storeName;
        store.SupportedCurrencies = 'USD';
        store.Type = 'B2B';
        insert store;
        return store;
    }

    public BuyerGroup createBuyerGroup(String groupName) {
        BuyerGRoup gr = new BuyerGroup();
        gr.Name = groupName;
        insert gr;
        return gr;
    }

    public CommerceEntitlementPolicy createEntitlementPolicy(String name) {
        CommerceEntitlementPolicy policy = new CommerceEntitlementPolicy();
        policy.Name = name;
        insert policy;
        return policy;
    }

    public CommerceEntitlementProduct createEntitlementProduct(Id policyId, Id productId) {
        CommerceEntitlementProduct eProduct = new CommerceEntitlementProduct();
        eProduct.PolicyId = policyId;
        eProduct.ProductId = productId;
        insert eProduct;
        return eProduct;
    }

    public WebCart createCart() {
        // Creates a contact point address
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Shipping';
        address.Name = 'Test adddress';
        address.SAPId__c = '5000121';
        address.ParentId = this.AccountId;
        address.City = 'Saddel River';
        address.CountryCode = 'US';
        address.PostalCode = '07401';
        address.stateCode = 'NJ';
        address.Street = '7 Boroline Road';
        address.EMail__c = 'aaa@ccc.cxm';
        address.Phone__c = '111 222 333';  
        address.Mobile__c = '666 777 888';
        insert address;

        WebCart cart = new WebCart();
        cart.WebStoreId = this.StoreId;
        cart.AccountId = this.AccountId;
        cart.Name = 'Test Cart';
        //cart.Status = 'Checkout';
        insert cart;
        this.CartId = cart.Id;

        CartDeliveryGroup cdg = new CartDeliveryGroup();
        cdg.CartId = cart.Id;
        cdg.Name = 'Test Delivery Group';
        cdg.DeliverToName = 'Delivery Name';
        cdg.ContactPointAddressId__c = address.Id;
        cdg.shippingInstructions = '#ADDR: ' + address.Id;
        insert cdg;

        CartItem item = new CartItem();
        item.CartId = cart.Id;
        item.Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id;
        item.Quantity = 1;
        item.SalesPrice = 100;
        item.Name = 'Test Cart Item';
        item.CartDeliveryGroupId = cdg.Id;
        insert item;

        return cart;
    }
    
}