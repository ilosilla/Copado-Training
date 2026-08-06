/**
 * @description  : 
 * @author       : Nubika Team <porcelanosa@nubika.com>
 * @version      : 1.0.0
 * @date         : 18-09-2023
 * @group        : 
 * @see          : 
**/
@SuppressWarnings('PMD')
@isTest
public with sharing class NB2B_CartToOrderManager_Test {
   @isTest
    public static void createErrorTest(){
        // Assert.isNotNull(NB2B_CartToOrderManager.loremIpsum());
        NB2B_CartToOrderManager.B2BCartToOrderOutput result = new NB2B_CartToOrderManager.B2BCartToOrderOutput('Error', null, true, true, false);
        Assert.areEqual('Error', result.errorTxt);
    }
}