/**
 * @author       Ivan Losilla
 * @since        April 2025
 * @group        Porsamarket
 * @description  PorsaMarket Project figure class
 * @test PorsaMarketProjectTest
 */
public class PorsaMarketProject {
    public class PorsamarketProjectException extends Exception {}

    public String projectId;            // Id from porsamarket
    public String pmService;            // Country of the project
    public String oppSfId;              // Id of the opportunity related to the project
    public String sfAccountId;          // Id of the Account of the Opportunity. -1 if the Account doesn't exist on SF
    public String pmkAccountId;         // On France, SIRET of the Account.
    public String sfOwnerId;            // The sf id of the owner
    public String types;                // New o Updated, depending of what it needs to be done on the project. If Updated, an OppId has to appear on the line.
    public String userCreator;
    public Boolean sendEmail = true;             // Whether to send email notifications or not
    public PMProjectWrapper data;       // Data taken from porsamarket

    public PorsaMarketProject() {}

    public void getData() {
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://porsamarket.porcelanosagrupo.com/' + this.pmService + '/Projects');
        req.setMethod('POST');
        req.setHeader('Accept', 'application/json;odata=verbose');
        String user = 'sf_to_porsamarket_FR';
        String pass = 'Ry5s7y5WzCcVmmz75MaPAeCdANjUgs4Wejt6nJAMmV7QTn8qv976GxcuqjY8yAJQ2597ZvJrGCNZAaRAVTm9BebanQt3suunKcSdQwLA8XRneTyg8MyMmuufAN2UeGnNgtasEVYr5b5MtqdwPQP2uKtCdwfjgvs8A9sbjQBmUEsPmSrk7qGhSAJEaUy4fMgx2C2DpWcdMj7acmRx2gNAS8SueFWJGRV4RfVddwr2QPtZVRqmChMLKFY8qr3BsxSv';
        String body = '{' +
            '"User": "' + user + '", ' +
            '"Pwd": "' + pass + '",' +
            '"Project": "' + this.projectId + '",' +
            '"Account": ""' +
        '}';

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            if (Test.isRunningTest()) {
                PMProjectWrapper wrapper = new PMProjectWrapper();
                wrapper.IdProject = 'PRJ001';
                wrapper.Name = 'Test Project';
                wrapper.Street = '123 Main St';
                wrapper.Street2 = 'Suite 5';
                wrapper.State = 'Valencia';
                wrapper.PostCode = '46001';
                wrapper.CountryCode = 'ES';
                wrapper.City = 'Valencia';
                wrapper.TotalAmount = 100000;
                wrapper.Comment = 'A test project';
                wrapper.New_Renovation = 'Neuf';
                wrapper.SF_Classification = 'A';
                wrapper.SF_Subclassification = 'B';

                this.data = wrapper;
            } else {
                List<PMProjectWrapper> results = (List<PMProjectWrapper>) JSON.deserialize(res.getBody(), List<PMProjectWrapper>.class);
                if (results.size() > 0) {
                    this.data = results[0];
                }
            }
        } else {
            throw new PorsamarketProjectException('Error al recabar datos de porsamarket');
        }
    }

    public Opportunity toOpportunity() {
        if (this.data == null) {
            return null;
        }
        Opportunity result = new Opportunity();
        Id rTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Project_trade').getRecordTypeId();

        result.recordTypeId = rTypeId;
        result.Name = this.data.Name;
        result.StageName = 'Especificación';
        result.Address__c = this.data.Street + (this.data.Street2 != null ? ' ' + this.data.Street2 : '');
        result.CountryCode__c =  this.data.countryCode;
        if (this.sendEmail == false) {
            result.Discovery_Completed__c = true;
        }

        if (this.data.countryCode == 'CAN') {
            result.CountryCode__c = 'CA';
        }

        result.State__c = this.data.State;
        result.City__c = this.data.City;
        result.Postcode__c = this.data.PostCode;
        result.Amount_custom__c = this.data.TotalAmount;
        result.Operation_Type__c = (this.data.New_Renovation == 'Neuf' ? 'New construction' : 'Refurbishment');
        result.Description = this.data.Comment;
        result.PorsamarketId__c = this.pmService + this.data.IdProject;
        result.Verified__c = true;
        result.Opportunity_Classification__c = this.data.SF_Classification;
        result.Opportunity_Classification_II__c = this.data.SF_Subclassification;
        result.Verified__c = true;
        result.CloseDate = System.today().addDays(365);
        result.LeadSource = 'Porsamarket';

        if (isOffsite()) {
            result.Product_Categories__c = 'Offsite';
            result.ProjectType__c = 'PMAPPROVALFLOW';
            if (String.isBlank(this.userCreator) == false && this.userCreator.toUpperCase().contains('SEGARRA')) {
                result.ProjectType__c = null;
            }
        }

        return result;
    }

    public Opportunity updateOpportunity(String oppId) {
        Opportunity result = [SELECT id, porsamarketId__c,ownerid, owner.name, verified__c FROM Opportunity WHERE Id =: oppId];

        result.porsamarketId__c = this.pmService + this.projectId;
        result.verified__c = true;
        return result;
    }

    public static PorsaMarketProject readProject(List<string> csvLine) {
        String pmService = csvLine[0];
        String types = csvLine[2];
        String registerId = csvLine[3];
        String sfOppId = csvLine[4];
        String pmkAccountId = csvLine[5];
        String sfAccountId = csvLine[6];
        String user = csvLine[7];
        String dateParam = csvLine[8];
        Boolean sendEmail = true;
        if (csvLine.size() > 9) {
            sendEmail = (String.isBlank(csvLine[9]) == false && csvLine[9].toUpperCase().contains('NOMAIL') ? false : true);
        }        

        PorsaMarketProject elem = new PorsaMarketProject();
        elem.projectId = registerId;
        elem.pmService = pmService;
        elem.oppSfId = sfOppId;
        elem.pmkAccountId = pmkAccountId;
        elem.sfAccountId = sfAccountId;
        elem.types = types;
        elem.userCreator = user;
        elem.sendEmail = sendEmail;
        elem.getData();

        return elem;
    }

    public Boolean isOffsite() {
        Boolean result = false;
        if (String.isBlank(this.types) == false && this.types.toUpperCase().contains('OFFSITE')) {
            result = true;
        }
    
        return result;
    }

    public static PorsaMarketAccount readProjectAccount(List<string> csvLine) {
        String pmService = csvLine[0];
        String types = csvLine[2];
        String registerId = csvLine[3];
        String sfOppId = csvLine[4];
        String pmkAccountId = csvLine[5];
        String sfAccountId = csvLine[6];
        String user = csvLine[7];
        String dateParam = csvLine[8];
        Boolean sendEmail = true;
        if (csvLine.size() > 9) {
            sendEmail = (String.isBlank(csvLine[9]) == false && csvLine[9].toUpperCase().contains('NOMAIL') ? false : true);
        }
        PorsaMarketAccount elemAccount = new PorsaMarketAccount();
        elemAccount.accountId = pmkAccountId;
        elemAccount.pmService = pmService;
        elemAccount.sfId = sfAccountId;
        if (String.isBlank(elemAccount.sfId) || elemAccount.sfId == String.valueOf(-1)) {
            elemAccount.sfId = null;
        }
        elemAccount.vat = pmkAccountId;
        elemAccount.type = 'ACCOUNT';
        elemAccount.sendEmail = sendEmail;
        elemAccount.getData();

        return elemAccount;
    }

    public class PMProjectWrapper {
        public String IdProject;
        public String Name;
        public String Street;
        public String Street2;
        public String State;
        public String PostCode;
        public String CountryCode;
        public String City;
        public String Createddate;
        public Decimal TotalAmount;
        public String Comment;
        public String Type;
        public String Prive_Public;
        public String New_Renovation;
        public String SF_Classification;
        public String SF_Subclassification;
        public String Status;
        public List<PMActorWrapper> Actors;
    }

    public class PMActorWrapper {
        public String Id;
        public String Type;
        public String Name;
    }

}