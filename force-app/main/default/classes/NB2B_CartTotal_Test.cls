/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : EHG@nubika.com
**/
@isTest
public without sharing class NB2B_CartTotal_Test {
    @isTest public static void test001() {
        Assert.isNotNull(NB2B_CartTotal.loremIpsum());   
        Assert.isNotNull(NB2B_CartToOrder2.loremIpsum());   
    }
}