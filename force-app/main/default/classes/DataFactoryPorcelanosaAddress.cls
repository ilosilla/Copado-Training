/**
* @author 		Ramón Prades
* @date 		May 2023
* @group 		DataFactories   
* @description 	Porcelanosa Address data factory
*/
public class DataFactoryPorcelanosaAddress {

    public static List<PorcelanosaAddress__c> createAddresses() {
        List<PorcelanosaAddress__c> addresses = new List<PorcelanosaAddress__c>();
        if (Test.isRunningTest()) {
            PorcelanosaAddress__c a1 = new PorcelanosaAddress__c(
                Name = 'Manhattan Showroom',
                SAPSalesOrg__c = '605',
                NBK_Address_Type__c = 'Showroom',
                NBK_Address__Street__s = '202 5th Avenue',
                NBK_Address__City__s = 'New York',
                NBK_Address__PostalCode__s = '10010',
                NBK_Address__StateCode__s = 'NY',
                NBK_Address__CountryCode__s = 'US'      );
            addresses.add(a1);

            PorcelanosaAddress__c a2 = new PorcelanosaAddress__c(
                Name = 'Porcelanosa Ramsey',
                SAPSalesOrg__c = '605',
                NBK_Address_Type__c = 'Warehouse;Showroom;Collection Point;Ships Samples;',
                NBK_Address__Street__s = '600 NJ-17',
                NBK_Address__City__s = 'Ramsey',
                NBK_Address__PostalCode__s = '07446',
                NBK_Address__StateCode__s = 'NJ',
                NBK_Address__CountryCode__s = 'US'      );
            addresses.add(a2);

            PorcelanosaAddress__c a3 = new PorcelanosaAddress__c(
                Name = 'Porcelanosa Paramus',
                SAPSalesOrg__c = '605',
                NBK_Address_Type__c = 'Showroom;Collection Point;',
                NBK_Address__Street__s = '65 NJ-17',
                NBK_Address__City__s = 'Paramus',
                NBK_Address__PostalCode__s = '07652',
                NBK_Address__StateCode__s = 'NJ',
                NBK_Address__CountryCode__s = 'US'      );
            addresses.add(a3);

            PorcelanosaAddress__c a4 = new PorcelanosaAddress__c(
                Name = 'Porcelanosa Southeast',
                SAPSalesOrg__c = '502',
                NBK_Address_Type__c = 'Warehouse;Showroom;Collection Point;Ships Samples;',
                NBK_Address__Street__s = '1 Otterspool Way',
                NBK_Address__City__s = 'Watford',
                NBK_Address__PostalCode__s = 'WD25 8HL',
                NBK_Address__StateCode__s = '',
                NBK_Address__CountryCode__s = 'GB'      );
            addresses.add(a4);

            insert addresses;
        }
        return addresses;
    }
}


//,NBK_Address_Type__c,NBK_Address__Street__s,NBK_Address__City__s,NBK_Address__PostalCode__s,NBK_Address__StateCode__s,NBK_Address__CountryCode__s,NBK_Address__Latitude__s,NBK_Address__Longitude__s,NBK_Address__GeocodeAccuracy__s,NBK_Address__c,NBK_Address__c.city,NBK_Address__c.country,NBK_Address__c.countryCode,NBK_Address__c.geocodeAccuracy,NBK_Address__c.latitude,NBK_Address__c.longitude,NBK_Address__c.postalCode,NBK_Address__c.state,NBK_Address__c.stateCode,NBK_Address__c.street,NBK_Business_Hours__c,NBK_Phone__c,NBK_SAPId__c,NBK_SalesOffice__c,NBK_Sales_Org__c,NBK_isActive__c,NBK_isWarehouse__c,NBK_minDeliveryDays__c,NBK_ownAddress__c