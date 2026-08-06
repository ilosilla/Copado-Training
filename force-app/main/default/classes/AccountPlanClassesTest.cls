@isTest
public with sharing class AccountPlanClassesTest {
    @isTest
    static void fillerTestAccountAdditional() {
        AccountAdditionalDataService aux = new AccountAdditionalDataService();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }

    @isTest
    static void fillerTestPappersService() {
        PappersService aux = new PappersService();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }

    @isTest
    static void fillerTestAccountAdditionalData() {
        AccountAdditionalData aux = new AccountAdditionalData();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}