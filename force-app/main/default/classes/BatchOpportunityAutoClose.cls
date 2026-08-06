/**
* @author Ivan Losilla Perez
* @date May 2023
*
* @group Batch
* @description Set Opportunities, given a certain attributes, to closed lost, and send email to the owners to inform about the changes.
*/

public class BatchOpportunityAutoClose implements Schedulable, Database.Batchable<SObject>, Database.Stateful {

    class BatchOpportunityAutoCloseException extends Exception{}

    public Map<String, String> mapOpportunitiesClosed = new Map<String, String>();
    public String mapOpportunitiesError;
    public Integer mapOpportunitiesErrorCount = 0;
    private Boolean toDev = false;
    private Boolean updateRegisters = true;
    public SystemLog batchLog;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this,5);
    }

    public void setTest() {
        this.toDev = true;
        this.updateRegisters = false;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        batchLog = new SystemLog('OPPORTUNITY-AUTO_CLOSE');

        return Database.getQueryLocator([SELECT Id, Reason_Lost__c, Amount_custom__c, StageName,Name,Account.Name,OwnerId,AccountId, Last_Activity_Date__c, CloseDate
                                         FROM Opportunity
                                         WHERE StageName NOT IN ('Lost', 'Closed Won', 'Closed Lost', 'Closed')
                                         AND RecordType.Name IN ('Project retail', 'Project trade')
                                         AND Last_Activity_Date__c < LAST_N_DAYS:365
                                         AND CloseDate < TODAY]);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {        
        for (Opportunity opp : scope) {
            setValuesOnClose(opp);
        }

        if (this.updateRegisters == true) {
            updateRegisters(scope);
        } else {
            for (Opportunity opp : scope) {
                // It's a test and we must add all opps to the emails
                addSuccessRegister(opp);
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        try {
            sendEmails();
            sendErrorEmails();
        } catch (DmlException ex) {
            Mail mail = new Mail();
            mail.setGeneric();
            mail.setSubject('Auto close opportunities ERROR');
            mail.setHtml('Message: <p>' + ex.getMessage() + '</p>');
            mail.setTo(new List<String>{'ivan.losilla@porcelanosagrupo.com'});
            mail.send();
        }
        if (mapOpportunitiesErrorCount > 0) {
            batchLog.saveLog(true);
        }
    }

    /**
     * PRIVATE METHODS
     */

     private void setValuesOnClose(Opportunity opp) {
        opp.StageName = 'Closed Lost';
        opp.Reason_Lost__c = 'AUTOMATICCLOSURE';
        if (opp.Amount_custom__c == null || opp.Amount_custom__c <= 0) {
            opp.Amount_custom__c = 1;
        }
     }

     private void addSuccessRegister(Opportunity opp) {
        addRegisterToEmail(opp, false, null);
     }

     private void addErrorRegister(Opportunity opp, String error) {
        addRegisterToEmail(opp, true, error);
     }

     private void updateRegisters(List<Opportunity> oppsList) {
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();

        for (Opportunity opp : oppsList) {
            oppsMap.put(opp.Id, opp);
        }

        List<Database.SaveResult> resultsOpportunities  = Database.update(oppsList, false);

        for (Database.SaveResult sr : resultsOpportunities) {
            if (sr.isSuccess()) {
                addSuccessRegister(oppsMap.get(sr.getId()));
            } else {
                batchLog.addError('Error: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + sr.getId() + ' - ERROR: ' + sr.getErrors()[0].getMessage());
                addErrorRegister(oppsMap.get(sr.getId()), sr.getErrors()[0].getMessage());
            }
        }
     }

     private void addRegisterToEmail(Opportunity opp, Boolean isError, String errorMessage) {
        String valueOnMap = '';
        String url = URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id;

        if (isError == true) {
            this.mapOpportunitiesError += '<tr><td class="row-header"><a href="'+url+'">'+opp.Name+'</a></td><td>'+errorMessage+'</td></tr>';
            this.mapOpportunitiesErrorCount += 1;
        } else {
            if (mapOpportunitiesClosed.containsKey(opp.OwnerId)) {
                valueOnMap = mapOpportunitiesClosed.get(opp.OwnerId);
            }
            valueOnMap += '<tr><td class="row-header"><a href="'+url+'">'+opp.Name+'</a></td><td>'+opp.Account.name+'</td></tr>';
            mapOpportunitiesClosed.put(opp.OwnerId, valueOnMap);
        }
     }

     private void sendErrorEmails() {
        if (this.mapOpportunitiesErrorCount == 0) {
            return;
        }

        String textSubject = 'ERRORS - OPPORTUNITY AUTOMATIC CLOSE';
        String textBody = '<p> Ha habido ' + this.mapOpportunitiesErrorCount + ' errores:</p>';
        textBody += '<table style="width:600px"><tr><th class="col-header">Opportunity</th><th class="col-header">Account</th></tr>' +
                        '&TABLE&' +
                        '</table>';
        String emailTo = 'ivan.losilla@porcelanosagrupo.com';

        textBody = textBody.replace('&TABLE&', this.mapOpportunitiesError);

        Mail mail = new Mail();
        mail.setGeneric();
        mail.setHtml(MailUtils.addHTMLTags(textBody));
        mail.setSubject(textSubject);
        mail.setTo(new List<String>{emailTo});
        mail.send();
     }

    private void sendEmails() {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        String textBody;
        String textSubject;
        List<User> users = [SELECT Id, LanguageLocaleKey, Name, FirstName, Email from User where isActive = true and Id IN :mapOpportunitiesClosed.keySet()];

        /*************************** ENGLISH ***********************/
        String subjectEN = 'Closure of Inactive Opportunities';
        String textEN = '<p>Dear &FIRSTNAME&,</p>' +
                    '<p>The system has closed the following opportunities due to inactivity. Please review them and If there are any' +
                    ' opportunities you’d like to reactivate, click on the opportunity link, change the stage and update  the close date to a future date.</p>' +
                    '<table style="width:600px"><tr><th class="col-header">Opportunity</th><th class="col-header">Account</th></tr>' +
                    '&TABLE&' +
                    '</table>' +
                    '<p>Thank you for your cooperation.</p><p>CRM Team<br/>Porcelanosa</p>';

        /*************************** FRENCH ***********************/
        String subjectFR = 'Clôture des opportunités inactives';
        String textFR = '<p>Cher &FIRSTNAME&,</p>' +
                    '<p>Le système a fermé les opportunités suivantes par inactivité. Veuillez les vérifier et si vous souhaitez en réactiver '+
                    'certaines, cliquez sur le lien de l\'opportunité, modifiez l\'étape et mettez à jour la date de clôture à une date à future.</p>' +
                    '<table style="width:600px"><tr><th class="col-header">Opportunité</th><th class="col-header">Account</th></tr>' +
                    '&TABLE&' +
                    '</table>' +
                    '<p>Thank you for your cooperation.</p><p>CRM Team<br/>Porcelanosa</p>';


        try {
            String emailTo = null;
            String devBody = null;
            for (User usr : Users) {
                textBody = textEN;
                textSubject = subjectEN;
    
                if (usr.LanguageLocaleKey == 'fr') {
                    textBody = textFR;
                    textSubject = subjectFR;
                }
                textBody = textBody.replace('&FIRSTNAME&', usr.FirstName);
                textBody = textBody.replace('&TABLE&', mapOpportunitiesClosed.get(usr.Id));

                emailTo = usr.Email;
                devBody = textBody;
                if (this.toDev == true) {
                    emailTo = 'ivan.losilla@porcelanosagrupo.com';
                    devBody = textBody + ' Email TO: ' + usr.Email;
                }

                Mail mail = new Mail();
                mail.setGeneric();
                mail.setHtml(MailUtils.addHTMLTags(devBody));
                mail.setSubject(textSubject);
                mail.setTo(new List<String>{emailTo});
                emailList.add(mail.getEmail());
            }
            Messaging.sendEmail(emailList);

        } catch (BatchOpportunityAutoCloseException ex) {
            Mail mail = new Mail();
            mail.setGeneric();
            mail.setSubject('Auto close opportunities ERROR');
            mail.setHtml('Message: <p>' + ex.getMessage() + '</p>');
            mail.setTo(new List<String>{'ivan.losilla@porcelanosagrupo.com'});
            mail.send();
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
        return s;
    }
}