/**
 * @author         Ramón Prades
 * @date           July 2025
 * @group          Utils
 * @description    Utility methods for working with String values
 */
public class StringCommons {

    /**
     * Truncates a string to the specified max length (inclusive).
     * If the input is null or shorter than maxLength, returns the original string.
     *
     * @param input     The original string
     * @param maxLength The maximum number of characters allowed
     * @return          Truncated string if needed, or the original one
     */
    public static String truncate(String input, Integer maxLength) {
        if (input == null) return null;
        if (input.length() <= maxLength) {
            return input;
        } else {
            return input.substring(0, maxLength);
        }
    }

}