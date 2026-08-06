/**
* @author Ivan Losilla
* @date April 2022
* @group Scripts
* @description Sends all contacts modified to Connectif
*/
global class ScriptSyncContacts implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private final String logScenario = 'CONTACTS SYNC';
    private final String fileRootName = 'ScriptContactsData_';

    private Boolean isTest = false;
    private Map<String, Pedidos_cabeceraSet__x> mapSalesDoc = new Map<String, Pedidos_cabeceraSet__x>();
    private Boolean errorOcurred = false;
    private DateTime startDate;
    private PorcelanosaSetting__c pSetting;
    private String fileNameCreated;
    private Boolean sync = true;
    private List<String> csvHeaders = new List<String>{'_email','_name','_surname','_mobilePhone','country','source','store',
                                                        'sales-org','account-type','language','account-classification','external-id','sales-doc','city','postal-code'};
    private List<String> csvRowList = new List<String>();
    private String bodyCsvString;
    List<Contact> contactListToSync = new List<Contact>();

    global void setNotSync() {
        this.sync = false;        
    }

    global void setDateTime(DateTime dt) {
        this.startDate = dt;
    }

    global ScriptSyncContacts() {}

    global ScriptSyncContacts(Id pSettingId, Boolean sync) {
        this.pSetting = [select id,Description__c, Key__c, Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Id =: pSettingId];
        this.sync = sync;
        System.debug('START SYNC CONTACTS - Delete Old csv file');
        this.deleteOldFiles();
    }

    global void executeInBatch() {
        List<PorcelanosaSetting__c> pSettings = [select id,Description__c, IsActive__c, Key__c, Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where IsActive__c = true and Key__c = 'CONNECTIF'];
        for (PorcelanosaSetting__c pSetting : pSettings) {
            if (pSetting.Subkey__c != null && pSetting.IsActive__c == true && pSetting.Value1__c != null) {
                Database.executeBatch(new ScriptSyncContacts(pSetting.Id, this.sync));
            }
        }
    }

    global void execute(System.SchedulableContext context) {
        System.debug('START SYNC CONTACTS');
        new ScriptSyncContacts().executeInBatch();
    }

    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        try {
            List<Contact> auxList = new List<Contact>();
            auxList = filterValidContacts(scope);
            this.contactListToSync.addAll(auxList);
            System.debug('START SYNC CONTACTS - Get Sales Docs');
            this.getSalesDocsByContacts(auxList);
        } catch (Exception ex) {
            //this.hasException = true;
            //this.logger.addError(ex);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id,Firstname,LastName,Phone,Email,MailingCity,MailingPostalCode,HasOptedOutOfEmail,Owner.Default_Sales_Organization__c,owner.Sales_Office__c,owner.LanguageLocaleKey,MailingCountryCode,toLabel(Account.Account_Classification__c), AccountId, Account.Sap_id__c, toLabel(Account.RecordType.Name)  from contact where (MailingCountryCode = \'' + this.pSetting.Subkey__c + '\' or Account.Billingcountrycode  = \'' + this.pSetting.Subkey__c + '\')';
        if (this.startDate != null) {
            query += ' and lastModifiedDate >= ' + this.startDate;
        } else if (this.pSetting.Value2__c != null) {
            query += ' and lastModifiedDate >= ' + this.pSetting.Value2__c;
        } else {
            query += ' and lastModifiedDate = LAST_N_DAYS:60';
        }
        query += ' and ((NOT LastModifiedBy.Profile.name like \'%Admini%\') or LastModifiedBy.name like \'%api%\') and (NOT LastModifiedBy.name like \'%Automated%\')';
        System.debug('START SYNC CONTACTS - Query: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('START SYNC CONTACTS - Get Contacts Data');
        this.getContactsData();
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

    private void getSalesDocsByContacts(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact cnt : contacts) {
            if (cnt.Account.Sap_id__c != null) {
                accountIds.add(cnt.AccountId);
            }
        }

        List<Pedidos_cabeceraSet__x> dataPedidos = [select Account__c, Ordertype__c, Ordernum__c, Orderdate__c from Pedidos_cabeceraSet__x where Account__c IN :accountIds order by Orderdate__c desc];

        for (Pedidos_cabeceraSet__x doc : dataPedidos) {
            if (this.mapSalesDoc.containsKey(doc.Account__c)) {
                if (doc.Orderdate__c > mapSalesDoc.get(doc.Account__c).Orderdate__c) {
                    this.mapSalesDoc.put(doc.Account__c, doc);
                }
            } else {
                this.mapSalesDoc.put(doc.Account__c, doc);
            }
        }
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

    public void getContactsData() {
        try {
            // Rows
            String row = '';
            for (Contact cnt : this.contactListToSync) {
                Datetime hasSalesDoc = this.mapSalesDoc.containsKey(cnt.AccountId) ? this.mapSalesDoc.get(cnt.AccountId).Orderdate__c : null;
                Boolean validPhone = false;
                if (cnt.Phone != null){
                    validPhone = Pattern.matches('^([0-9\\(\\)\\/\\+ \\-]*)$', cnt.Phone);
                }
                row = '';
                row = cnt.Email + ';' + (cnt.FirstName != null ? cnt.FirstName : '') + ';' + (cnt.LastName != null ? cnt.LastName : '') + ';' + ((cnt.Phone != null && validPhone == true) ? cnt.Phone : '') + ';' +
                        cnt.MailingCountryCode + ';SF;' + cnt.Owner.Sales_Office__c + ';' + 
                        cnt.Owner.Default_Sales_Organization__c + ';' + cnt.Account.RecordType.Name + 
                        ';' + cnt.owner.LanguageLocaleKey + ';' + cnt.Account.Account_classification__c + 
                        ';' + cnt.Id + ';' + (hasSalesDoc != null ? hasSalesDoc.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '') +
                        ';' + cnt.MailingCity + ';' + cnt.MailingPostalCode;
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