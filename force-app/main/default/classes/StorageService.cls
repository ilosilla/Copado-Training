/**
* @author Ivan Losilla
* @date April 2025
* @group Storages
* @test StorageServiceTest
*/
public class StorageService {
    // Método para guardar un archivo en el repositorio
    public static Map<String, Object> saveFile(String path, String fileName, Blob content, Boolean isBase64) {
        Map<String, Object> fileData = new Map<String, Object>{
            'name' => fileName,
            'isBase64' => isBase64,
            'content' => content
        };
        String jsonBody = JSON.serialize(fileData);

        SAPCPIProxy proxy = new SAPCPIProxy(path);
        proxy.setMethod('PUT');
        proxy.setJSONBody(jsonBody);
        return (Map<String, Object>) JSON.deserializeUntyped(proxy.callCPI());
    }

    // Método para leer un archivo
    public static StorageServiceFile readFile(String fullpath) {
        StorageServiceFile result = new StorageServiceFile();
        String fileName;

        Integer lastSlashIndex = fullpath.lastIndexOf('/');
        if (lastSlashIndex != -1) {
            fileName = fullpath.substring(lastSlashIndex + 1);
        } else {
            fileName = fullpath; // Por si no hay slashes, asumimos que ya es el nombre
        }
        result.filename = fileName;

        SAPCPIProxy proxy = new SAPCPIProxy(fullPath);
        proxy.setMethod('GET');
        // Convert the input string to a Blob
        proxy.callCPI();
        
        // Encode the Blob as a Base64 string
        String base64String = EncodingUtil.base64Encode(proxy.getResponseBodyAsBlob());
        result.data = base64String;

        return result;
    }

    // Método para eliminar un archivo
    public Boolean deleteFile(String fullPath) {
        try {
            SAPCPIProxy proxy = new SAPCPIProxy(fullPath);
            proxy.setMethod('DELETE');
            proxy.callCPI();

            return true;
        } catch (Exception ex) {
            System.debug('deleteFile Error: ' + ex.getMessage());
            return false;
        }
    }

    public class StorageServiceFile {
        @InvocableVariable
        @AuraEnabled
        public String filename;

        @InvocableVariable
        @AuraEnabled
        public String data;

        public StorageServiceFile() {
            this.filename = null;
            this.data = null;
        }

        public StorageServiceFile(String name, String data){
            this.filename = name;
            this.data = data;
        }
    }
}