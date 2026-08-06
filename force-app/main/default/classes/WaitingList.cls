public class WaitingList {
    private WaitingList__c entry;

    public WaitingList(WaitingList__c wlistEntry) {
        this.entry = wlistEntry;
    }

    public WaitingList(Id wlistId) {
        List<WaitingList__c> wlists = getData(new Set<Id>{wlistId});
        if (wlists.size() == 1) {
            this.entry = wlists[0];
        }
    }

    public String getSalesperson() {
        return this.entry == null ? null : this.entry.Salesperson__c; 
    }

    public void assistCustomer() {
        try {
            if (this.entry != null) {
                if (this.entry.Salesperson__c == null) {
                    throw new ContextException(Label.wlist_noSalesperson);
                }
                
                if (this.entry.Status__c != 'ASSIGNED') {
                    throw new ContextException(Label.wlist_alreadyAssigned);
                } else {
                    this.entry.Status__c = 'INPROGRESS';
                    update this.entry;

                    if (this.entry.Phone__c != null) {
                        sendAssistSMS();
                    }
                }
            }
        } catch (ContextException ex) {
            throw new ContextException(ex.getMessage());
        }
    }

    public void assignSalesperson(Id salespersonId) {
        try {
            if (this.entry != null) {
                this.entry.Salesperson__c = salespersonId;
                this.entry.Status__c = 'ASSIGNED';
                update this.entry;
            }
        } catch (ContextException ex) {
            throw new ContextException('Something happened. Try again or contact an Admin');
        }
    }

    public void changeStatus(String newStatus) {
        try {
            if (this.entry != null) {
                this.entry.Status__c = newStatus;
                update this.entry;
            }
        } catch (ContextException ex) {
            throw new ContextException(ex);
        }
    }

    private static List<WaitingList__c> getData(Set<Id> wlistIds) {
        List<WaitingList__c> auxWaitingLists = [SELECT toLabel(Status__c) labelStatus, Name__c, Email__c,FirstName__c,Id,LastName__c,
                        Phone__c,SalesOffice__r.SalesOffice__c,Status__c, SalesOffice__r.CountryCode__c, SalesOffice__r.Name, Salesperson__r.Name, Salesperson__c,
                        Salesperson__r.FirstName, Salesperson__r.LastName, Transformed__c,Account__c,Account__r.Name,
                        Contact__c,Contact__r.Name,Appointment__c,CreatedDate, Owner.Email, Salesperson__r.Email
                        FROM WaitingList__c 
                        WHERE Id IN : wlistIds];
                    
        return auxWaitingLists;
	}

    public void sendNotificationsAssigned(Id userId, Boolean assist) {
        Id typeId = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'ApexNotification'].Id;
        
        try {
            if (typeId != null) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                if (assist == false) {
                    notification.setBody(this.entry.FirstName__c + ' ' + this.entry.LastName__c + ' is waiting for you');
                    notification.setTitle('A Customer is waiting');
                } else {
                    notification.setBody(this.entry.Name__c + ' is waiting for your assistance');
                    notification.setTitle(Label.wlist_customerWaiting);
                }
                notification.setNotificationTypeId(typeId);
                
                notification.setTargetId(this.entry.Id);
                notification.send(new Set<String>{this.entry.Salesperson__c});
            }
        } catch (ContextException e) {
            SystemUtils.debugWarning('WLASSIGNED', 'WAITING LIST ASIGNED MAIL NOT SENT', e);
        }
    }

    public void sendNotificationNewWLItem() {
        try {
            Set<String> userIds = new Set<String>();
            List<User> listUsers = new List<User>();
            if (this.entry != null){
                listUsers = [SELECT Id, Sales_Office__c from User where isActive = true and Sales_Office__c =: this.entry.SalesOffice__r.SalesOffice__c ];
            }
    
            for (user usr : listUsers) {
                userIds.add(usr.Id);
            }
            
            Id typeId = [SELECT Id FROM CUstomNotificationType WHERE DeveloperName = 'ApexNotification'].Id;
            if (typeId != null) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                Set<String> listSendTo = userIds;
    
                if (listSendTo != null && listSendTo.size() > 0) {
                    notification.setBody(Label.wlist_personWaiting.replace(this.entry.FirstName__c + ' ' + this.entry.LastName__c, '#NAME'));
                    notification.setTitle(Label.wlist_newPerson);
                    notification.setNotificationTypeId(typeId);
                    notification.setTargetId(this.entry.Id);
                    notification.send(listSendTo);
                }

                if (this.entry.Phone__c != null) {
                    sendWelcomeSMS();
                }
            }
        } catch (ContextException e) {
            SystemUtils.debugWarning('WLNEWENTRY', 'NEW ENTRY NORIFICATION FAILED', e);
        }
    }

    private void sendWelcomeSMS() {
        String messageSMS = Label.wlist_welcomeSms;
        String firstName = this.entry.FirstName__c == null ? '-' : this.entry.FirstName__c;
        String salesOfficeName = this.entry.SalesOffice__r.Name == null ? '-' : this.entry.SalesOffice__r.Name;
        messageSMS = messageSMS.replace('#FIRSTNAME', firstName);
        messageSMS = messageSMS.replace('#SALESOFFICENAME', salesOfficeName);
        sendSMS(this.entry.Phone__c, messageSMS, this.entry.SalesOffice__r.CountryCode__c);
    }

    private void sendAssistSMS() {
        String messageSMS = Label.wlist_assistSms;
        String firstName = this.entry.FirstName__c == null ? '-' : this.entry.FirstName__c;
        String salesPersonName = this.entry.Salesperson__r.FirstName == null ? '-' : this.entry.Salesperson__r.FirstName;
        messageSMS = messageSMS.replace('#FIRSTNAME', firstName);
        messageSMS = messageSMS.replace('#SALESPERSONNAME', salesPersonName);
        sendSMS(this.entry.Phone__c, messageSMS, this.entry.SalesOffice__r.CountryCode__c);
    }

    @future(callout = true)
    private static void sendSMS(String phone, String body, String country){
        SMS messageSend = new SMS(phone, body, country);
        messageSend.send();
    }

    public void sendWaitingAssistanceMail() {
        try {
            List<Mail> mailsToSend = new List<Mail>();
            Mail auxMail = new Mail();
            auxMail.setHtml(setHtml(this.entry.Salesperson__r.Name, this.entry.Name__c));
            auxMail.setGeneric(); // It will come from a generic email address
            auxMail.setTo(this.entry.Salesperson__c);
            auxMail.setSubject('A CUSTOMER IS WAITING YOUR ASSISTANCE');
            mailsToSend.add(auxMail);
    
            MailUtils.sendBatch(mailsToSend);
        } catch (ContextException e) {
            SystemUtils.debugWarning('WLASSIGNED', 'WAITING LIST ASIGNED MAIL NOT SENT', e);
        }
    }

    private static String setHtml(String ownerName, String personName) {
        String mailBody = '<html><head><style>'
                + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 200; } '
                + 'a { color: #666; } '
                + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
                + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:5px;border:1px solid DimGray;}'
                + '.row-header {background-color: #eff1f3;  font-weight: bold; width: 300px;} '
                + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
                + '.error-banner td {border-style:none; padding: 30px !important;} '
                + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
                + '.info-banner td {border-style:none;; padding: 30px !important;} '
                +  '</style></head><body>#BODY</body></html>';
        String longTextBody = Label.wlist_waitingAssistance;
        longTextBody = longTextBody.replace('#NAMESALESPERSON', ownerName == null ? '' : ownerName);
        longTextBody = longTextBody.replace('#NAMECUSTOMER', personName == null ? '' : personName);
        longTextBody = longTextBody.replace('#TEAMCRM', 'Porcelanosa USA');
        mailBody = mailBody.replace('#BODY',longTextBody);
        
        return mailBody;
    }
}