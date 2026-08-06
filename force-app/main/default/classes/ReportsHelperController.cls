/**
* @author Ivan Losilla
* @date March 2025
* @group Reports
* @test ReportsHelperTest
*/
public class ReportsHelperController {
    public List<ReportEventWrapper> events { get; set; }

    public ReportsHelperController() {
        events = new List<ReportEventWrapper>();
        Map<String, User> usersMap = new Map<String, User>();

        // Leer parámetro de IDs
        //String idsParam = ApexPages.currentPage().getParameters().get('eventIds');
        String startDateParam = ApexPages.currentPage().getParameters().get('startDate');
        String endDateParam = ApexPages.currentPage().getParameters().get('endDate');
        String typeParam = ApexPages.currentPage().getParameters().get('type');
        String userId = ApexPages.currentPage().getParameters().get('userId');

        if (String.isBlank(startDateParam) == false && String.isBlank(endDateParam) == false && String.isBlank(typeParam) == false && String.isBlank(userId) == false) {
            List<Event> eventsList = new List<Event>();
            Set<String> userIds = new Set<String>();
            Date startDate = Date.valueOf(startDateParam);
            Date endDate = Date.valueOf(endDateParam);
            
            Map<String, Set<String>> userHierarchy = ReportsHelper.getUserHierarchy();
            Set<String> users = userHierarchy.get(userId);

            if (typeParam.toUpperCase() == 'MANAGED') {
                eventsList = ReportsHelper.getManagedEvents(startDate, endDate, users);
            }
            if (typeParam.toUpperCase() == 'UNMANAGED') {
                eventsList = ReportsHelper.getUnManagedEvents(startDate, endDate, new Set<String>{userId});
            }

            for (User usr : [SELECT Id, Email, LanguageLocaleKey,TimeZoneSidKey, profile.name, execution_context__c FROM User WHERE IsActive = true]) {
                usersMap.put(usr.Id, usr);
            }

            // Obtener Accounts y Contacts relacionados (opcional si quieres mostrar nombres)
            Set<Id> accountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            for (Event evt : eventsList) {
                if (evt.WhatId != null) accountIds.add(evt.WhatId);
                if (evt.WhoId != null) contactIds.add(evt.WhoId);
            }

            Map<Id, Account> accountMap = new Map<Id, Account>();
            if (!accountIds.isEmpty()) {
                for (Account acc : [SELECT Id, Name FROM Account WHERE Id IN :accountIds]) {
                    accountMap.put(acc.Id, acc);
                }
            }

            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            if (!contactIds.isEmpty()) {
                for (Contact ct : [SELECT Id, Name FROM Contact WHERE Id IN :contactIds]) {
                    contactMap.put(ct.Id, ct);
                }
            }

            // Convertir cada evento en wrapper
            for (Event evt : eventsList) {
                // Obtener timezone del owner
                String tzKey = usersMap.get(evt.OwnerId).TimeZoneSidKey;
                TimeZone tz = TimeZone.getTimeZone(tzKey);

                ReportEventWrapper row = new ReportEventWrapper();
                row.Subject = evt.Subject;
                row.EventType = evt.EventType__c;
                // 🔽 TRUNCAR descripción si supera 500 caracteres
                if (evt.Description != null && evt.Description.length() > 120) {
                    row.Description = evt.Description.substring(0, 120) + '...';
                } else {
                    row.Description = evt.Description;
                }
                row.StartDateTime = evt.StartDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID());
                row.EndDateTime = evt.EndDateTime.format('yyyy-MM-dd HH:mm:ss', tz.getID());
                row.AccountName = (evt.WhatId != null && accountMap.containsKey(evt.WhatId)) ? accountMap.get(evt.WhatId).Name : '';
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