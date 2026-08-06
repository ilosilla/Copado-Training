/**
 * @author         Ramón Prades
 * @date           October 2025
 * @layer          Integrations
 * @description    Utility class to access the Storage API services (viaCPI)
*/
public class StorageAPIHelper {
    
    static final String VALID_SERVICES = '|porsamarket|mbank|';

    private String storageName;

    public StorageAPIHelper(String storageName) {
        if (!VALID_SERVICES.containsIgnoreCase('|' + storageName + '|')) {
            throw new ValidationException('Invalid Storage: ');
        }
        this.storageName = storageName;
    }

    public DirectoryDTO dir(String folder) {        
        if (!folder.startsWith('/')) {
            folder = '/' + folder;
        }
        if (!folder.endsWith('/')) {
            folder += '/';
        }
        String path = '/' + storageName + folder;
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.STORAGE_API_ENDPOINT);
        proxy.setPath(path);
        proxy.setMethod('GET');
        String response = proxy.callCPI();
        return (DirectoryDTO) JSON.deserialize(response, DirectoryDTO.class);        
    }

    public String readTextFile(String filePath) {        
        if (!filePath.startsWith('/')) {
            filePath = '/' + filePath;
        }       
        String path = '/' + storageName + filePath;
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.STORAGE_API_ENDPOINT);
        proxy.setPath(path);
        proxy.setMethod('GET');
        String response = proxy.callCPI();
        return response;
    }

    public void moveFile(String filePath, String folder) {
        if (!filePath.startsWith('/')) {
            filePath = '/' + filePath;
        }   
        if (!folder.startsWith('/')) {
            folder = '/' + folder;
        }
        if (!folder.endsWith('/')) {
            folder += '/';
        }
        String body = '{"moveToPath":"' + folder + '"}';
        String path = '/' + storageName + filePath;
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.STORAGE_API_ENDPOINT);
        proxy.setPath(path);
        proxy.setQueryString('overwrite=true&createDirectory=true');
        proxy.setMethod('PATCH');        
        proxy.setJSONBody(body);
        proxy.callCPI();
    }
    public class DirectoryDTO {
        public String folder;
        public Integer totalItems;
        public DirectoryEntryDTO[] items;
    }

    public class DirectoryEntryDTO {
        public String Name;   
        public String Type;
        public Datetime Modified;
        public String Url;
        public Integer Size;
    }
}