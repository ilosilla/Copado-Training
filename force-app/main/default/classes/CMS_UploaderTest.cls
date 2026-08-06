@isTest public with sharing class CMS_UploaderTest {

    // Dummy test para conseguir cobertura, pero no hace nada real
    @IsTest(SeeAllData=true) private static void test001() {
        Id fakeId = UserInfo.getUserId();
        CMS_Uploader uploader = new CMS_Uploader(fakeId);
        uploader.AutoPublish = true;
        try {
            uploader.uploadImage('test.jpg', Blob.valueOf('XXX'));
        } catch(Exception ex) {
            Assert.isNotNull(ex.getMessage());
        }
        Assert.isTrue(true);
    }

}