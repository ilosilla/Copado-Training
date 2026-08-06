/**
* @author 		Ramón Prades
* @date 		December 2022
* @group 		Tools
* @description  Class to write system logs (Object SystemLog__c)
*/
public without sharing class SystemLog {
    
    public static final String splitter = '-----------------------------------------------------------------<br/>';
    private static final Integer MAX_LINE_LENGTH = 80000;
    Boolean enabled = false;
    SystemLogScenario__c scenario;
    SystemLog__c record; 
    String separator = '<br/>';
    String section = '<br/>======================================================<br/>';
    
    String logLevel;
    Boolean isWritable = false;
    Boolean isOverflown = false;
    Integer numErrors = 0;
    Integer numWarnings = 0;


    /**
     * Use this method when  you can't insert a log record because the transaction is rolled back in an exception
     */
    @future(callout=true) public static void writeLog(String systemLogString) {
        SystemLog logger = (SystemLog) JSON.deserialize(systemLogString, SystemLog.class);
        logger.saveLog(true);
    }

    public SystemLog(String scenario) {
        try {
            this.enabled = false;
            SystemLogScenario__c[] scenarios  = [select Id, Name, LogLevel__c, MailTo__c, MailSubjectPrefix__c from SystemLogScenario__c where Name = :scenario];
            if (scenarios.size() > 0) {
                this.isOverflown = false;
                this.enabled = true;
                this.scenario = scenarios[0];
                this.logLevel = this.scenario.LogLevel__c;
                this.enabled = (this.LogLevel != 'Disabled');
                this.record = new SystemLog__c();
                this.record.LogLevel__c = this.LogLevel;
                this.record.ScenarioId__c = this.scenario.Id;   
                this.record.LogLines__c = '';     
                this.isWritable = (this.logLevel == 'Debug');
                this.numErrors = 0;
                this.numWarnings = 0;        
                this.addToLogLines(this.section + 'Log level is ' + this.record.LogLevel__c + ' - ');
                this.addToLogLines('GMT Time ' + System.now() + ' - ');
                this.addToLogLines('User is ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' ' + UserInfo.getUserEmail() + this.section);            
            }
        } catch(Exception ex) {
            this.addError(ex);
        }
    } // Constructor

    public Boolean hasErrors() {
        return (this.numErrors > 0);
    }

/*    public SystemLog(Id loggerId) {
        SystemLog__c logRecord = Database.query('select ' + )
    }*/


    public SystemLog__c getLogRecord() {
        if (this.enabled) {
            return this.record;
        } else {
            return null;            
        }
    }

    public void setSummary(String summary) {        
        if (this.enabled && String.isNotBlank(summary)) {
            if (summary.length() > 60) {
                summary = summary.substring(0, 60);
            }
            this.record.Summary__c = summary;
        }
    }

    /* Use this when the record is saved from the outside */
    public void setRecordId(Id id) {
        this.record.Id = id;
    }

    public void setInputData(String text) {
        if (this.enabled) {
            this.record.InputData__c = text;
        }
    }

    public void setTag(String value) {
        if (this.enabled) {
            this.record.Tag__c = value;
        }
    }

    public void setInputObject(List<SObject> l) {
        if (this.enabled) {
            this.record.InputData__c = JSON.serializePretty(l);
        }
    }

    public void setInputObject(SObject o) {
        if (this.enabled) {
            this.record.InputData__c = JSON.serializePretty(o);//generator.getAsString();
        }
    }

    public void addError(Exception ex) {        
        if (this.enabled) {
            this.numErrors++;
            if (this.logLevel == 'Errors') {
                this.isWritable = true;
            }
            this.addToLogLines('[ERROR] ' + ex.getTypeName() + ': ' + ex.getMessage() + '<br/>');
            addToLogLines(ex.getStackTraceString() + this.separator);
            this.record.HasErrors__c = true;
        }
    }

    public void addError(String text) {
        if (this.enabled) {
            this.numErrors++;
            if (this.logLevel == 'Errors') {
                this.isWritable = true;
            }
            this.addToLogLines('[ERROR] ' + text + separator);
            this.record.HasErrors__c = true;
        }
    }

    public void addWarning(String text) {
        if (this.enabled) {
            this.numWarnings++;
            if (this.logLevel == 'Warnings') {
                this.isWritable = true;
            }
            this.addToLogLines('[WARNING] ' + text + separator);
        }
    }

    public void addInfo(String text) {
        if (this.enabled) {
            if (this.logLevel == 'Info') {
                this.isWritable = true;
            }
            this.addToLogLines('[INFO] ' + text + separator);
        }
    }

    public void addSection(String text) {
        if (this.enabled) {            
            this.addToLogLines(section + text + section);
        }
    }

    public void addDebug(String text) {
        if (this.enabled) {
            if (this.logLevel == 'Debug') {
                this.isWritable = true;
            }
            this.addToLogLines('[DEBUG] ' + text + separator);
        }
    }

    public void saveLog() {
        this.saveLog(false);
    }

    public void saveLog(Boolean close) {
        if (this.enabled && this.isWritable) {   
            // Database.UpsertResult upsertResult = Database.upsert(this.record, false);  // AllOrNothing is false
            upsert this.record;
            if (close) {
                this.closeLog();
            }
        }
    }

    /* <<<<<<<<<<<<<<<<<<<<< PRIVATE METHODS >>>>>>>>>>>>>>>>>>>>> */

    private void addToLogLines(String txt) {
        if (String.isBlank(txt) || this.isOverflown) {
            return;
        }
        this.record.LogLines__c += txt;
        if (this.record.LogLines__c.length() > MAX_LINE_LENGTH) {
            this.isOverflown = true;
            this.record.LogLines__c = this.record.LogLines__c.substring(0, MAX_LINE_LENGTH);
        }
    }

    private void closeLog() {
        if (this.scenario.MailTo__c != null) {
            this.mailLog();
        }
    }

    private void mailLog() {
        String url =  URL.getOrgDomainUrl().toExternalForm() + '/' + this.record.Id;
        String link = '<a href="' + url + '">' + url + '</a>';
        if (this.enabled && String.IsNotBlank(this.scenario.MailTo__c)) {
            String subject = '[SYSLOG ' + this.scenario.Name + ']';
            if (String.IsNotBlank(this.scenario.MailSubjectPrefix__c)) {
                subject += ' ' + this.scenario.MailSubjectPrefix__c; 
            }
            if (this.record.HasErrors__c )  {
                subject += ' New log with ERRORS';
            } else {
                subject += ' New log OK';
            }
            List<String> mailAddresses = this.scenario.MailTo__c.split(';');
            Mail m = new Mail();
            m.setTo(mailAddresses);
            m.setSubject(subject);

            String info = 'Number of Errors: ' + this.numErrors + this.separator;
            info += 'Number of Warnings: ' + this.numWarnings + this.separator;

            String body = link + this.separator + info + this.record.LogLines__c + this.section + '<h1>Input Data</h1>' + '<pre>' + this.record.InputData__c + '</pre>';
            m.setHtml(body);
            m.send();
        }
    }
    
} // class