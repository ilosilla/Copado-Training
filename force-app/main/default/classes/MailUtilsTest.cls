@isTest
public class MailUtilsTest {
    @testSetup static void setup() {
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        List<Account> accList = new List<Account>();
        accList.add(Account_TestDataFactory.createRetailer());
        accList.add(Account_TestDataFactory.createBusinessAccount());
        accList.add(Account_TestDataFactory.createRetailer());
        accList.add(Account_TestDataFactory.createCustomer());

        insert accList;
    }

    @isTest
    public static void getMail() {
        User usr = [Select Id, Email from User LIMIT 1];
        List<String> usrMail = MailUtils.getMail(usr.Id);
        
        System.assert(usrMail.size() > 0);
        System.assert(usrMail[0] == usr.Email);
    }
    
    @isTest
    public static void getMailMultiple() {
        Map<Id, User> usrList = new Map<Id,User>([Select Id from User LIMIT 5]);
        Map<Id, Account> accList = new Map<Id,Account>([Select Id from Account LIMIT 4]);
        List<Id> idsList = new List<Id>();
        idsList.addAll(usrList.keySet());
        idsList.addAll(accList.keySet());
        List<String> usrsMails = MailUtils.getMail(idsList);

        System.assert(usrsMails.size() == 9);
    }

    @isTest
    public static void validateEmail() {
        String mail = 'test@test.com';
        List<String> mailList = new List<String>{mail};

        System.assert(MailUtils.validateEmail(mail) == true);
    }

    @isTest
    public static void keepValidEmails() {
        String mail = 'test@test.com';
        String mailTwo = 'test@test';
        String mailThree = 'test@test';
        List<String> mailList = new List<String>{mail, mailTwo, mailThree};

        System.assert(MailUtils.keepValidEmails(mailList).size() == 1);
    }

    @isTest
    public static void getSobjectField() {
        List<User> users = [select Id, Name from User LIMIT 1];
        User user = users[0];

        Object aux = MailUtils.getSobjectField(user, 'Name');

        System.assert(user.Name == aux, 'No coincide el nombre');
    }

    @isTest static void mapToTable() {
        Map<String, String> m = new Map<String, String>();
        m.put('a', 'b');
        String t = MailUtils.mapToTable(m);
        System.assert(t.length() > 0, 'String should not be empty');
    }

}