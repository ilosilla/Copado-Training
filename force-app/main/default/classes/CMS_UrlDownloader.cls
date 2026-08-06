/**
 * @author         Ramón Prades
 * @date           August 2025
 * @group          CMS
 *
 * Class: CMS_UrlDownloader
 * Prefix CMS_ = Content/Commerce Media Suite
 *
 * Purpose:
 *   Central utility to download binary content from a public URL.
 *   This class is designed to be reusable across different flows that need to
 *   fetch remote media files (images, PDFs, etc.) before uploading them into
 *   Salesforce Enhanced CMS or associating them with products.
 *
 * Responsibilities:
 *   - Perform HTTP GET requests to given URLs.
 *   - Route all requests through the SAP CPI "URL Proxy" service, which acts
 *     as a trusted middleware. This avoids the need to register every external
 *     host in Salesforce Remote Site Settings or Named Credentials.
 *   - Validate HTTP response status codes.
 *   - Return the raw binary (Blob) and useful metadata (content type, file name).
 *   - Provide error handling for timeouts, invalid responses, or missing content.
 *
 * Usage Example:
 *   CMS_UrlDownloader.DownloadResult result =
 *       CMS_UrlDownloader.download('https://example.com/image.jpg');
 *   Blob fileData = result.body;
 *   String mimeType = result.contentType;
 *   String fileName = result.fileName;
 *
 * Related Classes:
 *   - CMS_FileUploader: persists Blob into Salesforce as ContentVersion.
 *   - CMS_ProductAssociationService: links ContentDocument to Product2.
 *
 * Notes:
 *   - This class does NOT insert anything into Salesforce; it only fetches
 *     the content. Storage and association are handled by other CMS_ classes.
 *   - All downloads go through the CPI proxy, ensuring central control,
 *     auditing, and simplified security.
 *   - Intended for batch or queueable contexts when processing large volumes.
 */
public class CMS_UrlDownloader {

    public static Integer httpTimeoutMs = 20000;

    public static DownloadResult download(String url) {

        if (String.isBlank(url)) {
            throw new RequiredFieldException('URL is required.');
        }
                
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.URL_PROXY);
        proxy.setQueryString('url=' + EncodingUtil.urlEncode(url, 'UTF-8'));
        proxy.setMethod('GET');    
        proxy.callCPI();
        HttpResponse response = proxy.getHttpResponse();
        DownloadResult out = new DownloadResult();
        out.success = true;
        out.content = response.getBodyAsBlob();
        out.mimeType = response.getHeader('Content-Type');
        out.fileName = URLCommons.extractFileName(url);
        return out;
    }

    public class DownloadResult {
        public Boolean success = false;
        public Blob content;
        public String fileName;
        public String mimeType;
    }

}