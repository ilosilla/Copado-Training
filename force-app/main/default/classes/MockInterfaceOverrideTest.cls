@isTest
public  with sharing class MockInterfaceOverrideTest {
    @isTest
    static void testOrdersApexClass(){
        List<ZSFMatBase__x> productBaseLst = new List<ZSFMatBase__x>();
        
        ZSFMatBase__x productBaseObj = new ZSFMatBase__x();
        productBaseLst.add(productBaseObj);

        Test.startTest();
        	MockInterface myMock = new MockInterface();
        	List<SObject> myLst = myMock.passThrough(productBaseLst);
        Test.stopTest();
        //do assertions
	}
}