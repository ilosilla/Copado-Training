/**
 * @author      Ramón Prades
 * @date        May 2026
 * @group       Deployment
 * @description Minimal smoke test used for production deployments that require
 *              RunSpecifiedTests but do not have a functional Apex change to test.
 *
 * Design notes:
 * - This class is intentionally independent from business logic and data.
 * - It is mainly intended for pure destructive deployments, such as removing
 *   unused legacy Apex classes or obsolete metadata.
 * - It should not be used as the only test class for deployments that create
 *   or modify production Apex logic.
 * - For functional Apex changes, the corresponding business test classes must
 *   be executed instead.
 */
@IsTest
private class DeploymentSmokeTest {

    @IsTest
    static void deploymentSmokeTest() {
        System.assertEquals(
            1,
            1,
            'Deployment smoke test should always pass.'
        );
    }

}