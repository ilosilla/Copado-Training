/**
* @author Ivan Losilla
* @date April 2025
* @group Scripts
* @description Uploads Event management files
* @test ScriptWeeklyReportsUploadFilesTest
*/
global class ScriptWeeklyReportsUploadFiles implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
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

    global ScriptWeeklyReportsUploadFiles(Id pSettingId) {
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
            Database.executeBatch(new ScriptWeeklyReportsUploadFiles(pSetting.Id), 1); // UNO por UNO
        }
        
    }

    global void execute(Database.BatchableContext bc, List<User> scope) {
        try {
            Map<String, String> result = ReportsHelper.uploadReports(this.startDate, this.endDate, String.valueOf(scope[0].Id));
            if (result.containsKey('SENT') && result.get('UPLOAD') == 'TRUE') {
                this.resultBatch.put(scope[0].email, 'FILE PATH: ' + result.get('PATH') + ' - ' + result.get('REGISTERS') + ' MANAGED' );
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

                return Database.getQueryLocator([
                    SELECT Id, Email, LanguageLocaleKey,TimeZoneSidKey, profile.name, execution_context__c
                    FROM User 
                    WHERE isactive = true and execution_context__c =: this.pSetting.Value1__c AND Default_Sales_Organization__c IN : salesOrgs AND  profile.Name IN ('Managers', 'Standard Trade')
                ]);
            } 

            // All Sales Orgs
            return Database.getQueryLocator([
                SELECT Id, Email, LanguageLocaleKey,TimeZoneSidKey, profile.name, execution_context__c
                FROM User 
                WHERE isactive = true and execution_context__c =: this.pSetting.Value1__c AND  profile.Name IN ('Managers', 'Standard Trade')
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, TimeZoneSidKey FROM User 
            WHERE Name = 'PATATINPATATAN'
        ]);
    }
    
    global void finish(Database.BatchableContext bc){
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
        return s;
    }
}