/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_AreaCalculationController
     Created Date:      04/07/2022
     Author:            Ignacio Galindo Schuhmacher
     Mail:              ignacio.galindo@nubika.com
     Description:       Class to manage show button conditions and Area calculations
------------------------------------------------------------------------------------------*/

public with sharing class NB2B_QuickOrderController {

    @AuraEnabled(cacheable=false)
    public static List<quickOrderWrapper> getInit(){
        System.debug('NB2B_QuickOrderController getInit start');
        List<quickOrderWrapper> quickOrderWrapper = new List<quickOrderWrapper>();
        String userId = UserInfo.getUserId();
        
        User user = [Select id, ContactId, Contact.AccountId, Contact.Account.Name,Contact.Account.Country_formula__c, 
                            Contact.Account.CurrencyIsoCode, LanguageLocaleKey from User where id=:userId limit 1];
        for(Integer x =0; x < 1; x++){
            quickOrderWrapper thisWrapper = new quickOrderWrapper();
            thisWrapper.currencyIsoCode = user.Contact.Account.CurrencyIsoCode;
            quickOrderWrapper.add(thisWrapper);
        }

        System.debug('NB2B_QuickOrderController getInit end');

        return quickOrderWrapper;
    }

    @AuraEnabled (cacheable=false)
    public static NB2B_AreaCalculationController.AreaCalculationWrapper getProductAndPrice(String searchTerm){
        //PRIMERO LLAMAMOS AL MÉTODO DE BUSCAR PRODUCTO
        //UNA VEZ LOCALIZAMOS EL PRODUCTO, ENVIAMOS AL AREA CALCULATION CONTROLLER PARA RECUPERAR PRECIO 
        //SI TODO VA BIEN, MONTAMOS EL WRAPPER
        System.debug('NB2B_QuickOrderController getProductAndPrice start');
        System.debug('NB2B_QuickOrderController getProductAndPrice searchTerms : ' + searchTerm);
        NB2B_AreaCalculationController.AreaCalculationWrapper priceWrapper;
        //QuickOrderWrapper responseWrapper;
        NB2B_SearchSku.SearchResults productId;

        try{
            //responseWrapper = new QuickOrderWrapper();

            //productId = searchProduct(searchTerm);

            if(searchTerm != null){
                productId = NB2B_SearchSku.searchSku(searchTerm);
                System.debug('product Id : ' + productId.productId);
                System.debug('product : ' + productId);
                if(productId.productId != null){
                    priceWrapper = NB2B_AreaCalculationController.checkShowButtonV2(productId.productId);
                }
                
            }else{
                priceWrapper = new NB2B_AreaCalculationController.AreaCalculationWrapper();
                priceWrapper.isCorrect = false;
            }

        }catch(Exception e){
            System.debug('NB2B_QuickOrderController getProductAndPrice error : ' + e);
        }
        System.debug('NB2B_QuickOrderController getProductAndPrice priceWrapper : ' + JSON.serialize(priceWrapper));
        System.debug('NB2B_QuickOrderController getProductAndPrice finish');
        return priceWrapper;
    }

    
    @AuraEnabled (cacheable=false)
    public static QuickOrderResultWrapper addToCart(String jsonWrapper,  String salesOrg){
        System.debug('NB2B_QuickOrderController addToCart start');
        List<quickOrderWrapper> quickOrderWrapper;
        //String salesOrg;
        List<cartItem> cartItemList = new List<cartItem>();
        try{
            System.debug('quickOrderWrapper: ' + jsonWrapper);
            quickOrderWrapper = (List<quickOrderWrapper>)JSON.deserialize(jsonWrapper, List<quickOrderWrapper>.class);
            System.debug('quickOrderWrapper after : ' + JSON.serialize(quickOrderWrapper));
            

            for(quickOrderWrapper thisItem : quickOrderWrapper){
                if(thisItem.total != null && thisItem.productInfo!= null && thisItem.quantity != null && thisItem.quantity > 0 && thisItem.total > 0){
                    cartItem newCartItem;
                    newCartItem = sendToCart(thisItem.productInfo.product.Id, thisItem.productInfo.webStoreId, thisItem.quantity, thisItem.productInfo.price.Id, salesOrg, thisItem.total, null);
                    System.debug('Sale');
                    if(newCartItem != null){
                        cartItemList.add(newCartItem);
                    }
                }
            }
            if(!cartItemList.isEmpty()){
                insert cartItemList;
            }else{
                return new QuickOrderResultWrapper(false, 'There are no items available to add to cart');
            }

        }catch(Exception e){
            System.debug('Exception e: ' + e);
            return new QuickOrderResultWrapper(false, e.getMessage());
        }

        System.debug('NB2B_QuickOrderController addToCart end');

        return new QuickOrderResultWrapper(true, 'success');
    }

    @AuraEnabled
    public static cartItem sendToCart(String recordId, String webStoreId, Integer quantity, String priceBookId, String salesOrg, Decimal amount, String shade){
        System.debug('NB2B_QuickOrderController sendToCart start');   
        cartItem cartItem;
        Product2 product;
        WebCart cart;
        PriceBookEntry priceBookEntry;
        CartDeliveryGroup cartDeliveryGroup;
        Id userId;
        try{
            System.debug('Buscamos product');
            product = [Select id, StockKeepingUnit, Name from Product2 where id=:recordId limit 1];
            System.debug('Buscamos priceBookEntry');
            priceBookEntry = [Select id, IsActive, ActivePriceAdjustmentQuantity ,
                                            Bzirk__c , UnitPrice , Pricebook2Id , Product2Id ,
                                            ProductCode , UPrice__c, CurrencyIsoCode 
                                    from PriceBookEntry where Id =:priceBookId limit 1];
            System.debug('Buscamos user');
            if(Test.isRunningTest()){
               userId = [Select id from User where FirstName = 'TEST AREA' limit 1].Id;
                System.debug('userId : ' + userId);
            }else{
               userId = UserInfo.getUserId();
            }
            //System.debug('Buscamos webCart : ' + [Select id, ownerID,WebStoreId,status   from webCart]);
            cart = [Select id from webCart where ownerID =:userId and WebStoreId =:webStoreId and (status='Active' or status='Checkout') Limit 1];
            System.debug('Buscamos cartDeliveryGroup : ' + [Select Id from CartDeliveryGroup where cartId =:cart.Id]);
            cartDeliveryGroup = [Select Id from CartDeliveryGroup where cartId =:cart.Id Limit 1];
            cartItem = new cartItem ();
            cartItem.Sku = product.StockKeepingUnit;
            cartItem.CartId = cart.Id ;
            cartItem.CurrencyIsoCode = priceBookEntry.CurrencyIsoCode;
            cartItem.ListPrice = amount;
            cartItem.Name       = product.Name;
            cartItem.Product2Id = recordId;
            cartItem.Quantity = quantity;
            cartItem.SalesPrice = priceBookEntry.UnitPrice;
            //cartItem.TotalAmount = quantity * priceBookEntry.UnitPrice;
            cartItem.TotalLineAmount = amount;
            cartItem.TotalPrice = amount;
            cartItem.Type = 'Product';   
            cartItem.CartDeliveryGroupId = cartDeliveryGroup.Id;
            cartItem.UnitAdjustedPrice  = amount/quantity;
            cartItem.UnitAdjustmentAmount  = 0;
            cartItem.NB2B_SalesOrg__c = salesOrg;  
            cartItem.NB2B_UnitPrice__c = priceBookEntry.UPrice__c; 
            cartItem.NB2B_Shade__c = shade;
            
            //insert cartItem;            
        }catch(Exception e){
            System.debug('NB2B_QuickOrderController sendToCart exception :' + e); 
           
        }
        return cartItem;
    }

    public class quickOrderWrapper{
        @AuraEnabled 
        public Boolean showSearch = true;
        @AuraEnabled 
        public Boolean showProductData = false;
        @AuraEnabled 
        public Integer quantity = 0;
        @AuraEnabled 
        public Decimal total = 0;
        @AuraEnabled 
        public String currencyIsoCode;
        @AuraEnabled 
        public NB2B_AreaCalculationController.AreaCalculationWrapper productInfo = new NB2B_AreaCalculationController.AreaCalculationWrapper();
    }

    public class QuickOrderResultWrapper{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMsg; 

        public QuickOrderResultWrapper(Boolean success, String errorMsg){
            this.success = success;
            this.errorMsg = errorMsg;
        }
    }

}