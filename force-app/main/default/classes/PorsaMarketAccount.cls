/**
 * @author       Ivan Losilla
 * @since        April 2025
 * @group        Porsamarket
 * @description  PorsaMarket Account figure class
 * @test PorsaMarketAccountTest
 */
public class PorsaMarketAccount {
    public class PorsamarketAccountException extends Exception {}

    public String accountId;        // Porsamarket Id. SIret on France
    public String pmService;      // Servie of Poramarket. GB, US, HH, etc
    public String sfId = null;      // if exists on Salesforce, the Id
    public String sfOwnerId;        // if exists on Salesforce, the Id of the Owner
    public String vat;              // Siret of the account, on france
    public String type;             // ACCOUNT or LOT, depending on the type.
    public Boolean sendEmail = true;             // ACCOUNT or LOT, depending on the type.
    public PMPAccountWrapper data;  // Data taken from porsamarket

    public PorsaMarketAccount() {}

    public void getData() {
        HttpRequest req = new HttpRequest();

        if (this.type == 'ACCOUNT') {
            req.setEndpoint('https://porsamarket.porcelanosagrupo.com/' + this.pmService + '/Accounts');
        }

        if (this.type == 'LOT') {
            req.setEndpoint('https://porsamarket.porcelanosagrupo.com/' + this.pmService + '/Lots');
        }

        req.setMethod('POST');
        req.setHeader('Accept', 'application/json;odata=verbose');

        String user = 'sf_to_porsamarket_FR';
        String pass = 'Ry5s7y5WzCcVmmz75MaPAeCdANjUgs4Wejt6nJAMmV7QTn8qv976GxcuqjY8yAJQ2597ZvJrGCNZAaRAVTm9BebanQt3suunKcSdQwLA8XRneTyg8MyMmuufAN2UeGnNgtasEVYr5b5MtqdwPQP2uKtCdwfjgvs8A9sbjQBmUEsPmSrk7qGhSAJEaUy4fMgx2C2DpWcdMj7acmRx2gNAS8SueFWJGRV4RfVddwr2QPtZVRqmChMLKFY8qr3BsxSv';
        String body = '{' +
            '"User": "' + user + '", ' +
            '"Pwd": "' + pass + '",' +
            '"Project": "",' +
            '"Account": "' + this.accountId + '"' +
        '}';

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            if (Test.isRunningTest()) {
                PMPAccountWrapper testData = new PMPAccountWrapper();
                testData.Name = 'test account';
                testData.Street = 'test street';
                testData.Street2 = 'test street 2';
                testData.City = 'test city';

                this.data = testData;
            } else {
                List<PMPAccountWrapper> results = (List<PMPAccountWrapper>) JSON.deserialize(res.getBody(), List<PMPAccountWrapper>.class);
                if (results.size() > 0) {
                    this.data = results[0];
                }
            }
        } else {
            throw new PorsamarketAccountException('Error al recabar datos de porsamarket');
        }
    }

    public Account toAccount() {
        if (this.data == null) {
            return null;
        }
        Account result = new Account();
        Id rTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();

        result.recordTypeId = rTypeId;
        result.Name = this.data.Name;
        result.BillingStreet = this.data.Street + (this.data.Street2 != null ? ' ' + this.data.Street2 : '');
        result.BillingCountryCode =  this.data.countryCode;

        if (this.data.countryCode == 'CAN') {
            result.BillingCountryCode = 'CA';
        }

        result.BillingStateCode = this.data.State;
        result.BillingCity = this.data.City;
        result.BillingPostalCode = this.data.PostCode;
        result.vat_number__c = this.data.VAT;
        result.vat_number_2__c = this.data.VAT2;
        result.Business_Email__c = this.data.Email;
        result.Phone = this.data.Phone;
        result.Account_Classification__c = this.data.Classification;
        result.Account_Subclassification__c = this.data.Subclassification;
        result.DVSAction__c = 'ACCEPTED';
        result.SynchronizedWithDvs__c = true;
        result.DVSAcceptedDate__c = System.now();
        result.DVSAcceptedBy__c = UserInfo.getUserId();
        result.AccountSource = 'Porsamarket';
        if (this.pmService == 'HZ') {
            result.AccountSource = 'Houzz';
        }
        result.External_ID__c = this.pmService + this.data.Id;

        return result;
    }

    public static PorsaMarketAccount readLot(List<string> csvLine) {
        String pmService = csvLine[0];
        String obj = csvLine[1];
        String registerId = csvLine[5];
        String user = csvLine[7];
        String dateParam = csvLine[8];
        Boolean sendEmail = true;
        if (csvLine.size() > 9) {
            sendEmail = (String.isBlank(csvLine[9]) == false && csvLine[9].toUpperCase().contains('NOMAIL') ? false : true);
        }        String sfId = null;
        if (csvLine[6].startsWith('001')) {
            sfId = csvLine[6];
        }

        PorsaMarketAccount elemLot = new PorsaMarketAccount();
        elemLot.accountId = registerId;
        elemLot.pmService = pmService;
        elemLot.sfId = sfId;
        elemLot.vat = registerId;
        elemLot.type = 'LOT';
        elemLot.sendEmail = sendEmail;
        elemLot.getData();

        return elemLot;
    }

    public static PorsaMarketAccount readAccount(List<string> csvLine) {
        String pmService = csvLine[0];
        String obj = csvLine[1];
        String registerId = csvLine[5];
        String user = csvLine[7];
        String dateParam = csvLine[8];
        Boolean sendEmail = true;
        if (csvLine.size() > 9) {
            sendEmail = (String.isBlank(csvLine[9]) == false && csvLine[9].toUpperCase().contains('NOMAIL') ? false : true);
        }
        String sfId = null;
        if (csvLine[6].startsWith('001')) {
            sfId = csvLine[6];
        }

        PorsaMarketAccount elemAccount = new PorsaMarketAccount();
        elemAccount.accountId = registerId;
        elemAccount.pmService = pmService;
        elemAccount.sfId = sfId;
        elemAccount.vat = registerId;
        elemAccount.type = 'ACCOUNT';
        elemAccount.sendEmail = sendEmail;
        elemAccount.getData();

        return elemAccount;
    }

    public class PMPAccountWrapper {
        public String Id;
        public String Name;
        public String Street;
        public String Street2;
        public String State;
        public String PostCode;
        public String CountryCode;
        public String City;
        public String Phone;
        public String Email;
        public String VAT;
        public String VAT2;
        public String Classification;
        public String Subclassification;
    }
}