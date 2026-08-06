@isTest
public class WaitingListComponentControllerTest {
    @TestSetup
    static void setup(){
        TestUtils.enableTriggers();

        DataFactoryOrganization.createData();
        List<Sales_Office__c> offices = [SELECT Id, SalesOffice__c from Sales_Office__c];
        offices[0].WaitingList__c = true;
        update offices[0];

        WaitingList__C wlEntry = new WaitingList__c(FirstName__c = 'Test', LastName__c = 'Person', Phone__c = '222222222', SalesOffice__c = offices[0].Id);
        insert wlEntry;
    }

    @isTest
    private static void newWntry() {
        List<Sales_Office__c> offices = [SELECT Id, SalesOffice__c from Sales_Office__c];
        offices[0].WaitingList__c = true;
        update offices[0];

        WaitingList__C wlEntry = new WaitingList__c(FirstName__c = 'Test', LastName__c = 'Person', Phone__c = '222222222', SalesOffice__c = offices[0].Id);
        WaitingListComponentController.createNewWListEntry(wlEntry);

        List<WaitingList__C> wList = [SELECT Id, SalesOffice__r.SalesOffice__c, CreatedDate FROM WaitingList__c];
        System.assert(wList.size() == 2, 'Debería haber 2 registros');
    }

    @isTest
    private static void getWaitingPersonsData() {
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, CreatedDate FROM WaitingList__c LIMIT 1];
        List<WaitingList__C> aux = WaitingListComponentController.getWaitingPersonsData(wList.SalesOffice__r.SalesOffice__c, Date.today());
        System.assert(aux.size() > 0, 'Debería haber algún registro devuelto');
    }
    
    @isTest
    private static void getSalesOffice() {
        User admin = TestUtils.getAdminUser();
        List<Sales_Office__c> offices = new List<Sales_Office__c>();
        System.runAs(admin){
            offices = WaitingListComponentController.getSalesOffice();
        }
        System.assert(offices.size() > 0, 'Debería haber algún registro devuelto');
    }
    
    @isTest
    private static void changeSalesman(){
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        User usr = [SELECT Id from User where isActive = true and email like 'balma.sales%' LIMIT 1];
        WaitingListComponentController.assignSalesperson(wList.Id, usr.Id);
        
        wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        System.assert(wList.Status__c == 'ASSIGNED', 'El status no ha cambiado');

        WaitingListComponentController.assistCustomer(wList.Id);
        
        wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        System.assert(wList.Status__c == 'INPROGRESS', 'El status no ha cambiado');
    }

    @isTest
    private static void assignAssistSalesman(){
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        User usr = [SELECT Id from User where isActive = true and email like 'balma.sales%' LIMIT 1];
        WaitingListComponentController.assignAndAssistSalesperson(wList.Id, usr.Id);
        
        wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        System.assert(wList.Status__c == 'INPROGRESS', 'El status no ha cambiado');
    }
    
    @isTest
    private static void changeStatus(){
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        WaitingListComponentController.changeStatus(wList.Id, 'LOST');
        
        wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        System.assert(wList.Status__c == 'LOST', 'El status no ha cambiado');
    }
    
    @isTest
    private static void getUserSalesOffice() {
        User usr = [SELECT Id, Sales_Office__c from User where Id =: UserInfo.getUserId() LIMIT 1];
        String usrSalesOffice = WaitingListComponentController.getUserSalesOffice();
        System.assert(usr.Sales_Office__c == usrSalesOffice, 'No ha cogido bien la sales office del usuario');
        
    }
    
    @isTest
    private static void getUsers() {
        User usr = [SELECT Id, Sales_Office__c from User where Id =: UserInfo.getUserId() LIMIT 1];
        List<User> users = WaitingListComponentController.getUsers(usr.Sales_Office__c);
        System.assert(users.size() > 0, 'No ha cogido bien la sales office del usuario');
        
    }

    @isTest
    private static void createNewPersonAccount() {
        String pivateRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Private_Customer').getRecordTypeId();
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        Account newAcc = new Account(LastName = 'Smith', FirstName = 'John', RecordTypeId = pivateRecordType, Salutation = 'Dr.',
                                        PersonEmail='test@test.c0m',
                                        PersonMailingCountryCode='GB', PersonMailingCity = 'Bristol', PersonMailingPostalCode = 'BS1 3NZ' );
        WaitingListComponentController.createNewPersonAccount(wList.Id, newAcc);
        List<Account> accs = [SELECT Id from Account];
        System.assert(accs.size() > 0, 'No se ha creado el person account');
        
    }

    @isTest
    private static void createNewContact() {
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();
        WaitingList__C wList = [SELECT Id, SalesOffice__r.SalesOffice__c, Status__c, OwnerId, CreatedDate FROM WaitingList__c LIMIT 1];
        Account a = new Account(Name = 'Test Account', RecordTypeId=rtId, 
                    BillingCountryCode = 'GB', BillingCity = 'London', BillingPostalCode = 'BS1 3ND');
        insert a;
        Account acc = [Select Id from Account where Name = 'Test Account' LIMIT 1];
        System.assert(acc != null, 'No se ha creado el account');
        if (acc != null) {
            Contact newContact = new Contact(LastName = 'Smith', FirstName = 'John', Salutation = 'Dr.',
                                        Email='test@test.c0m', AccountId = acc.Id);
            WaitingListComponentController.createNewContact(wList.Id, newContact);
            List<Contact> contacts = [SELECT Id from Contact];
            System.assert(contacts.size() > 0, 'No se ha creado el contact');
        }
        
    }
    
    
}