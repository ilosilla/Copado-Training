/**
 * @author         Ramón Prades
 * @date           February 2024
 * @group          Tests
 * @description    Test class
*/
@isTest public class ClaimRelatedStatsControllerTest {

    @testSetup private static void testSetup() {
        DataFactoryCase.createCollections(1);
    } // testSetup

    @isTest private static void test001() {
        Case c = [select Id from Case limit 1];
        ClaimRelatedStatsController.DataDTO dto = ClaimRelatedStatsController.getClaimStats(c.Id);
        Assert.areEqual(0, dto.accountClaims, ' No other cases should be found');
    } // test
}