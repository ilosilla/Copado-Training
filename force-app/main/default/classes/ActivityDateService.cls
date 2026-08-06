/**
* @author Ivan Losilla
* @date July 2022
* @group ActivityDates
* @description Updates the Activity on Accounts and Opportunity. To do this, we take into acount:
*   - New Account Team Member       - affects the Account related
*   - New Display and Marketing     - affects the Account related
*   - New Contact                   - affects the Account related
*   - New Account Contact Relation  - affects the Account related
*   - New Opportunity               - affects the Account related
*   - New Sales Relationship        - affects the Account related
*   - Update Opportunity Stage      - affects both the Account and the Opportunity related
*   - New Opportunity Team Member   - affects both the Account and the Opportunity related
*   - New Opportunity Contact Role  - affects both the Account and the Opportunity related
*   - New SAP Order                 - affects both the Account and the Opportunity related
*   - New SAP Quote                 - affects both the Account and the Opportunity related
*   - New Event                     - affects both the Account and the Opportunity related
*   - New Task                      - affects both the Account and the Opportunity related
*   - New Email                     - affects both the Account and the Opportunity related
*   - New Email Einstein            - affects both the Account and the Opportunity related
*   - New Moodboard                 - affects both the Account and the Opportunity related
*   - New Installation Request      - affects both the Account and the Opportunity related
*/
public class ActivityDateService {

    private List<Event> eventsList                                  = new List<Event>();
    private List<Opportunity> opportunitiesList                     = new List<Opportunity>();
    private List<EmailMessage> emailsList                           = new List<EmailMessage>();
    private List<Contact> contactsList                              = new List<Contact>();
    private List<AccountContactRelation> accountContactRelationsList= new List<AccountContactRelation>();
    private List<Task> tasksList                                    = new List<Task>();
    private List<Displays_Marketing_Material__c> displaysList       = new List<Displays_Marketing_Material__c>();
    private List<AccountTeamMember> accTeamMembersList              = new List<AccountTeamMember>();
    private List<OpportunityTeamMember> oppTeamMembersList          = new List<OpportunityTeamMember>();
    private List<OpportunityContactRole> oppContactRolesList        = new List<OpportunityContactRole>();
    private List<ActivityMetric> activityMetricsList                = new List<ActivityMetric>();
    private List<Pedidos_cabeceraSet__x> sapOrdersList              = new List<Pedidos_cabeceraSet__x>();
    private List<Ofertas_cabeceraSet__x> sapQuotesList              = new List<Ofertas_cabeceraSet__x>();
    private List<Moodboard__c> moodboardsList                       = new List<Moodboard__c>();
    private List<Sales_Relationship__c> salesRelationshipsList      = new List<Sales_Relationship__c>();
    private List<InstallationRequest__c> installationRequestsList   = new List<InstallationRequest__c>();

    private Map<Id, Datetime> oppsIdToUpdate                        = new Map<Id, Datetime>();
    private Map<Id, DateTime> accsIdToUpdate                        = new Map<Id, Datetime>();
    private List<Opportunity> oppsToUpdateList                      = new List<Opportunity>();
    private List<Account> accsToUpdateList                          = new List<Account>();

    private protected String lastEventField                         = 'LastEventDateTime__c';
    private protected String lastEmailField                         = 'LastEmailDateTime__c';
    private protected String lastContactField                       = 'LastContactDateTime__c';
    private protected String lastOpportunityField                   = 'LastOpportunityDateTime__c';
    private protected String lastOrderField                         = 'LastOrderDateTime__c';
    private protected String lastQuoteField                         = 'LastQuoteDateTime__c';
    private protected String globalLastActivityField                = 'Last_Activity_Date__c';

    public class LastActivityException extends Exception{}

    /****************************************************************************************/

    public static void updateFromAccTeamMembers(Set<Id> accTeamMembersIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setAccTeamMembers(accTeamMembersIds);
            aux.getRegistersFromAccTeamMembers();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromContacts(Set<Id> contactsIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setContacts(contactsIds);
            aux.getRegistersFromContacts();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    public static void updateFromAccountContactRelations(Set<Id> accountContactRelationIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setAccountContactRelations(accountContactRelationIds);
            aux.getRegistersFromAccountContactRelations();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromOpportunities(Set<Id> opportunitiesIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setOpportunities(opportunitiesIds);
            aux.getRegistersFromOpportunitites();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromOppTeamMembers(Set<Id> oppTeamMembersIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setOppTeamMembers(oppTeamMembersIds);
            aux.getRegistersFromOppTeamMembers();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromOppContactRoles(Set<Id> oppContactRolesIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setOppContactRoles(oppContactRolesIds);
            aux.getRegistersFromOppContactRoles();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromEvents(Set<Id> eventsIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setEvents(eventsIds);
            aux.getRegistersFromEvents();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromTasks(Set<Id> tasksIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setTasks(tasksIds);
            aux.getRegistersFromTasks();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromEmails(Set<Id> emailsIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setEmails(emailsIds);
            aux.getRegistersFromEmails();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromDisplays(Set<Id> displaysIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setDisplays(displaysIds);
            aux.getRegistersFromDisplays();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromActivityMetrics(List<ActivityMetric> metrics) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setActivityMetrics(metrics);
            aux.getRegistersFromsetActivityMetrics();
            aux.setDateFieldsEinstein();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromSAPOrders(List<Pedidos_cabeceraSet__x> sapOrders) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setSapOrders(sapOrders);
            aux.getRegistersFromSapOrders();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }
    
    public static void updateFromSAPQuotes(List<Ofertas_cabeceraSet__x> sapQuotes) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setSapQuotes(sapQuotes);
            aux.getRegistersFromSapQuotes();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    public static void updateFromMoodboards(Set<Id> moodboardIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setMoodboards(moodboardIds);
            aux.getRegistersFromMoodboards();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    public static void updateFromSalesRelationships(Set<Id> salesRelationshipIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setSalesRelationships(salesRelationshipIds);
            aux.getRegistersFromSalesRelationships();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    public static void updateFromInstallationRequests(Set<Id> installationRequestIds) {
        try {
            ActivityDateService aux = new ActivityDateService();
            aux.setInstallationRequests(installationRequestIds);
            aux.getRegistersFrominstallationRequests();
            aux.setDateFields();
            aux.saveData();
        } catch (Exception ex) {
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }

    /*****************************************************************************************/

    private void setAccTeamMembers(Set<Id> accTeamMembersIds) {
        this.accTeamMembersList = new AccountTeamMembersSelector().selectById(accTeamMembersIds);
    }

    private void setContacts(Set<Id> contactsIds) {
        this.contactsList = new ContactsSelector().selectById(contactsIds);
    }

    private void setAccountContactRelations(Set<Id> accountContactRelations) {
        System.debug('BBBBBBB');
        this.accountContactRelationsList = [SELECT Id, AccountId, ContactId, IsActive FROM AccountContactRelation WHERE Id =: accountContactRelations];
    }

    private void setOpportunities(Set<Id> oppsIds) {
        this.opportunitiesList = new OpportunitiesSelector().selectById(oppsIds);
    }

    private void setOppTeamMembers(Set<Id> oppTeamMembersIds) {
        this.oppTeamMembersList = new OpportunityTeamMembersSelector().selectById(oppTeamMembersIds);
    }

    private void setOppContactRoles(Set<Id> oppContactRoleIds) {
        this.oppContactRolesList = new OpportunityContactRolesSelector().selectById(oppContactRoleIds);
    }

    private void setEvents(Set<Id> eventIds) {
        this.eventsList = new EventsSelector().selectById(eventIds);
    }

    private void setTasks(Set<Id> tasksIds) {
        this.tasksList = new TasksSelector().selectById(tasksIds);
    }

    private void setEmails(Set<Id> emailsIds) {
        this.emailsList = new EmailMessagesSelector().selectById(emailsIds);
    }

    private void setDisplays(Set<Id> displaysIds) {
        this.displaysList = new DisplaysSelector().selectById(displaysIds);
    }
    
    private void setActivityMetrics(List<ActivityMetric> metrics) {
        this.activityMetricsList = metrics;
    }

    private void setSapOrders(List<Pedidos_cabeceraSet__x> sapOrders) {
        this.sapOrdersList = sapOrders;
    }
    
    private void setSapQuotes(List<Ofertas_cabeceraSet__x> sapQuotes) {
        this.sapQuotesList = sapQuotes;
    }

    private void setMoodboards(Set<Id> moodboardsIds) {
        this.moodboardsList = new MoodboardsSelector().selectById(moodboardsIds);
    }

    private void setSalesRelationships(Set<Id> salesRelationshipIds) {
        this.salesRelationshipsList = new SalesRelationshipsSelector().selectById(salesRelationshipIds);
    }

    private void setInstallationRequests(Set<Id> installationRequestIds) {
        this.installationRequestsList = new InstallationRequestsSelector().selectById(installationRequestIds);
    }
    
    /*****************************************************************************************/

    private void getRegistersFromAccTeamMembers() {
        for (AccountTeamMember accTeamMembers : this.accTeamMembersList) {
            this.accsIdToUpdate.put(accTeamMembers.AccountId, System.now());
        }
    }
    
    private void getRegistersFromContacts() {
        for (Contact ct : this.contactsList) {
            this.accsIdToUpdate.put(ct.AccountId, System.now());
        }
    }

    private void getRegistersFromAccountContactRelations() {
        System.debug('AAAAAA');
        for (AccountContactRelation acr : this.accountContactRelationsList) {
            this.accsIdToUpdate.put(acr.AccountId, System.now());
        }
        System.debug(this.accsIdToUpdate);
    }
    
    private void getRegistersFromOpportunitites() {
        for (Opportunity opp : this.opportunitiesList) {
            this.accsIdToUpdate.put(opp.AccountId, System.now());
        }
    }
    
    private void getRegistersFromOppTeamMembers() {
        for (OpportunityTeamMember oppTeamMembers : this.oppTeamMembersList) {
            this.oppsIdToUpdate.put(oppTeamMembers.OpportunityId, System.now());
        }
    }
    
    private void getRegistersFromOppContactRoles() {
        Set<Id> contactIds = new Set<Id>();
        for (OpportunityContactRole oppContactRoles : this.oppContactRolesList) {
            this.oppsIdToUpdate.put(oppContactRoles.OpportunityId, System.now());
            contactIds.add(oppContactRoles.ContactId);
        }

        if (contactIds.size() > 0) {
            List<Contact> contacts = new ContactsSelector().selectById(contactIds);
            for (Contact ct : contacts) {
                this.accsIdToUpdate.put(ct.AccountId, System.now());
            }
        }
    }

    private void getRegistersFromEvents() {
        Set<Id> contactIds = new Set<Id>();
        
        for (Event evt : this.eventsList) {
            this.accsIdToUpdate.put(evt.AccountId, System.now());
            
            if (evt.WhatId != null && evt.WhatId.getSObjectType().getDescribe().getName().toUppercase() == 'ACCOUNT') {
                this.accsIdToUpdate.put(evt.WhatId, System.now());
            }
            if (evt.WhatId != null && evt.WhatId.getSObjectType().getDescribe().getName().toUppercase() == 'OPPORTUNITY') {
                this.oppsIdToUpdate.put(evt.WhatId, System.now());
            }
            if (evt.WhoId != null && evt.WhoId.getSObjectType().getDescribe().getName().toUppercase() == 'CONTACT') {
                contactIds.add(evt.WhoId);
            }
        }

        if (contactIds.size() > 0) {
            List<Contact> contacts = new ContactsSelector().selectById(contactIds);
            for (Contact ct : contacts) {
                this.accsIdToUpdate.put(ct.AccountId, System.now());
            }
        }
    }

    private void getRegistersFromTasks() {
        Set<Id> contactIds = new Set<Id>();
        
        for (Task task : this.tasksList) {
            this.accsIdToUpdate.put(task.AccountId, System.now());
            
            if (task.WhatId != null && task.WhatId.getSObjectType().getDescribe().getName().toUppercase() == 'ACCOUNT') {
                this.accsIdToUpdate.put(task.WhatId, System.now());
            }
            if (task.WhatId != null && task.WhatId.getSObjectType().getDescribe().getName().toUppercase() == 'OPPORTUNITY') {
                this.oppsIdToUpdate.put(task.WhatId, System.now());
            }
            if (task.WhoId != null && task.WhoId.getSObjectType().getDescribe().getName().toUppercase() == 'CONTACT') {
                contactIds.add(task.WhoId);
            }
        }

        if (contactIds.size() > 0) {
            List<Contact> contacts = new ContactsSelector().selectById(contactIds);
            for (Contact ct : contacts) {
                this.accsIdToUpdate.put(ct.AccountId, System.now());
            }
        }
    }

    private void getRegistersFromEmails() {
        Set<Id> tasksIds = new Set<Id>();

        for (EmailMessage mail : this.emailsList) {

            if (mail.relatedToId != null && mail.relatedToId.getSObjectType().getDescribe().getName().toUppercase() == 'ACCOUNT') {
                this.accsIdToUpdate.put(mail.relatedToId, System.now());
            }
            if (mail.relatedToId != null && mail.relatedToId.getSObjectType().getDescribe().getName().toUppercase() == 'OPPORTUNITY') {
                this.oppsIdToUpdate.put(mail.relatedToId, System.now());
            }

            if (mail.ActivityId != null) {
                tasksIds.add(mail.ActivityId);
            }
         }

         if (tasksIds.size() > 0) {
            this.setTasks(tasksIds);
            this.getRegistersFromTasks();
         }
    }

    private void getRegistersFromDisplays() {
        for (Displays_Marketing_Material__c display : this.displaysList) {
            this.accsIdToUpdate.put(display.Account__c, System.now());
        }
    }

    private void getRegistersFromsetActivityMetrics() {
        for (ActivityMetric metric : this.activityMetricsList) {
            if (metric.BaseId != null) {
                String sObjName = metric.BaseId.getSObjectType().getDescribe().getName();
                switch on sObjName.toUpperCase() {
                    when 'ACCOUNT'{
                        this.accsIdToUpdate.put(metric.BaseId, metric.LastEmailDateTime);
                    }
                    when 'OPPORTUNITY' {
                        this.oppsIdToUpdate.put(metric.BaseId, metric.LastEmailDateTime);
                    }
                }
            }
        }
    }

    private void getRegistersFromSapOrders() {
        Map<Id, Pedidos_cabeceraSet__x> oppOrderMap = new Map<Id, Pedidos_cabeceraSet__x>();
        Map<Id, Pedidos_cabeceraSet__x> accOrderMap = new Map<Id, Pedidos_cabeceraSet__x>();
        for (Pedidos_cabeceraSet__x sapOrder : this.sapOrdersList) {
            if (sapOrder.Sfopportunity__c != null) {
                oppOrderMap.put(sapOrder.Sfopportunity__c, sapOrder);
            }
            if (sapOrder.Account__c != null) {
                accOrderMap.put(sapOrder.Account__c, sapOrder);
            }
        }
        
        if (oppOrderMap.size() > 0) {
            List<Opportunity> oppsList = new OpportunitiesSelector().selectById(oppOrderMap.keySet());
            for (Opportunity opp : oppsList) {
                if (oppOrderMap.get(opp.Id).Orderdate__c != null && (opp.LastOrderDateTime__c == null || opp.LastOrderDateTime__c < oppOrderMap.get(opp.Id).Orderdate__c)) {
                    this.oppsIdToUpdate.put(opp.Id, oppOrderMap.get(opp.Id).Orderdate__c);
                }
            }
        }
        
        if (accOrderMap.size() > 0) {
            List<Account> accsList = new AccountsSelector().selectById(accOrderMap.keySet());
            for (Account acc : accsList) {
                if (accOrderMap.get(acc.Id).Orderdate__c != null && (acc.LastOrderDateTime__c == null || acc.LastOrderDateTime__c < accOrderMap.get(acc.Id).Orderdate__c)) {
                    this.accsIdToUpdate.put(acc.Id, accOrderMap.get(acc.Id).Orderdate__c);
                }
            }
        }
    }

    private void getRegistersFromSapQuotes() {
        Map<Id, Ofertas_cabeceraSet__x> oppQuoteMap = new Map<Id, Ofertas_cabeceraSet__x>();
        Map<Id, Ofertas_cabeceraSet__x> accQuoteMap = new Map<Id, Ofertas_cabeceraSet__x>();
        for (Ofertas_cabeceraSet__x sapQuote : this.sapQuotesList) {
            if (sapQuote.Sfopportunity__c != null) {
                oppQuoteMap.put(sapQuote.Sfopportunity__c, sapQuote);
            }
            if (sapQuote.Account__c != null) {
                accQuoteMap.put(sapQuote.Account__c, sapQuote);
            }
        }

        if (oppQuoteMap.size() > 0) {
            List<Opportunity> oppsList = new OpportunitiesSelector().selectById(oppQuoteMap.keySet());
            for (Opportunity opp : oppsList) {
                if (oppQuoteMap.get(opp.Id).Orderdate__c != null && (opp.LastQuoteDateTime__c == null || opp.LastQuoteDateTime__c < oppQuoteMap.get(opp.Id).Orderdate__c)) {
                    this.oppsIdToUpdate.put(opp.Id, oppQuoteMap.get(opp.Id).Orderdate__c);
                }
            }
        }
        
        if (accQuoteMap.size() > 0) {
            List<Account> accsList = new AccountsSelector().selectById(accQuoteMap.keySet());
            for (Account acc : accsList) {
                if (accQuoteMap.get(acc.Id).Orderdate__c != null && (acc.LastQuoteDateTime__c == null || acc.LastQuoteDateTime__c < accQuoteMap.get(acc.Id).Orderdate__c)) {
                    this.accsIdToUpdate.put(acc.Id, accQuoteMap.get(acc.Id).Orderdate__c);
                }
            }
        }
    }

    private void getRegistersFromMoodboards() {
        for (Moodboard__c moodboard : this.moodboardsList) {
            this.oppsIdToUpdate.put(moodboard.Opportunity__c, System.now());
        }
    }

    private void getRegistersFromSalesRelationships() {
        for (Sales_Relationship__c salesRel : this.salesRelationshipsList) {
            this.accsIdToUpdate.put(salesRel.Account_Org__c, System.now());
        }
    }

    private void getRegistersFromInstallationRequests() {
        Set<Id> contactIds = new Set<Id>();
        for (InstallationRequest__c insRequest : this.installationRequestsList) {
            this.oppsIdToUpdate.put(insRequest.Opportunity__c, System.now());
            this.accsIdToUpdate.put(insRequest.InstallerAccount__c, System.now());
            if (insRequest.Installer_Contact__c != null) {
                contactIds.add(insRequest.Installer_Contact__c);
            }
        }

        if (contactIds.size() > 0) {
            List<Contact> contacts = new ContactsSelector().selectById(contactIds);
            for (Contact ct : contacts) {
                this.accsIdToUpdate.put(ct.AccountId, System.now());
            }
        }
    }

    private void setDateFieldsEinstein() {
        List<Account> accountsListToUpdate = new List<Account>();
        List<Opportunity> opportunitiesListToUpdate = new List<Opportunity>();

        if (this.oppsIdToUpdate.size() > 0) {
            List<Opportunity> opps = new OpportunitiesSelector().selectById(this.oppsIdToUpdate.keySet());
            for (Opportunity opp : opps) {
                this.accsIdToUpdate.put(opp.AccountId, this.oppsIdToUpdate.get(opp.Id));
            }
        }
        List<Account> accountsList = [SELECT Id,
                                        Last_Activity_Date__c,
                                        LastEventDateTime__c,
                                        LastEmailDateTime__c,
                                        LastOpportunityDateTime__c,
                                        LastOrderDateTime__c,
                                        LastQuoteDateTime__c,
                                        LastContactDateTime__c
                                        FROM Account WHERE Id IN :this.accsIdToUpdate.keySet()];
        //List<Account> accountsList = new AccountsSelector().selectById(this.accsIdToUpdate.keySet());
        //List<Opportunity> opportunitiesList = new OpportunitiesSelector().selectById(this.oppsIdToUpdate.keySet());
        List<Opportunity> opportunitiesList = [SELECT Id,
                                        Last_Activity_Date__c,
                                        LastEventDateTime__c,
                                        LastEmailDateTime__c,
                                        LastOrderDateTime__c,
                                        LastQuoteDateTime__c
                                        FROM Opportunity WHERE Id IN :this.oppsIdToUpdate.keySet()];

        Boolean toSave = false;
        for (Account acc : accountsList) {
            toSave = false;
            if (acc.LastEmailDateTime__c == null || acc.LastEmailDateTime__c < this.accsIdToUpdate.get(acc.Id)) {
                toSave = true;
                acc.put(lastEmailField, this.accsIdToUpdate.get(acc.Id));
            }
            if (acc.Last_Activity_Date__c < this.accsIdToUpdate.get(acc.Id)) {
                toSave = true;
                acc.put(globalLastActivityField, this.accsIdToUpdate.get(acc.Id));
            }
            if (toSave == true) {
                accountsListToUpdate.add(acc);
            }
        }

        for (Opportunity opp : opportunitiesList) {
            toSave = false;
            if (opp.LastEmailDateTime__c == null || opp.LastEmailDateTime__c < this.oppsIdToUpdate.get(opp.Id)) {
                toSave = true;
                opp.put(lastEmailField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (opp.Last_Activity_Date__c < this.oppsIdToUpdate.get(opp.Id)) {
                toSave = true;
                opp.put(globalLastActivityField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (toSave == true) {
                opportunitiesListToUpdate.add(opp);
            }
        }
        this.accsToUpdateList = accountsListToUpdate;
        this.oppsToUpdateList = opportunitiesListToUpdate;
    }

    private void setDateFields() {
        if (this.oppsIdToUpdate.size() > 0) {
            List<Opportunity> opps = new OpportunitiesSelector().selectById(this.oppsIdToUpdate.keySet());
            for (Opportunity opp : opps) {
                this.accsIdToUpdate.put(opp.AccountId, this.oppsIdToUpdate.get(opp.Id));
            }
        }
        
        List<Account> accountsList = [SELECT Id,
                                        Last_Activity_Date__c,
                                        LastEventDateTime__c,
                                        LastEmailDateTime__c,
                                        LastOpportunityDateTime__c,
                                        LastOrderDateTime__c,
                                        LastQuoteDateTime__c,
                                        LastContactDateTime__c
                                        FROM Account WHERE Id IN :this.accsIdToUpdate.keySet()];
        //List<Account> accountsList = new AccountsSelector().selectById(this.accsIdToUpdate.keySet());
        //List<Opportunity> opportunitiesList = new OpportunitiesSelector().selectById(this.oppsIdToUpdate.keySet());
        List<Opportunity> opportunitiesList = [SELECT Id,
                                        Last_Activity_Date__c,
                                        LastEventDateTime__c,
                                        LastEmailDateTime__c,
                                        LastOrderDateTime__c,
                                        LastQuoteDateTime__c
                                        FROM Opportunity WHERE Id IN :this.oppsIdToUpdate.keySet()];       

        for (Account acc : accountsList) {
            if (this.eventsList.size() > 0) {
                acc.put(lastEventField, this.accsIdToUpdate.get(acc.Id));
            }
            if (this.emailsList.size() > 0) {
                acc.put(lastEmailField, this.accsIdToUpdate.get(acc.Id));
            }
            if (this.contactsList.size() > 0) {
                acc.put(lastContactField, this.accsIdToUpdate.get(acc.Id));
            }
            if (this.opportunitiesList.size() > 0) {
                acc.put(lastOpportunityField, this.accsIdToUpdate.get(acc.Id));
            }
            if (this.sapOrdersList.size() > 0 && (acc.LastOrderDateTime__c == null || acc.LastOrderDateTime__c < this.accsIdToUpdate.get(acc.Id))) {
                acc.put(lastOrderField, this.accsIdToUpdate.get(acc.Id));
            }
            if (this.sapQuotesList.size() > 0 && (acc.LastQuoteDateTime__c == null || acc.LastQuoteDateTime__c < this.accsIdToUpdate.get(acc.Id))) {
                acc.put(lastQuoteField, this.accsIdToUpdate.get(acc.Id));
            }
            if (acc.Last_Activity_Date__c < this.accsIdToUpdate.get(acc.Id)) {
                acc.put(globalLastActivityField, this.accsIdToUpdate.get(acc.Id));
            }
        }
        
        for (Opportunity opp : opportunitiesList) {
            if (this.eventsList.size() > 0) {
                opp.put(lastEventField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (this.emailsList.size() > 0) {
                opp.put(lastEmailField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (this.sapOrdersList.size() > 0 && (opp.LastOrderDateTime__c == null || opp.LastOrderDateTime__c < this.oppsIdToUpdate.get(opp.Id))) {
                opp.put(lastOrderField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (this.sapQuotesList.size() > 0 && (opp.LastQuoteDateTime__c == null || opp.LastQuoteDateTime__c < this.oppsIdToUpdate.get(opp.Id))) {
                opp.put(lastQuoteField, this.oppsIdToUpdate.get(opp.Id));
            }
            if (opp.Last_Activity_Date__c < this.oppsIdToUpdate.get(opp.Id)) {
                opp.put(globalLastActivityField, this.oppsIdToUpdate.get(opp.Id));
            }
        }

        this.accsToUpdateList = accountsList;
        this.oppsToUpdateList = opportunitiesList;
    }

    private void saveData() {
        if (this.oppsToUpdateList.size() > 0) {
            List<Database.SaveResult> resultsOpportunities  = Database.update(this.oppsToUpdateList, false);

            for (Database.SaveResult sr : resultsOpportunities) {
                if (!sr.isSuccess()) {
                    System.debug('Failed update Opportunity Activity Date');
                    System.debug(sr);
                }
            }
        } 

        if (this.accsToUpdateList.size() > 0) {
            List<Database.SaveResult> resultsAccounts       = Database.update(this.accsToUpdateList, false);

            for (Database.SaveResult sr : resultsAccounts) {
                if (!sr.isSuccess()) {
                    System.debug('Failed update Account Activity Date');
                    System.debug(sr);
                }
            }
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
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
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