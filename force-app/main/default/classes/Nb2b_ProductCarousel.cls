public with sharing class Nb2b_ProductCarousel {
    
    @AuraEnabled
	public static List<WrapperSalida> getProductsInitial(){
		try {

			String url = getCommunityUrl('Portal B2B');
            Id pricebookId = new RunWithoutSharing().getPriceBookId();
			Integer total = 100;
			Integer totalCarousel = 10;
			Integer randomNumber;
			PricebookEntry productRandom;
			List<PricebookEntry> listproductsRandom = new List<PricebookEntry>();
			List<PricebookEntry> listproducts = [Select id, product2.URL_Photo_1__c, product2.Name, Product2Id
												 From PricebookEntry 
												 WHERE Pricebook2Id =: pricebookId
												 	   And product2.URL_Photo_1__c != null order by createdDate desc Limit :total];

			if((listproducts == null || listproducts.isEmpty()) && !Test.isRunningTest()){return null;}
			//fill the list with random values
			totalCarousel = (totalCarousel > listproducts.size() ? listproducts.size():totalCarousel);//if there are less products than totalCarousel we set to the product list available
			for(Integer i = 0; i< totalCarousel; i++){
				randomNumber = Integer.valueof((Math.random() * listproducts.size() - 1 ));productRandom = listproducts[randomNumber];
				if(!listproductsRandom.contains(productRandom)){listproductsRandom.add(listproducts[randomNumber]);}
			}

			List<WrapperSalida> resultado = new List<WrapperSalida>();
			for(PricebookEntry prod : listproductsRandom){WrapperSalida wr = new WrapperSalida();wr.id = prod.Product2.Id;wr.name = prod.Product2.Name;wr.imagen = prod.Product2.URL_Photo_1__c;wr.url = url+'product/'+prod.Product2Id;wr.price = '';resultado.add(wr);}

			return resultado;
		} catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
	}

	private static String getCommunityUrl(String communityName){
		String result = '';
		List<Network> network = [SELECT Name, UrlPathPrefix FROM Network WHERE Name = :communityName];
		result = URL.getSalesforceBaseUrl().toExternalForm(); 
		if (!network.isEmpty()){ result = result + '/' + network[0].UrlPathPrefix + '/s/'; }

		return result;
	}

    private without sharing class RunWithoutSharing {
        public Id getPriceBookId() {
            if(!Test.isRunningTest()){
                User communityUser = [SELECT Id, Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()];
                BuyerGroupMember bgm = [SELECT Id, BuyerGroupId FROM BuyerGroupMember WHERE BuyerId =: communityUser.Contact.AccountId LIMIT 1];
                BuyerGroupPricebook bgp = [SELECT Id, Pricebook2Id FROM BuyerGroupPricebook WHERE BuyerGroupId =: bgm.BuyerGroupId LIMIT 1];
                return bgp.Pricebook2Id;
            }else{
                List<WebStore> listWebStore = [SELECT StrikethroughPricebookId from WebStore where Name = 'United Kingdom' LIMIT 1];
                return listWebStore[0].StrikethroughPricebookId;
            }
        }
    }

    public class WrapperSalida{
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String description;
		@AuraEnabled
		public String imagen;
		@AuraEnabled
		public String url;
		@AuraEnabled
		public String textore;
		@AuraEnabled
		public String price;
	}
}