@isTest
public class B2B_contactPageController_Test {

    @isTest public static void getDefaultContactPoint() {
        Test.startTest();
        B2B_contactPageController.sendMailtoSupport('test');
        Test.stopTest();
    }

}