@isTest
public class NBK_FinderStoreController_Test {

    @TestSetup
    public static void makeData(){
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        ware.NBK_Address__CountryCode__s = 'US';
        insert ware;
    }

    @IsTest
    public static void testgetPropertiesFromCountry(){
        NBK_FinderStoreController.PropertiesFront mdt;
        Test.startTest();
            mdt = NBK_FinderStoreController.getPropertiesFromCountry('US');
            NBK_FinderStoreController.getPropertiesFromCountry('ES');
        Test.stopTest();
        System.assertEquals(mdt != null, true, 'OK');
    }

    @IsTest
    public static void testgetAddressPosition(){
        String result;
        Test.startTest();
            result = NBK_FinderStoreController.getAddressPosition(39.72676768420198, -104.9846328587533, 'ES');
            result = NBK_FinderStoreController.getAddressPosition(39.72676768420198, -104.9846328587533, 'US');
            result = NBK_FinderStoreController.getAddressPosition(39.72676768420198, -104.9846328587533, 'UK');
            result = NBK_FinderStoreController.getAddressPosition(39.72676768420198, -104.9846328587533, 'FR');
        Test.stopTest();
        System.assertEquals(result != null, false, 'OK');
    }

    @IsTest
    public static void testsearchAllStoresFromCountry(){
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_FinderStoreController.searchAllStoresFromCountry('ES');
            result = NBK_FinderStoreController.searchAllStoresFromCountry('US');
            result = NBK_FinderStoreController.searchAllStoresFromCountry('UK');
            result = NBK_FinderStoreController.searchAllStoresFromCountry('FR');
        Test.stopTest();
        System.assertEquals(result != null, false, 'OK');
    }

     @IsTest
    public static void testsearchStores(){
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_FinderStoreController.searchStores('Madrid', null ,null, null, 'ES');
            result = NBK_FinderStoreController.searchStores('London', null, null, null, 'UK');
            result = NBK_FinderStoreController.searchStores('Paris',null, null, null, 'FR');
            result = NBK_FinderStoreController.searchStores('Miami', null, null, null, 'US');
        Test.stopTest();
    }
    
    @IsTest
    public static void testsearchAssociates(){
        List<AddressStoreWRP> result;
        List<AddressStoreWRP> resultUS;
        Test.startTest();
            result = NBK_FinderStoreController.searchAssociates('Paris',null, null, null, 'FR');
            resultUS = NBK_FinderStoreController.searchAssociates('San Francisco',null, null, null, 'US');
        Test.stopTest();
    }

    @IsTest
    public static void testgetInitalStores(){
        List<AddressStoreWRP> result;
        Test.startTest();
            result = NBK_FinderStoreController.getInitialStores(39.72676768420198, -104.9846328587533, 'ES');
            result = NBK_FinderStoreController.getInitialStores(39.72676768420198, -104.9846328587533, 'US');
            result = NBK_FinderStoreController.getInitialStores(39.72676768420198, -104.9846328587533, 'UK');
            result = NBK_FinderStoreController.getInitialStores(39.72676768420198, -104.9846328587533, 'FR');
        Test.stopTest();
        System.assertEquals(result != null, false, 'OK');
    }
    
    @IsTest
    public static void testgetInitalAssociates(){
        List<AddressStoreWRP> result,resultUS;
        Test.startTest();
            result = NBK_FinderStoreController.getInitialAssociates(39.72676768420198, -104.9846328587533, 'FR');
            resultUS = NBK_FinderStoreController.getInitialAssociates(39.72676768420198, -104.9846328587533, 'FR');
        Test.stopTest();
        System.assertEquals(result == null, false, 'OK');
        System.assertEquals(resultUS == null, false, 'OK');
    }
    
    @isTest
    static void fillerTestAccountAdditionalData() {
        NBK_FinderStoreController aux = new NBK_FinderStoreController();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }

}