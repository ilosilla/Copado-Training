public class PorsaMarketFiles {
    public static StorageApiService.StorageApiFolderResult readFolder(Boolean isTest) {
        StorageApiService.StorageApiFolderResult result;
        StorageApiService aux = new StorageApiService();

        if (isTest) {
            result = aux.readFolder('porsamarket/TESTS/');
        } else {
            result = aux.readFolder('porsamarket/');
        }
        return result;
    }

    public static String readFile(String fileName, Boolean isTest) {
        StorageApiService aux = new StorageApiService();
        if (isTest) {
            return aux.readFile('porsamarket/TESTS/' + fileName);
        } else {
            return aux.readFile('porsamarket/' + fileName);
        }
    }

    public static String moveFile(String fileName, Boolean isTest) {
        StorageApiService aux = new StorageApiService();
        if (isTest) {
            return aux.moveFile('porsamarket/TESTS/' + fileName, '/TESTS/PROCESSED/');
        } else {
            return aux.moveFile('porsamarket/' + fileName, '/PROCESSED/');
        }
    }

    public static String moveErrorFile(String fileName) {
        StorageApiService aux = new StorageApiService();
        return aux.moveFile('porsamarket/' + fileName, '/ERRORS/');
    }

    @Future(callout=true)
    public static void moveProcessedFiles(List<String> filenames, Boolean isTest) {
        for (String filename : filenames) {
            moveFile(filename, isTest);
        }
    }

    @Future(callout=true)
    public static void moveErrorFiles(List<String> filenames) {
        for (String filename : filenames) {
            moveErrorFile(filename);
        }
    }
}