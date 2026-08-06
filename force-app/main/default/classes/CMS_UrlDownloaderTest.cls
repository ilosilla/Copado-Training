@isTest public with sharing class CMS_UrlDownloaderTest {

    @testSetup private static void testSetup() {
        SAPCPIProxyTest.testSetup();
    }

    @isTest public static void testDownload() {
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new SAPCPIProxyTest.Mocker());
        String url ='https://some-site.com/random/file.png';
        Test.startTest();
        CMS_UrlDownloader.DownloadResult result = CMS_UrlDownloader.download(url);
        Test.stopTest();
        Assert.isTrue(result.success, 'True expected');
    }
}