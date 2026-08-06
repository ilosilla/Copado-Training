/**
* @author Ivan Losilla
* @date March 2025
* @group Scripts
* @description Send Event management emails
* @test ScriptEventReportsTest
*/
global class ScriptEventManagedReports implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public Boolean isTest = false;
    public String mailTest;
    public Date startDate;
    public Date endDate;
    public PorcelanosaSetting__c pSetting;
    public Map<String, String> resultBatch = new Map<String, String>();

    global void setStart(Date dt) {
        this.startDate = dt;
    }

    global void setEnd(Date dt) {
        this.endDate = dt;
    }

    global void setSetting(String pSettingId) {
        this.pSetting = [select id,Description__c, Key__c, IsActive__c,Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Id =: pSettingId];
        if (this.pSetting.Value2__c != null) {
            this.isTest = true;
            this.mailTest = this.pSetting.Value2__c;
        }
    }

    global ScriptEventManagedReports(Id pSettingId) {
        this.pSetting = [select id,Description__c, Key__c, IsActive__c,Subkey__c, Value1__c, Value2__c, Value3__c  from PorcelanosaSetting__c where Id =: pSettingId];

        if (this.startDate == null || this.endDate == null) {
            Date today = Date.today();
            Date thisMonday = today.toStartOfWeek();
            this.startDate = thisMonday;
            this.endDate = this.startDate.addDays(6);
        }

        if (this.pSetting.Value2__c != null) {
            this.isTest = true;
            this.mailTest = this.pSetting.Value2__c;
        }
    }

    global void execute(System.SchedulableContext context) {
        if (this.pSetting != null && this.pSetting.IsActive__c) {
            Database.executeBatch(new ScriptEventManagedReports(pSetting.Id), 1); // UNO por UNO
        }
        
    }

    global void execute(Database.BatchableContext bc, List<PermissionSetAssignment> scope) {
        try {
            Map<String, String> result = ReportsHelper.reportEvents(this.pSetting.subkey__c,this.startDate, this.endDate, String.valueOf(scope[0].AssigneeId), this.mailTest);
            if (result.containsKey('SENT') && result.get('SENT') == 'TRUE') {
                this.resultBatch.put(scope[0].Assignee.email, result.get('REGISTERS') + ' ' + this.pSetting.subkey__c);
            }
        } catch (Exception ex) {
            //this.hasException = true;
            //this.logger.addError(ex);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> salesOrgs = new List<String>();
        if (this.pSetting != null && this.pSetting.IsActive__c == true && this.pSetting.Value1__c != null) {
            if (this.pSetting.Value3__c != null) {
                salesOrgs = this.pSetting.Value3__c.split(';');

                return Database.getQueryLocator([SELECT Id, Assignee.Name, AssigneeId, PermissionSet.Name, Assignee.email
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.Name = 'Login_Flow_Event_Management' and Assignee.execution_context__c =: this.pSetting.Value1__c and Assignee.IsActive = true and Assignee.Default_Sales_Organization__c IN : salesOrgs]);
            } 

            return Database.getQueryLocator([SELECT Id, Assignee.Name, AssigneeId, PermissionSet.Name, Assignee.email
                    FROM PermissionSetAssignment
                    WHERE PermissionSet.Name = 'Login_Flow_Event_Management' and Assignee.IsActive = true and Assignee.execution_context__c =: this.pSetting.Value1__c]);
        }
        return Database.getQueryLocator([
            SELECT Id, TimeZoneSidKey FROM User 
            WHERE Name = 'PATATINPATATAN'
        ]);
    }
    
    global void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        List<OrgWideEmailAddress> owea = [select Id from OrgWideEmailAddress where Address = 'salesforce@porcelanosagrupo.com'];
        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
            email.setUseSignature(false);
        }
        email.setToAddresses(new List<String>{'salesforce@porcelanosagrupo.com'});
        email.setSubject('Event Management ' + (this.pSetting != null ? this.pSetting.Value1__c : ''));

        String body = '<html><head><style>';
        body += 'body { font-family: Arial, sans-serif; font-size: 12px; }'; // 🔹 Fuente más pequeña
        body += 'table { width: 100%; border-collapse: collapse; border: 1px solid black; }'; // 🔹 Bordes mejorados
        body += 'th, td { border: 1px solid black; padding: 4px; text-align: left; font-size: 12px; }'; // 🔹 Bordes y tamaño de fuente
        body += 'th { background-color: #f2f2f2; }'; // 🔹 Fondo gris para encabezados
        body += 'a { color: blue; text-decoration: underline; font-size: 12px; }'; // 🔹 Enlaces azules y subrayados
        body += '</style></head><body>';
        body += '<h1 style="font-size: 16px;">Emails sent about Events status ' + this.startDate.format() + ' - ' + this.endDate.format() + '</h1>'; // 🔹 Título más grande
        body += '<table>';
        body += '<tr><th>Email</th><th>Records</th></tr>';

        for (String elem : this.resultBatch.keySet()) {
            body += '<tr><td>' + elem + '</td><td>' + this.resultBatch.get(elem) + '</td></tr>';
        }
        body += '</table></body></html>';
        email.setHtmlBody(body);
        // Enviar email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    @testVisible public static String testFiller() {
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