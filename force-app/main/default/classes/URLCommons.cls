/**
 * @author         Ramón Prades
 * @date           November 2023
 * @description    Common methods for URL manipulatiosn
*/
public class URLCommons {

    private static final Map<String, String> EXT_TO_MIME = new Map<String, String>{
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'gif'  => 'image/gif',
        'pdf'  => 'application/pdf',
        'doc'  => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls'  => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'ppt'  => 'application/vnd.ms-powerpoint',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'txt'  => 'text/plain'
    };


    /**
     * Converts the keys of a map of params to lower case
     */
    public static Map<String, String> convertKeysToLowerCase(Map<String, String> originalMap) {
        Map<String, String> lowerCaseMap = new Map<String, String>();
        for (String key : originalMap.keySet()) {
            lowerCaseMap.put(key.toLowerCase(), originalMap.get(key));
        }
        return lowerCaseMap;
    }
    
    /**
     * Get the ID form a URL like /domain/<id>
     */
    public static String getURLId(String url) {
        String id = url.substring(url.lastIndexOf('/')+1);
        Integer qm = id.indexOf('?');
        if (qm >= 0) {
            id = id.substring(0, qm);
        }
        return id;
    } // getId

    /**
     * Get params from URL like this:
     * /domain/<id>?p1=1&p2=2&p3
     */
    public static Map<String, String> getURLParams(String url) {
        return URLCommons.getURLParams(url, false);
    }

    /**
     * Get params from URL like this and converts the names to lower case
     * /domain/<id>?p1=1&p2=2&p3
     */
    public static Map<String, String> getURLParamsToLower(String url) {
        return URLCommons.getURLParams(url, true);
    }


    /**
     * Get params from URL like this:
     * /domain/<id>?p1=1&p2=2&p3
     * And converts the keys to lower case if instructed
     */
    private static Map<String, String> getURLParams(String url, Boolean toLower) {
        Map<String, String> paramsMap = new Map<String, String>();
        if (url.contains('?')) {
            String paramString = url.substring(url.lastIndexOf('?')+1);
            String[] params = paramString.split('&');
            for (String param : params) {
                String[] pair = param.split('=');
                String key = pair[0];
                String value = '';
                if (pair.size() > 1) {
                    value = pair[1];
                }
                if (toLower) {
                    key = key.toLowerCase();
                }
                paramsMap.put(key, value);
            }
        }
        return paramsMap;
    }

    public static String extractFileName(String url) {
        if (String.isBlank(url)) return null;
        
        // quita parámetros o ancla si hay
        String cleanUrl = url;

        // Ojo copn el maldito .php?/
        if (cleanUrl.contains('.php?/')) {
            cleanUrl = cleanUrl.replace('.php?/', '.php/');
            cleanUrl = cleanUrl.replaceFirst('&', '?');
        }
        Integer q = cleanUrl.indexOf('?');
        if (q != -1) cleanUrl = cleanUrl.substring(0, q);
        Integer h = cleanUrl.indexOf('#');
        if (h != -1) cleanUrl = cleanUrl.substring(0, h);

        Integer pos = cleanUrl.lastIndexOf('/');
        return (pos == -1) ? cleanUrl : cleanUrl.substring(pos + 1);
    }
    /**
     * Infers a MIME TYPE from a fielName
     */
    public static String inferMimeType(String fileName) {
        if (String.isBlank(fileName)) {
            return 'application/octet-stream'; // default
        } 
        List<String> parts = fileName.toLowerCase().split('\\.');
        if (parts.isEmpty()) {
            return 'application/octet-stream';
        }
        String ext = parts[parts.size() - 1];
        return EXT_TO_MIME.containsKey(ext) ? EXT_TO_MIME.get(ext) : 'application/octet-stream';
    }
    
}