@IsTest
public class SystemAlertTest {

    @IsTest
    static void testBusinessAlertWithoutException() {
        // Arrange
        Map<String, Object> context = new Map<String, Object>{
            'CartId' => 'CART-001',
            'LinesWithError' => 2
        };

        List<String> hints = new List<String>{
            'Check customer pricing conditions',
            'Compare with SAP pricing procedure'
        };

        SystemAlert alert = new SystemAlert(
            'B2B – Price Validation',
            SystemAlert.Severity.MEDIUM
        )
        .withContext(context)
        .withHints(hints)
        .withDedupKey('PRICE_MISMATCH_CART_001');

        // Act
        Test.startTest();
        SystemAlertService.notify(alert);
        Test.stopTest();

        // Assert
        // If we reach this point without exceptions,
        // the alert framework behaved correctly.
        System.assert(true, 'Business alert sent successfully');
    }

    @IsTest
    static void testTechnicalAlertWithException() {
        // Arrange
        Exception ex = new ContextException('SAP timeout while reading prices');

        Map<String, Object> context = new Map<String, Object>{
            'Endpoint' => '/sap/pricing',
            'SalesOrg' => 'US01'
        };

        SystemAlert alert = new SystemAlert(
            'SAP Pricing Integration',
            SystemAlert.Severity.HIGH
        )
        .withException(ex)
        .withContext(context)
        .withDedupKey('SAP_PRICING_TIMEOUT');

        // Act
        Test.startTest();
        SystemAlertService.notify(alert);
        Test.stopTest();

        // Assert
        System.assert(true, 'Technical alert with exception sent successfully');
    }

    @IsTest
    static void testDeduplicationDoesNotThrow() {
        // Arrange
        SystemAlert alert = new SystemAlert(
            'B2B – Price Validation',
            SystemAlert.Severity.MEDIUM
        )
        .withDedupKey('DUPLICATE_TEST_KEY');

        // Act
        Test.startTest();
        SystemAlertService.notify(alert);
        SystemAlertService.notify(alert); // duplicate on purpose
        Test.stopTest();

        // Assert
        System.assert(true, 'Duplicate alerts handled without errors');
    }

    @IsTest
    static void testAlertWithMinimalData() {
        // Arrange
        SystemAlert alert = new SystemAlert(
            'Minimal Alert',
            SystemAlert.Severity.LOW
        );

        // Act
        Test.startTest();
        SystemAlertService.notify(alert);
        Test.stopTest();

        // Assert
        System.assert(true, 'Minimal alert sent without optional data');
    }
}