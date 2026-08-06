/**
* @author 		Ramón Prades
* @date 		December 2022
* @group 		Tools
* @description  Test class
*/
@isTest public class SystemLogTest {

    @testSetup private static void testSetup() {
        SystemLogScenario__c sls = new SystemLogScenario__c();
        sls.Name = 'TEST';
        sls.MailTo__c = 'x@somesite.cxm';
        sls.MailSubjectPrefix__c = 'XXX';
        sls.LogLevel__c = 'Debug';
        insert sls;
    }

    @isTest private static void test01() {
        Account acc1 = new Account(Name='Test');
        SystemLog log = new SystemLog('TEST');
        log.setInputObject(acc1);
        log.setTag('Test Tag');
        log.addSection('Example');
        log.setInputData('DATA');
        log.setSummary('This is the summary line');
        try {
            log.addError('this is a test error');
            log.addWarning('This is a warning');
            log.addInfo('This is info'); 
            log.addDebug('This is debug info');
            // Force an exception
            Account acc = [select Id from Account limit 1];
            log.addDebug('the sentence above throws an exception ' + acc.Id);
        } catch (Exception ex) {
            log.addError(ex);
        }
        log.saveLog();
        log.saveLog(true);
        SystemLog__c[] logs = [select HasErrors__c, LogLines__c from SystemLog__c];
        System.assertEquals(1, logs.size(), 'There should be one log');
        Assert.isTrue(log.hasErrors(), 'Should be true');

        SystemLog__c logRecord = log.getLogRecord();
        Assert.isNotNull(logRecord, 'Record should not be null');
    }    
} // class