/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Commons
 * @description    HTML utility methods
*/
public class HTMLCommons {
    /**
     * Converts an HTML-formatted string into plain text.
     * @param htmlString The input HTML content.
     * @return A plain text version of the HTML.
     */
    public static String htmlToPlainText(String htmlString) {
        if (String.isEmpty(htmlString)) {
            return '';
        }

        // Step 1: Decode HTML entities (e.g., &amp; -> &, &lt; -> <, &gt; -> >)
        if (htmlString.contains('%')) {
            // Define regex to check for properly encoded %XX sequences
            Pattern validPercentEncoding = Pattern.compile('%[0-9A-Fa-f]{2}');
            Matcher matcher = validPercentEncoding.matcher(htmlString);

            // If a raw '%' exists without a valid %XX sequence, replace it
            if (!matcher.find()) {
                htmlString = htmlString.replace('%', '%25');
            }
        }
        htmlString = EncodingUtil.urlDecode(htmlString, 'UTF-8');

        // Step 2: Replace <br> and <p> with newlines for better readability
        htmlString = htmlString.replaceAll('<br\\s*/?>', '\n');
        htmlString = htmlString.replaceAll('<p\\s*/?>', '\n');

        // Step 3: Remove all remaining HTML tags
        htmlString = htmlString.replaceAll('<[^>]+>', '');

        // Step 4: Trim excessive whitespace
        htmlString = htmlString.replaceAll('\\s+', ' ').trim();

        return htmlString;
    }
}