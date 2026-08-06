/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-13-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class NBK_selectWarehouseController {

    @AuraEnabled
    public static list<picklistStates> getStatePicklist(){
        Schema.DescribeFieldResult stateField = PorcelanosaAddress__c.NB2B_States__c.getDescribe();
        Schema.sObjectField stateDescribed = stateField.getSObjectField();
        Map<String, String> stateValues = PicklistCommons.getValues(stateDescribed);
        system.debug('# Obtengo mapa de valores ' + stateValues);

        list<picklistStates> allStates = new list<picklistStates>();
        for(String val : stateValues.keySet()){
            picklistStates ps = new picklistStates(val, val);
            allStates.add(ps);
        }
        system.debug(' # Retorno lista de wrapper ' + allStates);
        return allStates;
    }

    @AuraEnabled
    public static list<mapMarkers> initializeMap(){
        list<PorcelanosaAddress__c> pa = [SELECT Name, NBK_Address__City__s, NBK_Address__Street__s, NBK_Address__PostalCode__s, NBK_Address__StateCode__s, NBK_Address__CountryCode__s, NBK_Address__Latitude__s, NBK_Address__Longitude__s
                                          FROM PorcelanosaAddress__c
                                          WHERE NBK_Address__CountryCode__s = 'US' OR
                                          NBK_Address__CountryCode__s = 'CA'];
        system.debug('# initializeMap lista de porcelanosa address ' + pa);
        list<mapMarkers> mapVals = new list<mapMarkers>();
        for(PorcelanosaAddress__c warehouse : pa){
            if(!String.isBlank(warehouse.NBK_Address__City__s) && !String.isBlank(warehouse.NBK_Address__Street__s) &&
               !String.isBlank(warehouse.NBK_Address__PostalCode__s) && !String.isBlank(warehouse.NBK_Address__StateCode__s) &&
               !String.isBlank(warehouse.NBK_Address__CountryCode__s)){
                //locations l = new locations(warehouse.NBK_Address__City__s, warehouse.NBK_Address__CountryCode__s, warehouse.NBK_Address__PostalCode__s, warehouse.NBK_Address__StateCode__s, warehouse.NBK_Address__Street__s, String.valueOf(warehouse.NBK_Address__Latitude__s), String.valueOf(warehouse.NBK_Address__Longitude__s));
                locations l = new locations(warehouse.NBK_Address__City__s, warehouse.NBK_Address__CountryCode__s, warehouse.NBK_Address__PostalCode__s, warehouse.NBK_Address__StateCode__s, warehouse.NBK_Address__Street__s);
                mapMarkers markers = new mapMarkers(l, warehouse.Name, warehouse.Name, '', '');
                mapVals.add(markers);
            }
        }
        system.debug('# initializeMap return markers ' + mapVals);
        return mapVals;
    }

    @AuraEnabled
    public static list<PorcelanosaAddress__c> getWarehousesByState(String country, String state){
        system.debug(' # Inicio getWarehousesByState state selected ' + state);
        //SELECT Id, Name, NBK_Address__City__s, NBK_Address__Street__s, NBK_Address__PostalCode__s, NBK_Address__StateCode__s FROM PorcelanosaAddress__c WHERE NBK_Address__StateCode__s = 'NY' 
        if (country.equals('US')){
            String stateCode = AddressCommons.getProvinceCode(country, state);
            // String stateCode = AddressCommons.getProvinceCode('US', state);
            system.debug(' # codigo de estado ' + stateCode);
            return [SELECT Name, NBK_Address__City__s, NBK_Address__Street__s, NBK_Address__PostalCode__s, NBK_Address__StateCode__s, NBK_Name_with_adress__c
                    FROM PorcelanosaAddress__c
                    WHERE NBK_Address__StateCode__s =: stateCode];
        }else{
            return [SELECT Name, NBK_Address__City__s, NBK_Address__Street__s, NBK_Address__PostalCode__s, NBK_Address__StateCode__s, NBK_Name_with_adress__c
                    FROM PorcelanosaAddress__c
                    WHERE NBK_Address__CountryCode__s =: country];
        }
    }

    public class picklistStates{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public picklistStates(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class mapMarkers{
        @AuraEnabled
        public locations location{get; set;}
        @AuraEnabled
        public String value{get; set;}
        @AuraEnabled
        public String tittle{get; set;}
        @AuraEnabled
        public String description{get; set;}
        @AuraEnabled
        public String icon{get; set;}


        public mapMarkers(locations l, String value, String tittle, String description, String icon) {
            this.location = l;
            this.value = value;
            //this.tittle = tittle;
            this.description = description;
            this.icon = icon;
        }
    }

    public class locations{
        @AuraEnabled
        public String City{get; set;}
        @AuraEnabled
        public String Country{get; set;}
        @AuraEnabled
        public String PostalCode{get; set;}
        @AuraEnabled
        public String State{get; set;}
        @AuraEnabled
        public String Street{get; set;}
        @AuraEnabled
        public String Latitude{get; set;}
        @AuraEnabled
        public String Longitude{get; set;}

        // public locations(String city, String country, String PostalCode, String state, String street, String Latitude, String Longitude) {
        public locations(String city, String country, String PostalCode, String state, String street) {
            this.City = city;
            this.Country = country;
            this.PostalCode = PostalCode;
            this.State = state;
            this.Street = street;
            // this.Latitude = latitude;
            // this.Longitude = longitude;
        }
    }

}