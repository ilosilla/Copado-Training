@IsTest
private class StringCommonsTest {

    @IsTest
    static void testTruncate_NullInput() {
        String input = null;
        String result = StringCommons.truncate(input, 100);
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @IsTest
    static void testTruncate_ShortString() {
        String input = 'Short text';
        String result = StringCommons.truncate(input, 100);
        System.assertEquals(input, result, 'Should return original string if length < max');
    }

    @IsTest
    static void testTruncate_ExactLength() {
        String input = 'x'.repeat(100);
        String result = StringCommons.truncate(input, 100);
        System.assertEquals(input, result, 'Should return original string if length == max');
    }

    @IsTest
    static void testTruncate_ExceedsLength() {
        String input = 'x'.repeat(150);
        String result = StringCommons.truncate(input, 100);
        System.assertEquals('x'.repeat(100), result, 'Should return truncated string');
        System.assertEquals(100, result.length(), 'Resulting string must be 100 chars long');
    }
}