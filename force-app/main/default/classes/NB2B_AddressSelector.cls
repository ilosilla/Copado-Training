public class NB2B_AddressSelector {
	public static List<ContactPointAddress> selectPointAddressesByAccountId(Id accountId){
		return [
			SELECT Id, Name, IsPrimary, IsDefault, Address, SapId__c
			FROM ContactPointAddress
			WHERE ParentId = : accountId
			//AND AddressType = 'Shipping'
			//AND UsageType NOT IN('Inactive', 'Temporary')
		];
	}

	public static List<Delivery_Days_Configuration__c> getDeliveryDaysConfigFromPostalCode(String postalCode){
        List<Delivery_Days_Configuration__c> deliveryDaysConfiguration = [
			SELECT Id, Delivery_Days__c, Default_code__c, DaysToDelay__c
			FROM Delivery_Days_Configuration__c
			WHERE Post_Code__c = :postalCode
		];
        if(deliveryDaysConfiguration.isEmpty()){
            deliveryDaysConfiguration = [SELECT Id, Delivery_Days__c,DaysToDelay__c ,Default_code__c
			FROM Delivery_Days_Configuration__c
			WHERE Default_code__c = true];
        }
		return deliveryDaysConfiguration;
	}
}