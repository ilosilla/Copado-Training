/**
 * @description  : 
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 22-08-2023
 * @group        : 
 * @see          : 
**/
@isTest public class B2BCartToOrderDraftTest {

    @isTest private static void test001() {
        Assert.isNotNull(B2BCartToOrderDraft.loremIpsum());
    }

    @isTest private static void testLorem() {
        String l = NB2B_CartToOrder2.loremIpsum();
        Assert.isNotNull(l);
    }
}