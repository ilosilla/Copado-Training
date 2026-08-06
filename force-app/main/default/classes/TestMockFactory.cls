@isTest
public class TestMockFactory implements HttpCalloutMock {
  
  protected Map<MockEndpoint, HttpResponse> responses;  
  private HttpResponse  defaultResponse;
  private Map<String, Integer> occurrences;
  
  public TestMockFactory(Map<MockEndpoint, HttpResponse> responses) {
    this.responses = responses;
    this.occurrences = new Map<String,Integer>();
  }

  public void setDefaultResponse(Integer code, String status, String body) {
    this.defaultResponse = new HttpResponse();
    this.defaultResponse.setStatus(status);
    this.defaultResponse.setStatusCode(code);
    this.defaultResponse.setBody(body);
  }
  
  public HTTPResponse respond(HTTPRequest req) {
    String endpoint = req.getEndpoint();
    System.debug('MF endpoint = ' + endpoint);
    Integer occurrence = this.occurrences.get(endpoint) ?? 0;
    System.debug('MF occurence: ' + occurrence);
    MockEndpoint mEndpoint = new MockEndpoint(endpoint, occurrence);
    HTTPResponse result =  this.responses.get(mEndpoint);
    if (result == null) {
       mEndpoint = new MockEndpoint(endpoint, -1);
       result =  this.responses.get(mEndpoint);
       System.debug('MF result: ' + result);
    }
    this.occurrences.put(endpoint, occurrence + 1);
    if (result != null) {
      System.debug('MF return not null');
      return result;
    } else {
      System.debug('MF return default');
      return defaultResponse;
    }
  }

  public static HttpResponse getHttpResponse(Integer code, String status, String body) {
    HttpResponse res = new HttpResponse();
    res.setStatus(status);
    res.setStatusCode(code);
    res.setBody(body);
    return res;
  }

  public class MockEndpoint {
    String url;
    Integer occurrence;

    public MockEndpoint(String url, Integer occurrence) {
      this.url = url;
      this.occurrence = occurrence;
    }

    public Boolean equals(Object obj) {
      if (obj instanceof MockEndpoint) {
        MockEndpoint e = (MockEndpoint)obj;
          return ((this.url == e.url) && (this.occurrence == e.occurrence));
      }
      return false;
    }

    public Integer hashCode() {
      return (31 * url.hashCode()) + occurrence.hashCode();
    }
  }
}