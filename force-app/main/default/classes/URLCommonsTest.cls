@isTest public class URLCommonsTest {

    @IsTest
    public static void testConvertParamsToLower() {
        String url = '/algo/mas/1111111111?ApprovedBY=pepe&algo=mas&booleano1&booleano2&complejo=true';
        Map<String, String> params = URLCommons.getURLParams(url);
        params = URLCommons.convertKeysToLowerCase(params);
        Assert.areEqual(5, params.size(), 'There should be 5 params');
        Assert.isTrue(params.containsKey('approvedby'), 'wrong value');
    } 
    @isTest static void testGetParams() {
        String url = '/algo/mas/1111111111?approvedBy=pepe&algo=mas&booleano1&booleano2&complejo=true';
        Map<String, String> params = URLCommons.getURLParams(url);
        Assert.areEqual(5, params.size(), 'There should be 5 params');
        Assert.areEqual('true', params.get('complejo'), 'wrong value');
    }

    @isTest static void testGetParamToLowers() {
        String url = '/algo/mas/1111111111?approvedBy=pepe&algo=mas&booleano1&booleano2&COMPLEJO=true';
        Map<String, String> params = URLCommons.getURLParamsToLower(url);
        Assert.areEqual(5, params.size(), 'There should be 5 params');
        Assert.areEqual('true', params.get('complejo'), 'wrong value');
    }

    @isTest static void testGetParamsEmpty() {
        String url = '/algo/mas/1111111111';
        Map<String, String> params = URLCommons.getURLParams(url);
        Assert.areEqual(0, params.size(), 'There should be 0 params');
    }

    @isTest static void testGetId() {
        String url = '/algo/mas/12345?approvedBy=pepe&algo=mas&booleano1&booleano2&COMPLEJO=true';
        String id = URLCommons.getURLId(url);
        Assert.areEqual('12345', id, 'Wrong id');
    }

    @isTest static void testExtractFile() {
        String url = 'https://www.domain.com/subsite/fichero.pdf?download=true';
        String fileName = URLCommons.extractFileName(url);
        Assert.areEqual('fichero.pdf', fileName, 'Wrong filename read: ' + fileName);
    }

    @isTest static void testExtractFile2() {
        String url = 'https://www.domain.com/subsite/i.php?/fichero.pdf&download=true';
        String fileName = URLCommons.extractFileName(url);
        Assert.areEqual('fichero.pdf', fileName, 'Wrong filename read: ' + fileName);
    }


    @isTest static void inferMime1() {
        String fileName = null;
        String mime = URLCommons.inferMimeType(fileName);
        Assert.areEqual('application/octet-stream', mime, 'Wrong MIME');

        fileName ='fichero';
        mime = URLCommons.inferMimeType(fileName);
        Assert.areEqual('application/octet-stream', mime, 'Wrong MIME');

        fileName = 'foto.png';
        mime = URLCommons.inferMimeType(fileName);
        Assert.areEqual('image/png', mime, 'Wrong MIME');
    }

}