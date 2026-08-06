public class NB2B_DatePicker {
	@AuraEnabled
	public static List<B2B_Country_Settings__mdt> getb2bMetadata(String country){
		List<B2B_Country_Settings__mdt> b2b = [SELECT Cutover_Time__c, Days_to_wait__c, Label FROM B2B_Country_Settings__mdt WHERE Label =: country LIMIT 1];
		return b2b;
	}

}