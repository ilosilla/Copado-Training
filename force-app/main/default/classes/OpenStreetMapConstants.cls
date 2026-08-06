/**
 * Description: Class to contain all the constant values used in OpenStreetMapAPI class
 *
 * Verson: 1.2.0
 */
public with sharing class OpenStreetMapConstants {
    public static final String URL_SUFFIX = '&format=jsonv2&limit=1&accept-language=en-US';
    public static final String METHOD_GET = 'GET';
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String APPLICATION_JSON = 'application/json';
    public static final Integer SUCCESS_STATUS_CODE = 200;
    public static final List<String> AVAILABLE_QUERY_PARAMS = new List<String>{
        'street',
        'city',
        'county',
        'state',
        'country',
        'postalcode'
    };
    public static final String OPEN_STREET_MAP_API_MOCK = 'OpenStreetMapAPIMock';
}