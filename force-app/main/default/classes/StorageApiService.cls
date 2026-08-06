/**
* @author Ivan Losilla
* @date April 2025
* @group Storages
* @test StorageApiServiceTest
*/
public class StorageApiService {
    private String storageUrl = SAPCPIProxy.STORAGE_API_ENDPOINT;

    public StorageApiFolderResult readFolder(String path) {
        SAPCPIProxy proxy = new SAPCPIProxy(this.storageUrl + '/' + path + '/');
        proxy.setMethod('GET');
        String res = proxy.callCPI();
        return (StorageApiFolderResult) JSON.deserialize(res, StorageApiFolderResult.class);
    }

    public String readFile(String path) {
        SAPCPIProxy proxy = new SAPCPIProxy(this.storageUrl + '/' + path);
        proxy.setMethod('GET');
        return proxy.callCPI();
    }

    public String moveFile(String path, String newPath) {
        SAPCPIProxy proxy = new SAPCPIProxy(this.storageUrl + '/' + path);
        proxy.setMethod('PATCH');
        proxy.setJSONBody('{"moveToPath": "' + newPath + '"}');
        return proxy.callCPI();
    }

    public class StorageApiFolderResult {
        @InvocableVariable
        public String folder;

        @InvocableVariable
        public List<StorageApiFileResult> items;

        @InvocableVariable
        public Integer totalItems;
    }

    public class StorageApiFileResult {
        @InvocableVariable
        public String name;

        @InvocableVariable
        public String type;

        @InvocableVariable
        public Integer size;

        @InvocableVariable
        public Datetime modified;

        @InvocableVariable
        public String url;
    }
}