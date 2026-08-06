/**
 * @author         Ramón Prades
 * @date           November 2023
 * @group          Cloud Integrations
 * @description    LIst of enterprise services published for Salesforce
*/
public class EnterpriseSalesforceCatalog {
    public static String COLLECTIONS_OPEN_API {        // To approve collections via link
        get { return SystemSettings.SAPAPIUrl + '/' + SystemSettings.SAPCPIInstance + '/openapi/v1/collection'; }
    }
    
    public static String CLAIMS_OPEN_API {        // To approve collections via link
        get { return SystemSettings.SAPAPIUrl + '/' + SystemSettings.SAPCPIInstance + '/openapi/v2/claim'; }
    }

    public static String FILE_UPLOAD_API {        // To upload a file via api
        get { return SystemSettings.SAPAPIUrl + '/' + SystemSettings.SAPCPIInstance + '/api/sobjects/ContentVersion'; }
    }

    public static String SAP_IS_API_KEY {        // API Key topa ccess the salesforce API from  SAP IS
        get { return SystemSettings.SAPCPIAPIKey; }
    }

}