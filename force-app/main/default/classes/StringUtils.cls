/**
* @author Ivan Losilla
* @date November 2020
*
* @group Utils
* @group-content ../../ApexDocContent/StringUtils.htm
*
* @description Different methods to work with Strings
*/
public class StringUtils {
    
    public static String toUpperCase(String text) {
        if(String.isNotEmpty(text) && String.isNotBlank(text)) {
            return text.toUpperCase().normalizeSpace();
        }
        return text;
    }

    /**
     * Splits a name into first name and last name
     */
    public static Map<String, String> splitName(String name) {
        Map<String, String> result = new Map<String, String>();
        String firstName = '';
        String lastName = '';
        String[] words = name.normalizeSpace().trim().split(' ');
        if (words.size() > 0) {
            switch on words.size() {
                when 1 {
                    lastName = words[0];
                }
                when 2 {
                    firstName = words[0];
                    lastName = words[1];
                }
                when 3 {
                    firstName = words[0] + ' ' + words[1];
                    lastName = words[2];
                }
                when else {
                    firstName = words[0] + ' ' + words[1];
                    for (Integer i = 2; i < words.size(); i++) {
                        lastName = lastName + ' ' + words[i];
                    }
                }
            } // switch
            result.put('firstName', firstName.normalizeSpace());
            result.put('lastName', lastName.normalizeSpace());
        } // if
        return result;
    } // splitName
        
}