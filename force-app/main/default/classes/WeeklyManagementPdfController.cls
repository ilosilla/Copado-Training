/**
* @author Ivan Losilla
* @date March 2025
* @group Reports
* @test WeeklyManagementControllerTest
*/
public class WeeklyManagementPdfController {
    public List<ReportEventWrapper> events { get; set; }
    public List<OpportunityAdditionalInfo__c> oppComments { get; set; }
    public List<AccountAdditionalInfo__c> accComments { get; set; }
    public String startDate { get; set; }
    public String endDate { get; set; }
    public String userName { get; set; }
    public String weekComment { get; set; }

    public WeeklyManagementPdfController() {
        events = new List<ReportEventWrapper>();
        Map<String, User> usersMap = new Map<String, User>();

        // Leer parámetro de IDs
        //String idsParam = ApexPages.currentPage().getParameters().get('eventIds');
        String startDateParam = ApexPages.currentPage().getParameters().get('startDate');
        String endDateParam = ApexPages.currentPage().getParameters().get('endDate');
        String userId = ApexPages.currentPage().getParameters().get('userId');

        User currentUser = [SELECT Id, Name FROM User WHERE id =: userId];
        userName = currentUser.Name;
        endDate = endDateParam;
        startDate = startDateParam;

        if (String.isBlank(startDateParam) == false && String.isBlank(endDateParam) == false && String.isBlank(userId) == false) {
            Set<String> userIds = new Set<String>();
            Date startDate = Date.valueOf(startDateParam);
            Date endDate = Date.valueOf(endDateParam);
            WeeklyManagementController.weeklyData weeklyData = WeeklyManagementController.getWeeklyData(startDate, endDate, userId);
            oppComments = weeklyData.keyOpportunitiesComments;
            accComments = weeklyData.keyAccountsComments;
            weekComment = (weeklyData.weeklyManagement != null ? weeklyData.weeklyManagement.Comment__c : null);

            for (User usr : [SELECT Id, Email, LanguageLocaleKey,TimeZoneSidKey, profile.name, execution_context__c,Default_Sales_Organization__c,countrycode, Sales_Office_Text__c FROM User WHERE IsActive = true]) {
                usersMap.put(usr.Id, usr);
            }

            Map<String, Set<String>> userHierarchy = ReportsHelper.getUserHierarchy();
            Set<String> users = userHierarchy.get(userId);

            // Obtener Accounts y Contacts relacionados (opcional si quieres mostrar nombres)
            Set<Id> accountIds = new Set<Id>();
            Set<Id> opportunityIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            for (Event evt : weeklyData.events) {
                if (evt.WhatId != null) {
                    accountIds.add(evt.WhatId);
                    opportunityIds.add(evt.WhatId);
                }
                if (evt.WhoId != null) contactIds.add(evt.WhoId);
            }

            Map<Id, Account> accountMap = new Map<Id, Account>();
            if (!accountIds.isEmpty()) {
                for (Account acc : [SELECT Id, Name FROM Account WHERE Id IN :accountIds]) {
                    accountMap.put(acc.Id, acc);
                }
            }

            Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
            if (!opportunityIds.isEmpty()) {
                for (Opportunity opp : [SELECT Id, Name, Account.name FROM Opportunity WHERE Id IN :opportunityIds]) {
                    opportunityMap.put(opp.Id, opp);
                }
            }

            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            if (!contactIds.isEmpty()) {
                for (Contact ct : [SELECT Id, Name FROM Contact WHERE Id IN :contactIds]) {
                    contactMap.put(ct.Id, ct);
                }
            }
            // Convertir cada evento en wrapper
            for (Event evt : weeklyData.events) {
                // Obtener timezone del owner
                String tzKey = usersMap.get(evt.OwnerId).TimeZoneSidKey;
                TimeZone tz = TimeZone.getTimeZone(tzKey);

                String accountName = '';
                if (accountMap.containsKey(evt.WhatId)) {
                    accountName = accountMap.get(evt.WhatId).Name;
                } else if (opportunityMap.containsKey(evt.WhatId)) {
                    accountName = opportunityMap.get(evt.WhatId).Account.name;
                }

                ReportEventWrapper row = new ReportEventWrapper();
                row.Subject = evt.Subject;
                row.EventType = evt.EventType__c;
                row.Description = (String.isBlank(evt.otherComments__c) == true ? evt.Description : evt.otherComments__c);
                row.StartDateTime = evt.StartDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID());
                row.EndDateTime = evt.EndDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID());
                row.AccountName = accountName;
                row.ContactName = (evt.WhoId != null && contactMap.containsKey(evt.WhoId)) ? contactMap.get(evt.WhoId).Name : '';
                row.Cancelled = String.valueOf(evt.Cancelled__c);
                row.OwnerName = evt.Owner.Name;
                row.Completed = String.valueOf(evt.LoginFlowCompleted__c);
                row.Link = URL.getOrgDomainURL().toExternalForm() + '/' + evt.Id;
                events.add(row);
            }
        }
    }

    // Wrapper para pasar datos a VF
    public class ReportEventWrapper {
        public String Subject { get; set; }
        public String EventType { get; set; }
        public String Description { get; set; }
        public String StartDateTime { get; set; }
        public String EndDateTime { get; set; }
        public String AccountName { get; set; }
        public String ContactName { get; set; }
        public String Cancelled { get; set; }
        public String OwnerName { get; set; }
        public String Completed { get; set; }
        public String Link { get; set; }
    }
}