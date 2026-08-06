public class AppointmentManagerFrontProperty_Selector {

    public static AppointmentManagerFrontProperty__mdt getPropertiesFromCountry(String country){
        return [SELECT Id, ZoomGeneral__c, Country__c, CountryAuxi__c, ZoomFinder__c, ZoomStore__c, LatitudeInit__c, LongitudeInit__c, ZoomFinderState__c,ZoomFinderCountry__c,PrivacyPolicyUrl__c,NameShown__c,HasAssociates__c,DateFormat__c
                    FROM AppointmentManagerFrontProperty__mdt 
                        WHERE Country__c =: country LIMIT 1];
    }

}