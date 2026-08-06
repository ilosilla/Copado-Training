@isTest public class StorageAPIHelperTest {

    @testSetup static void testSetup() {
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    @isTest static void testConstructorError() {
        Boolean exc = false;
        try {
            StorageAPIHelper helper = new StorageAPIHelper('dummy');  
            Assert.IsNull(helper, 'No storage api class should have been created');
        } catch(Exception ex) {
            exc = String.isNotBlank(ex.getMessage());
        }
        Assert.isTrue(exc, 'An exception was expected');
    }

    @isTest static void testDir() {
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = '{"folder": "/processed","totalItems": 10,"items": []}';
        Test.setMock(HttpCalloutMock.class, mocker);
        Test.startTest();
        StorageAPIHelper helper = new StorageAPIHelper('mbank');            
        StorageAPIHelper.DirectoryDTO dto = helper.dir('/');
        Assert.isTrue(dto.items.size() == 0, 'No items expected');
    }

    @isTest static void testRead() {
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = '123';
        Test.setMock(HttpCalloutMock.class, mocker);
        Test.startTest();
        StorageAPIHelper helper = new StorageAPIHelper('mbank');            
        String content = helper.readTextFile('inbox/test.txt');
        Assert.isNotNull(content, 'COntent cannot be null');
    }

    @isTest static void testMove() {
        SAPCPIProxyTest.Mocker mocker = new SAPCPIProxyTest.Mocker();
        mocker.customResponse = '123';
        Test.setMock(HttpCalloutMock.class, mocker);
        Test.startTest();
        StorageAPIHelper helper = new StorageAPIHelper('mbank');            
        helper.moveFile('inbox/test.txt', 'dummy/folder');
        Assert.isTrue(true);
    }

}