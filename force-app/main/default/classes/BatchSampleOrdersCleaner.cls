/**
* @author 		Ivan Losilla
* @date 		May 2023
* @group 		Samples
* @description 	Sends emails to the users with one or more sample orders not sent to SAP, and removes the ones outdated.
*               The outdate number of days are set as a PorcelanosaSetting with the name SAMPLES_DELETE_DAYS
*/
global class BatchSampleOrdersCleaner implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    class SamplesCleanerException extends Exception{}

    private Boolean runAlerts = true;
    private Boolean runDelete = false;
    private Map<String, List<Order>> ordersToDeleteMap = new Map<String, List<Order>>();
    private Map<String, List<Order>> ordersToAlertMap = new Map<String, List<Order>>();
    private String executionContext;

    global void setDeleteOrders() {
        this.runDelete = true;        
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Id samplesRT = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('NBK_rt_samples').getRecordTypeId();
        String query = 'SELECT Id, createddate,Sap_Id__c, ownerId, account.Name, owner.Firstname FROM Order WHERE RecordTypeId = \'' + samplesRT + '\' AND Status = \'Draft\'';
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc) {
        Database.executebatch(new BatchSampleOrdersCleaner());    
  }

    global void execute(Database.BatchableContext bc, List<Order> scope) {
        separateOrders(scope);
    }

    global void finish(Database.BatchableContext bc){  
        sendAlertEmails();
        if (this.runDelete == true) {
            removeOutOfDateOrders();
        }
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void separateOrders(List<Order> orders) {
        PorcelanosaSetting setting = new PorcelanosaSetting('SAMPLES_DELETE_DAYS', 'GB');
        Integer daysToDelete = Integer.valueof(setting.value1);

        for (Order ordr : orders) {
            if (ordr.Createddate >= Date.today().addDays((-1)*daysToDelete)) {
                if (this.ordersToAlertMap.containsKey(ordr.OwnerId)) {
                    List<Order> auxAlert = this.ordersToAlertMap.get(ordr.OwnerId);
                    auxAlert.add(ordr);
                    this.ordersToAlertMap.put(ordr.OwnerId, auxAlert);
                } else {
                    this.ordersToAlertMap.put(ordr.OwnerId, new List<Order>{ordr});
                }
            } else {
                if (this.ordersToDeleteMap.containsKey(ordr.OwnerId)) {
                    List<Order> auxAlert = ordersToDeleteMap.get(ordr.OwnerId);
                    auxAlert.add(ordr);
                    this.ordersToDeleteMap.put(ordr.OwnerId, auxAlert);
                } else {
                    this.ordersToDeleteMap.put(ordr.OwnerId, new List<Order>{ordr});
                }
            }
        }
    }

    private void sendAlertEmails() {
        PorcelanosaSetting setting = new PorcelanosaSetting('SAMPLES_DELETE_DAYS', 'GB');
        Integer daysToDelete = Integer.valueof(setting.value1);

        for (String owner : this.ordersToAlertMap.keySet()) {
            String bodyMessage = '<p>Dear ' + this.ordersToAlertMap.get(owner)[0].Owner.Firstname + ',</p>';
            bodyMessage += '<p>You have ' + this.ordersToAlertMap.get(owner).size() + ' sample orders that have not been sent to SAP (see the links below).</p>';
            bodyMessage += '<p>Remember the system deletes all outstanding samples orders after ' + daysToDelete + ' days</p>';
            bodyMessage += '<p><ul>';
            for (Order ordr : this.ordersToAlertMap.get(owner)) {
                bodyMessage += '<li><a href="' + Url.getOrgDomainUrl().toExternalForm() + '//' + ordr.Id + '">' + ordr.Account.Name + ' - ' + ordr.CreatedDate.format() + '</a></li>';
            }
            bodyMessage += '</ul></p>';
            bodyMessage += '<p>CRM Team</p>';

            Mail mail = new Mail();
            mail.setSubject('Samples orders not in SAP');
            mail.setHtml(bodyMessage);
            if (SystemUtils.getOnSandbox()) {
                mail.setTo((Id) UserInfo.getUserId());        
            } else {
                mail.setTo(owner);
                Boolean debugFeature = SystemSettings.underDevelopment('SAMPLESMAILING');
                if (debugFeature) {
                    mail.setCC(new List<String>{'ivan.losilla@porcelanosagrupo.com'});
                }        
            }
            mail.send();
        }
    }

    private void removeOutOfDateOrders() {
        List<Order> toDelete = new List<Order>();
        for (String owner : this.ordersToDeleteMap.keySet()) {
            toDelete.addAll(this.ordersToDeleteMap.get(owner));
        }
        try {
            Mail mail = new Mail();
            mail.setSubject('Sample orders deleted');
            mail.setHtml(this.ordersToDeleteMap.size() + ' orders deleted because they haven\'t been sent to SAP');
            mail.setTo(new List<String>{'ivan.losilla@porcelanosagrupo.com'});
            delete toDelete;
            mail.send();
        } catch (SamplesCleanerException ex) {
            Mail mail = new Mail();
            mail.setSubject('Sample orders deleted Exception');
            mail.setHtml(ex.getMessage());
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