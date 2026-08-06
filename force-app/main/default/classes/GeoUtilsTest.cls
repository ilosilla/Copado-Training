@isTest public class GeoUtilsTest {

    @isTest static void isDummyStateCodeTest() {
        System.assertEquals(true, GeoUtils.isDummyStateCode('US', '01'));
        System.assertEquals(false, GeoUtils.isDummyStateCode('US', 'NY'));
        System.assertEquals(false, GeoUtils.isDummyStateCode('US', ''));
        System.assertEquals(false, GeoUtils.isDummyStateCode('', ''));
    }

    @isTest static void getUSStateCode() {
        System.assertEquals('NJ', GeoUtils.getUSStateCode('New Jersey'));
        System.assertEquals('', GeoUtils.getUSStateCode('Burriana'));
    }

    @isTest static void getCAStateCode() {
        System.assertEquals('MB', GeoUtils.getCAStateCode('MAnitoba'));
        System.assertEquals('', GeoUtils.getCAStateCode('Burriana'));
    }

}