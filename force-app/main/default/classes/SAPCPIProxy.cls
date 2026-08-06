/**
 * @author         Ramón Prades
 * @date           February 2025
 * @layer          Integrations
 * @description    Class to provide access to the services offered to Salesforce in SAP CPI
*/
public class SAPCPIProxy {

    public final static String OPEN_AI_ENDPOINT = '/api-repository/ai';
    public final static String STORAGE_REPORTS_ENDPOINT = '/v1/storage/reports';
    public final static String STORAGE_API_ENDPOINT = '/v1/storage-api';
    public final static String DVS_ENDPOINT = '/api-repository/v1/dvs';
    public final static String FACTORY_QUALITY = '/v1/intranet-api/quality/claims';
    public final static String PIM_ENDPOINT = '/v1/intranet-api/pim/products';
    public final static String PIM_IMAGES_ENDPOINT = '/intranet-api/imgrepo/v1/assets';
    public final static String URL_PROXY = '/x-api/url-proxy';
    public final static String STOCK_ENDPOINT = '/v1/erp/services/stock/sales-org/{sales-org}/{product-code}';
    public final static String STOCK_QUERY_ENDPOINT = '/erp/services/v2/stock/queries';
    public final static String CREDIT_ENDPOINT = '/v1/erp/services/credit/customer/{customer-id}/sales-org/{sales-org}?fullmode=false';
    public final static String ORDERS_ENDPOINT = '/v1/erp/orders';

    private String baseURL;
    private String apiKey;
    private String jsonBody;
    private String method; 
    private String endpoint; 
    private String path;
    private Integer timeout = 0;
    private String queryString;
    
    private HttpResponse response;
    private Integer responseCode;
    private String responseBody;
    private Blob responseBodyAsBlob;
    
    public SAPCPIProxy(String endpoint) {
        this.baseURL = SystemSettings.SAPAPIUrl ?? '';
        this.apiKey = SystemSettings.SAPCPIAPIKey; 
        this.endpoint = endpoint;
        this.method = 'POST'; // default
        // Remove trailing '/' from ths base URL
        if (this.baseURL?.endsWith('/')) {
            this.baseURL = this.baseURL.substring(0, this.baseURL.length() - 1);  // Remove last character
        }
    }

    public void setPath(String path) {
        this.path = path;
        if (!this.path.startsWith('/')) {
            this.path = '/' + this.path; 
        }
    }

    public void setTimeout(Integer milliSeconds) {
        this.timeout = milliSeconds;
    }

    public HttpResponse getHttpResponse() {
        return this.response;
    }

    public void setQueryString(String queryString) {
        this.queryString = queryString;
    }

    public void setJSONBody(String newBody) {
        this.jsonBody = newBody;
    }

    public void setMethod(String newMethod) {
        Set<String> allowedMethods = new Set<String>{'GET', 'POST', 'PUT', 'DELETE', 'PATCH'};
        if (!allowedMethods.contains(newMethod)) {
            throw new IllegalArgumentException('HTTP method not valid: ' + newMethod);
        }
        this.method = newMethod;
    }

    public Integer getResponseCode() {
        return this.responseCode;
    }

    public Boolean isSuccess() {
        return (this.responseCode >= 200 && this.responseCode <= 299);
    }

    public String getResponseBody() {
        return this.responseBody;
    }

    public Blob getResponseBodyAsBlob() {
        return this.responseBodyAsBlob;
    }

    public String callCPI() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String url = this.baseURL + this.endpoint;
        if (String.isNotBlank(this.path)) {
            url += this.path;
        }
        if (String.isNotBlank(this.queryString)) {
            url += '?' + this.queryString;
        }
        request.setEndpoint(url);
        request.setMethod(this.method);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('APIKey', this.apiKey ?? '');
        if (this.timeout > 0) {
            request.setTimeout(this.timeout);
        }
        if (this.jsonBody != null && this.method != 'GET') {
            request.setBody(this.jsonBody);
        }
        this.response = http.send(request);
        this.responseCode = this.response.getStatusCode();
        this.responseBody = this.response.getBody();
        this.responseBodyAsBlob = this.response.getBodyAsBlob();
        Boolean success = (this.responseCode >= 200 && this.responseCode <= 299);   
        if (!success) {
            throw new HttpException('Error calling SAP CPI: ' + this.responseCode + ' ' + this.responseBody);
        }
        return this.responseBody;
    }

    
}