/**
 * @description       :
 * @author            : EHG@nubika.com
 * @group             :
 * @last modified on  : 06-19-2023
 * @last modified by  : EHG@nubika.com
**/
public without sharing class NB2B_PorcelanosaAddressSelector {

    /**
    * @description SEARCH STORES
    * @author EHG@nubika.com | 06-19-2023
    * @param latitude
    * @param longitude
    * @return List<PorcelanosaAddress__c>
    **/
    public static List<PorcelanosaAddress__c> getStoresNearLatLon(Decimal latitude, Decimal longitude,Integer dist,String country,String province){
        System.debug('***** getStoresNearLatLon *****');
        System.debug('latitude:'+latitude);
        System.debug('longitude:'+longitude);
        if(country == 'US' || country == 'UK'){
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'mi') Distancia
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
                            AND NBK_OnlineAppointment__c = true
                            AND NBK_Address__CountryCode__s =: country
                            AND DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'mi') < :dist
                                    ORDER BY DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'mi') LIMIT 5];
        }else{
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'km') Distancia
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
														AND NBK_OnlineAppointment__c = true
                            AND NBK_Address__CountryCode__s =: country
                            AND DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'km') < :dist
                                    ORDER BY DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'km') LIMIT 5];
        }

    }

    /**
    * @description
    * @author EHG@nubika.com | 06-19-2023
    * @param latitude
    * @param longitude
    * @return List<PorcelanosaAddress__c>
    **/
    public static List<PorcelanosaAddress__c> getStoresNearLatLon(Decimal latitude, Decimal longitude, String countryCode, String province){
        if(countryCode == 'US' || countryCode == 'UK' || countryCode == 'AU'){
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'mi') Distancia
                        FROM PorcelanosaAddress__c
                            WHERE NBK_isActive__c = true
																AND NBK_OnlineAppointment__c = true
                                AND  NBK_Address__CountryCode__s =: countryCode
                                      ORDER BY NAME DESC];
        }else{
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'km') Distancia
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
															AND NBK_OnlineAppointment__c = true
                              AND  NBK_Address__CountryCode__s =: countryCode
                                    ORDER BY NAME DESC];
        }
    }

    /**
    * @description
    * @author EHG@nubika.com | 06-19-2023
    * @param latitude
    * @param longitude
    * @return List<PorcelanosaAddress__c>
    **/
    public static List<PorcelanosaAddress__c> getStoresNearLatLon(Decimal latitude, Decimal longitude, List<String> countryCodes){
        String countries =  string.join(countryCodes,',');
        if(countries.contains('US') || countries.contains('UK') || countries.contains('AU')){
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'mi') Distancia
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
													AND  NBK_Address__CountryCode__s IN: countryCodes
													AND NBK_OnlineAppointment__c = true
														ORDER BY NAME DESC];
        }else{
            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c,DISTANCE(NBK_Address__c, GEOLOCATION(:latitude,:longitude), 'km') Distancia
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
													AND  NBK_Address__CountryCode__s IN: countryCodes
													AND NBK_OnlineAppointment__c = true
														ORDER BY NAME DESC];
        }
    }

    /**
    * @description
    * @author EHG@nubika.com | 06-19-2023
    * @param latitude
    * @param longitude
    * @return List<PorcelanosaAddress__c>
    **/
    public static List<PorcelanosaAddress__c> getStoresNearCityUS(String province, List<String> countryCodes){

            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
														AND  NBK_Address__CountryCode__s IN: countryCodes
                            AND  NBK_Address__StateCode__s =: province
														AND NBK_OnlineAppointment__c = true
                                ORDER BY NAME DESC];

    }

    /**
    * @description
    * @author EHG@nubika.com | 06-19-2023
    * @param latitude
    * @param longitude
    * @return List<PorcelanosaAddress__c>
    **/
    public static List<PorcelanosaAddress__c> getStoresNearCountryUS( List<String> countryCodes){

            return[SELECT Name, NBK_Address__c ,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_LinkToShowroom__c,NBK_ShowroomImage__c
                    FROM PorcelanosaAddress__c
                        WHERE NBK_isActive__c = true
														AND  NBK_Address__CountryCode__s IN: countryCodes
														AND NBK_OnlineAppointment__c = true
                                ORDER BY NAME DESC];

    }
}