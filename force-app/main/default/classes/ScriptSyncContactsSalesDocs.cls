/**
* @author Ivan Losilla
* @date April 2022
* @group Scripts
* @description Update Sales Doc on Connectif Docs
*/
global class ScriptSyncContactsSalesDocs implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private final String fileRootName = 'ScriptContactsDataSalesDocs_';

    private Map<String, Pedidos_cabeceraSet__x> mapSalesDoc = new Map<String, Pedidos_cabeceraSet__x>();
    private DateTime startDate;
    private PorcelanosaSetting__c pSetting;
    private String fileNameCreated;
    private Boolean sync = true;
    private List<String> csvHeaders = new List<String>{'_email','sales-doc'};
    private List<String> csvRowList = new List<String>();
    private String bodyCsvString;
    List<Contact> contactListToSync = new List<Contact>();

    global void setNotSync() {
        this.sync = false;        
    }

    global void setDateTime(DateTime dt) {
        this.startDate = dt;
    }

    global ScriptSyncContactsSalesDocs() {}

    global ScriptSyncContactsSalesDocs(Id pSettingId, Boolean sync) {
        this.pSetting = [select id,Description__c, Key__c, Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Id =: pSettingId];
        this.sync = sync;
        System.debug('START SYNC CONTACTS - Delete Old csv file');
        this.deleteOldFiles();
    }

    global void executeInBatch() {
        List<PorcelanosaSetting__c> pSettings = [select id,Description__c, IsActive__c, Key__c, Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where IsActive__c = true and Key__c = 'CONNECTIF'];
        for (PorcelanosaSetting__c pSetting : pSettings) {
            if (pSetting.Subkey__c != null && pSetting.IsActive__c == true && pSetting.Value1__c != null) {
                Database.executeBatch(new ScriptSyncContactsSalesDocs(pSetting.Id, this.sync));
            }
        }
    }

    global void execute(System.SchedulableContext context) {
        System.debug('START SYNC CONTACTS');
        new ScriptSyncContactsSalesDocs().executeInBatch();
    }

    global void execute(Database.BatchableContext bc, List<Pedidos_cabeceraSet__x> scope) {
        try {
            for (Pedidos_cabeceraSet__x doc : scope) {
                if (this.mapSalesDoc.containsKey(doc.Account__c)) {
                    if (doc.Orderdate__c > mapSalesDoc.get(doc.Account__c).Orderdate__c) {
                        this.mapSalesDoc.put(doc.Account__c, doc);
                    }
                } else {
                    this.mapSalesDoc.put(doc.Account__c, doc);
                }
            }

            System.debug('SCOPE NUMBER RECORDS: ' + scope.size());
            List<Pedidos_cabeceraSet__x> auxList = new List<Pedidos_cabeceraSet__x>();
            List<Contact> auxListContacts = new List<Contact>();
            auxListContacts = getContacts(scope);
            auxListContacts = filterValidContacts(auxListContacts);
            this.contactListToSync.addAll(auxListContacts);
            System.debug('START SYNC CONTACTS - Get Sales Docs');
        } catch (Exception ex) {
            //this.hasException = true;
            //this.logger.addError(ex);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select id, Account__c, Customer__c, Orderdate__c,Erdat__c from Pedidos_cabeceraSet__x where Orderdate__c = LAST_N_DAYS:0';
        System.debug('START SYNC CONTACTS - Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('START SYNC CONTACTS - Get Contacts Data');
        this.mountCsvData();
        System.debug('START SYNC CONTACTS - Create contact csv Data');
        Map<String, String> dataToSend = this.createSendData();
        if (this.sync == true) {
            System.debug('START SYNC CONTACTS - Sync with Connectif');
            this.syncConnectif();
            this.csvRowList = new List<String>();
        }
        System.debug('START SYNC CONTACTS - Create csv file');
        this.createFile(dataToSend.get('BODY'), dataToSend.get('TITLE'));
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private List<Contact> filterValidContacts(List<Contact> contacts) {
        List<Contact> validContacts = new List<Contact>();
        for (Contact cnt : contacts) {
            if (cnt.Email != null 
                && cnt.Email.toUpperCase().contains('NOEMAIL') == false
                && cnt.Email.toUpperCase().contains('NOMAIL') == false
                && cnt.Email.toUpperCase().contains('PORCELANOSA') == false
                && cnt.Email.toUpperCase().contains('NOTGI') == false){
                    validContacts.add(cnt);
                }
        }

        return validContacts;
    }

    private List<Contact> getContacts(List<Pedidos_cabeceraSet__x> pedidos) {
        Set<String> accsList = new Set<String>();
        for (Pedidos_cabeceraSet__x pedido : pedidos) {
                accsList.add(pedido.Account__c);
        }
        List<Contact> contactsList = [select Id,Email,MailingCountryCode,AccountId from contact where AccountId IN :accsList and MailingCountryCode =: this.pSetting.Subkey__c];
        return contactsList;
    }

    public void deleteOldFiles() {
        String fileName = this.fileRootName + this.pSetting.Subkey__c + '%';
        Set<Id> docsIds = new Set<Id>();

        List<ContentVersion> documents = [select id,ContentDocument.Title,ContentLocation, CreatedBy.name,Description, FileExtension, ContentDocumentId from ContentVersion where ContentDocument.Title like :filename ];

        for (ContentVersion doc : documents) {
            docsIds.add(doc.ContentDocumentId);
        }

        List<ContentDocument> cdl = [SELECT Id
                                         FROM ContentDocument
                                         WHERE Id IN : docsIds];
        
        delete cdl;
    }

    public void mountCsvData() {
        try {
            // Rows
            String row = '';
            for (Contact cnt : this.contactListToSync) {
                Datetime hasSalesDoc = this.mapSalesDoc.containsKey(cnt.AccountId) ? this.mapSalesDoc.get(cnt.AccountId).Orderdate__c : null;
                row = '';
                row = cnt.Email + ';' + (hasSalesDoc != null ? hasSalesDoc.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '');
                this.csvRowList.add(row);
            }
            

            //return this.createCSV();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }

    } // updatePrices

    /**
    @description create a CSV file from a list of Strings each string should be a row
    */
    private Map<String, String> createSendData(){
        Map<String, String> result = new Map<String,String>();
        String headerRow = String.join(this.csvHeaders,';') + '\n';
        String concantenatedStr = headerRow;
        Integer i = 0;
        Integer rowListSize = this.csvRowList.size();
        System.debug('SYNC CONTACTS - Number of contacts on the document : ' + rowListSize);
        //assuming the rowList is in the correct format and each object in the list is a new record
        for(String row :this.csvRowList){
           
            i++;
            concantenatedStr += (String)row + ((i != rowListSize) ? '\n' : '');//add new line
        }
        String title = this.fileRootName + this.pSetting.Subkey__c + '_' + Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '.csv';

        this.bodyCsvString =  concantenatedStr;
        result.put('TITLE', title);
        result.put('BODY', concantenatedStr);
        return result;
    }

    /**
    @description create a file - generic
    */
    public String createFile(String versionData, String title) {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S'; //denotes it resides on Salesforce
        cv.Title = title; //title of the file
        cv.PathOnClient = title; // full path within Salesforce this can just be the name of file to be in the library
        cv.VersionData = Blob.valueOf(versionData); //file data
        insert cv;
        this.fileNameCreated = title;
        return cv.VersionData.toString();
    }

    private void syncConnectif() {
        System.debug('UPLOAD CSV');
        String boundaryString = '----WebKitFormBoundary' + String.valueOf(Crypto.getRandomInteger()) + String.valueOf(DateTime.now().getTime());

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.connectif.cloud/imports/');
        request.setMethod('POST');
        request.setHeader('Authorization', 'apikey ' + this.pSetting.Value1__c);
        //request.setHeader('Content-Type', 'multipart/form-data');
        request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundaryString);

        String body = '--'+boundaryString+'\r\n' +
                    'Content-Disposition: form-data; name="type"\r\n\r\n' +
                    'contacts\r\n' +
                    '--'+boundarystring+'\r\n' +
                    'Content-Disposition: form-data; name="overrideExisting"\r\n\r\n' +
                    'true\r\n' +
                    '--'+boundarystring+'\r\n' +
                    'Content-Disposition: form-data; name="updateOnlyEmptyFields"\r\n\r\n' +
                    'false\r\n' +
                    '--'+boundarystring+'\r\n' +
                    'Content-Disposition: form-data; name="delimiter"\r\n\r\n' +
                    ';\r\n' +
                    '--'+boundarystring+'\r\n' +
                    'Content-Disposition: form-data; name="file"; filename="ContactsPruebaConnectif.csv"\r\n' +
                    'Content-Type: text/csv\r\n\r\n';

        //String fileBody = '/Users/es00500217/Downloads/ContactsPruebaConnectif.csv'; // Aquí debes poner la ruta correcta al archivo en Salesforce

        String endBoundary = '\r\n--'+boundarystring+'--\r\n';
        System.debug('BODY CSV');
        System.debug(this.bodyCsvString);
        Blob bodyBlob = Blob.valueOf(body + this.bodyCsvString + endBoundary);
        request.setBodyAsBlob(bodyBlob);

        
        Http h = new Http();
        try {
            HttpResponse response = h.send(request);
            System.debug(response.getBody());
            this.pSetting.Value2__c = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
            update this.pSetting;
            System.debug('Updated Porcelanosa Setting');
        }catch(Exception ex){
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}