/**
* @author Ivan Losilla
* @date May 2021
* @group-content ../../ApexDocContent/WAITING LISTS.htm
* @description Manage the component WaitingListComponent sending necessary info
*/
public class WaitingListComponentController {
    /**
    * @description Given a SalesOffice and a date, returns the entries
    * @param salesOffice sap code of the sales office
    * @param dateFilter date
    * @return list of entries that match the params
    */
	@AuraEnabled
    public static List<WaitingList__c> getWaitingPersonsData(String salesOffice, Date dateFilter) {
        List<WaitingList__c> auxWaitingLists = new List<WaitingList__c>();
        List<WaitingList__c> waitingLists = new List<WaitingList__c>();
        Integer dayFiltered = dateFilter.Day();
        Integer monthFiltered = dateFilter.Month();
        Integer yearFiltered = dateFilter.Year();
        
        auxWaitingLists = [SELECT toLabel(Status__c) labelStatus, Name__c, Email__c,FirstName__c,Id,LastName__c,
                        Phone__c,SalesOffice__r.SalesOffice__c,Status__c, Salesperson__r.Name, Salesperson__c,
                        Salesperson__r.FirstName, Salesperson__r.LastName, Transformed__c,Account__c,Account__r.Name,
                        Contact__c,Contact__r.Name,Appointment__c,CreatedDate
                        FROM WaitingList__c 
                        WHERE SalesOffice__r.SalesOffice__c =: salesOffice
                        order By Status__c ASC, CreatedDate ASC];
        
        for (WaitingList__c wList : auxWaitingLists) {
            //DateTime transCreatedDate = SystemUtils.toUserTimezone(wList.CreatedDate);
            Integer dayWList = wList.CreatedDate.Day();
            Integer monthWList = wList.CreatedDate.Month();
            Integer yearWList = wList.CreatedDate.Year();

            if (dayFiltered == dayWList && monthFiltered == monthWList && yearFiltered == yearWList) {
                waitingLists.add(wList);
            }
        }
        return waitingLists;
    } // getWaitingPersonsData

    /**
    * @description Get the data of the sales office the current user can see, and have waiting lists active
    */
    @AuraEnabled 
    public static List<Sales_Office__c> getSalesOffice() {
        List<Sales_Office__c> salesOfficeList = new List<Sales_Office__c>();
        List<User> usr = UserUtils.getData(new Set<Id>{UserInfo.getUserId()});
        if (UserUtils.isAdministrator(usr[0])) {
            salesOfficeList = [SELECT Name,SalesOffice__c,SalesOrg__c, WaitingList__c, CountryCode__c FROM SALES_OFFICE__c where WaitingList__c = true];
        } else {
            Set<Id> listSubordinatesIds = SystemUtils.getRoleSubordinateUsers(usr[0].UserRoleId);
            List<User> listSubordinates = UserUtils.getData(listSubordinatesIds);
            Set<String> listSalesOffice = new Set<String>{usr[0].Sales_Office__c};

            for (User subordinate : listSubordinates) {
                listSalesOffice.add(subordinate.Sales_Office__c);
            }
            salesOfficeList = [SELECT Name,SalesOffice__c,SalesOrg__c, WaitingList__c, CountryCode__c FROM SALES_OFFICE__c where WaitingList__c = true and SalesOffice__c in :listSalesOffice];
        }       
        return salesOfficeList;
    } // getSalesOffice

    @AuraEnabled 
    public static String getUserSalesOffice() {
        List<User> usr = UserUtils.getData(new Set<Id>{UserInfo.getUserId()});
        return usr[0].Sales_Office__c;
    } // getUserSalesOffice

    /**
    * @description Given a sales office, returns the users that have it set on the profile
    * @param salesOffice sap code of a sales office
    * @return List of users who work on a sales office
    */
    @AuraEnabled 
    public static List<User> getUsers(String salesOffice) {
        List<User> usrList = new List<User>();
        usrList = [SELECT Id, Name from User where isActive = true and Sales_Office__c =: salesOffice order by Name ASC];
        return usrList;
    } // getUsers

    @AuraEnabled 
    public static String getPersonAccountRecordType() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Customer').getRecordTypeId();
    } // getPersonAccountRecordType

    /**
    * @description Changes the owner of an entry on a Waiting list and changes the status to 'INPROGRESS'
    * @param waitingId the id of the entry that is going to change
    */
    @AuraEnabled 
    public static Boolean assistCustomer(String waitingId) {
        WaitingList wlist = new WaitingList(waitingId);
        wlist.assistCustomer();
        
        if (wlist.getSalesperson() != UserInfo.getUserId()) {
            wlist.sendNotificationsAssigned(wlist.getSalesperson(), true);
        }
        return true;
    }

    /**
    * @description Changes the owner of an entry on a Waiting list and changes the status to 'INPROGRESS'
    * @param waitingId the id of the entry that is going to change
    * @param salespersonId the id of the salesperson
    */
    @AuraEnabled 
    public static Boolean assignSalesperson(String waitingId, String salespersonId) {
        WaitingList wlist = new WaitingList(waitingId);
        String existingSalesperson = wlist.getSalesperson();
        wlist.assignSalesperson(salespersonId);
        wlist = new WaitingList(waitingId);
        if (salespersonId != UserInfo.getUserId() && salespersonId != existingSalesperson) {
            //wlist.sendNotificationsAssigned(salespersonId, false);
            wlist.sendWaitingAssistanceMail();
        }
        return true;
    }
    
    @AuraEnabled 
    public static Boolean assignAndAssistSalesperson(String waitingId, String salespersonId) {
        WaitingList wlist = new WaitingList(waitingId);
        wlist.assignSalesperson(salespersonId);
        wlist.assistCustomer();
        
        if (salespersonId != UserInfo.getUserId()) {
            wlist.sendNotificationsAssigned(salespersonId, true);
            wlist.sendWaitingAssistanceMail();
        }
        return true;
    }

    @AuraEnabled 
    public static Boolean changeStatus(String waitingId, String newStatus) {
        WaitingList wlist = new WaitingList(waitingId);
        wlist.changeStatus(newStatus);
        return true;
    }

    @AuraEnabled 
    public static Boolean createNewWListEntry(WaitingList__c entryData) {
        try {
            insert entryData;
        } catch (ContextException ex) {
            throw new ContextException(ex);
        }
        
        WaitingList wlist = new WaitingList(entryData.Id);
        wlist.sendNotificationNewWLItem();
        return true;
    }

    @AuraEnabled 
    public static Boolean createNewPersonAccount(String waitingId, Account accountData) {
         Savepoint sp = Database.setSavepoint();
        
        try {
            insert accountData;
            
            WaitingList__c waitingPerson = [Select Id, Status__c from WaitingList__c where Id =: waitingId LIMIT 1];
            if (waitingPerson != null) {
                waitingPerson.Status__c = 'COMPLETED';
                waitingPerson.Transformed__c = true;
                waitingPerson.Account__c = accountData.Id;
                update waitingPerson;
            }
            
            return true;
        } catch (ContextException ex) {
            Database.RollBack(sp);
            throw new ContextException(ex);
        }
    } // createNewPersonAccount

    @AuraEnabled
    public static Boolean createNewContact(String waitingId, Contact contactData) {
         Savepoint sp = Database.setSavepoint();
        
        try {
            if (contactData.AccountId == null) {
                throw new ContextException('An account must be selected');
            }
            insert contactData;
            
            WaitingList__c waitingPerson = [Select Id, Status__c from WaitingList__c where Id =: waitingId LIMIT 1];
            if (waitingPerson != null) {
                waitingPerson.Status__c = 'COMPLETED';
                waitingPerson.Transformed__c = true;
                waitingPerson.Contact__c = contactData.Id;
                update waitingPerson;
            }
            
            return true;
        } catch (ContextException ex) {
            Database.RollBack(sp);
            throw new ContextException(ex);
        }
    } // createNewPersonAccount
}