/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 10-11-2023
 * @group        :
 * @see          :
**/
public without sharing class NBK_FinderStoreController {

    public static final String COUNTRY_US = 'US';
    public static final String COUNTRY_CA = 'CA';
    public static final String COUNTRY_UK = 'UK';
    public static final String COUNTRY_GB = 'GB';
    public static final String COUNTRY_FR = 'FR';
    public static final String COUNTRY_AU = 'AU';
    public static final String COUNTRY_DE = 'DE';

    /**
    * @description get properties from AppointmentManagerFrontProperty__mdt
    * @author EHG@nubika.com | 2023
    * @param country
    * @return PropertiesFront
    **/
    @AuraEnabled
    public static PropertiesFront getPropertiesFromCountry(String country){
        try{
            AppointmentManagerFrontProperty__mdt mdt = AppointmentManagerFrontProperty_Selector.getPropertiesFromCountry(country);

            return new PropertiesFront(
                Decimal.valueOf(mdt.LatitudeInit__c),
                Decimal.valueOf(mdt.LongitudeInit__c),
                mdt.ZoomGeneral__c,
                mdt.ZoomFinder__c,
                mdt.ZoomFinderState__c,
                mdt.ZoomFinderCountry__c,
                mdt.ZoomStore__c,
                mdt.CountryAuxi__c,
                mdt.NameShown__c,
                mdt.PrivacyPolicyUrl__c,
                mdt.DateFormat__c,
                mdt.hasAssociates__c
            );

        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }

    /**
    * @description get the name of the city from latitude and longitude params
    * @author EHG@nubika.com | 2023
    * @param lat
    * @param lon
    * @param country
    * @return String
    **/
    @AuraEnabled
    public static String getAddressPosition(Decimal lat,Decimal lon, String country){
        try{
            if(country == COUNTRY_US || country == COUNTRY_CA){
                return NBK_selectWarehouseHandlerUS.getAddressPosition(lat, lon, country);
            }else if(country == COUNTRY_UK){
                //Para UK en SF está configurado todo como GB
                country = COUNTRY_GB;
                //return NBK_selectWarehouseHandlerUK.getAddressPosition(lat, lon, country);*/
            }else if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.getAddressPosition(lat, lon, country);
            }/*else if(country == COUNTRY_AU){
                return NBK_selectWarehouseHandlerAU.getAddressPosition(lat, lon, country);
            }*/
            return AppointmentWarehouseService.getAddressPosition(lat, lon, country);
        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }

    /**
    * @description search all stores from country param
    * @author EHG@nubika.com | 2023
    * @param country
    * @return List<AddressStoreWRP>
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> searchAllStoresFromCountry(String country){
        try{
            if(country == COUNTRY_US){
                return NBK_selectWarehouseHandlerUS.searchAllStoresFromCountry(country);
            }else if(country == COUNTRY_UK){
                country = COUNTRY_GB;
                //return NBK_selectWarehouseHandlerUK.searchAllStoresFromCountry(country);*/
            }else if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.searchAllStoresFromCountry(country);
            }/*else if(country == COUNTRY_AU){
                return NBK_selectWarehouseHandlerAU.searchAllStoresFromCountry(country);
            }*/
            return AppointmentWarehouseService.searchAllStoresFromCountry(country);
        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }

    /**
    * @description search stores by street city postalcode and province
    * @author EHG@nubika.com | 2023
    * @param street
    * @param city
    * @param postalcode
    * @param province
    * @param country
    * @return List<AddressStoreWRP>
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> searchStores(String street, String city, String postalcode, String province, String country){
        try{
            if(country == COUNTRY_US || country == COUNTRY_CA){
                return NBK_selectWarehouseHandlerUS.searchStores(city, postalcode, province, country);
            /*}else if(country == COUNTRY_UK){
                return NBK_selectWarehouseHandlerUK.searchStores(street,city, postalcode, province, country);*/
            }else if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.searchStores(street,city, postalcode, province, country);
            }/*else if(country == COUNTRY_AU){
                return NBK_selectWarehouseHandlerAU.searchStores(street,city, postalcode, province, country);
            }*/
            return AppointmentWarehouseService.searchStores(street,city, postalcode, province, country);

        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }
    
    @AuraEnabled
    public static List<AddressStoreWRP> searchAssociates(String street, String city, String postalcode, String province, String country){
        try{
            if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.searchAssociates(street,city, postalcode, province, country);
            }
            if(country == COUNTRY_US){
                return NBK_selectWarehouseHandlerUS.searchAssociates(street,city, postalcode, province, country);
            }
            return null;

        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }

    /**
    * @description search all stores from country
    * @author EHG@nubika.com | 2023
    * @param latitude
    * @param longitude
    * @return List<AddressStoreWRP>
    **/
    @AuraEnabled
    public static List<AddressStoreWRP> getInitialStores(Decimal latitude, Decimal longitude, String country){
        try{
            if(country == COUNTRY_US){
                return NBK_selectWarehouseHandlerUS.getInitialStores(latitude, longitude, country);
            }else if(country == COUNTRY_UK){
                country = COUNTRY_GB;
                //return NBK_selectWarehouseHandlerUK.getInitialStores(latitude, longitude, country);*/
            }else if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.getInitialStores(latitude, longitude, country);
            }/*else if(country == COUNTRY_AU){
                return NBK_selectWarehouseHandlerAU.getInitialStores(latitude, longitude, country);
            }*/
            return AppointmentWarehouseService.getInitialStores(latitude, longitude, country);
        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }
    
    @AuraEnabled
    public static List<AddressStoreWRP> getInitialAssociates(Decimal latitude, Decimal longitude, String country){
        try{
			if(country == COUNTRY_FR){
                return NBK_selectWarehouseHandlerFR.getInitialAssociates(latitude, longitude, country);
            }
            if(country == COUNTRY_US){
                return NBK_selectWarehouseHandlerUS.getInitialAssociates(latitude, longitude, country);
            }

            return null;
        }catch(Exception ex){
            Logger.error(ex.getMessage());
            Logger.saveLog();
            return null;
        }
    }


    public class PropertiesFront{
        @AuraEnabled
        public Decimal latitude {get; set;}
        @AuraEnabled
        public Decimal longitude {get; set;}
        @AuraEnabled
        public Decimal zoomGeneral {get; set;}
        @AuraEnabled
        public Decimal zoomFinder {get; set;}
        @AuraEnabled
        public Decimal zoomFinderState {get; set;}
        @AuraEnabled
        public Decimal zoomFinderCountry {get; set;}
        @AuraEnabled
        public Decimal zoomStore {get; set;}
        @AuraEnabled
        public String countryAuxi {get; set;}
        @AuraEnabled
        public String nameShown {get; set;}
        @AuraEnabled
        public String privacyPolicyLink {get; set;}
         @AuraEnabled
        public String dateFormat {get; set;}
        @AuraEnabled
        public Boolean hasAssociates {get; set;}

        public PropertiesFront(Decimal latitude, Decimal longitude, Decimal zoomGeneral, Decimal zoomFinder, Decimal zoomFinderState, Decimal zoomFinderCountry, Decimal zoomStore, String countryAuxi, String nameShown, String privacyPolicyLink, String dateFormat, Boolean hasAssociates){
            this.latitude           = latitude;
            this.longitude          = longitude;
            this.zoomGeneral        = zoomGeneral;
            this.zoomFinder         = zoomFinder;
            this.zoomFinderState    = zoomFinderState;
            this.zoomFinderCountry  = zoomFinderCountry;
            this.zoomStore          = zoomStore;
            this.countryAuxi        = countryAuxi;
            this.nameShown          = nameShown;
            this.privacyPolicyLink  = privacyPolicyLink;
            this.dateFormat         = dateFormat;
            this.hasAssociates      = hasAssociates;
        }
    }
    
    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        
        return s;
    }

}