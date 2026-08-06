@isTest
public with sharing class MailHtmlTest {
    @isTest
    static void createTitle() {
        String aux = MailHtml.createTitle('test');
       System.assert(aux.length() > 5, 'It didn\'t work');
    }

    @isTest
    static void createHeader() {
        String aux = MailHtml.createHeader('test');
       System.assert(aux.length() > 5, 'It didn\'t work');
    }

    @isTest
    static void createTableValues() {
        List<String> headersTable = new List<String>{'Name','Surname','DNI', 'Phone'};
        List<String> rowOne = new List<String>{'Ivan', 'Losilla', '11111111X', '667 233 443'};
        List<String> rowTwo = new List<String>{'Ramón', 'Prades', '22222222T', '667 233 443'};
        List<List<String>> rowsTable = new List<List<String>>();
        rowsTable.add(rowOne);
        rowsTable.add(rowTwo);

        String tableHtml = MailHtml.createTableValues(headersTable, rowsTable);
       System.assert(tableHtml.length() > 20, 'It didn\'t work');
    }

    @isTest
    static void createTableFields() {
        List<String> headersTable = new List<String>{'User Id','Name','Email Address'};
        List<String> fieldsTable = new List<String>{'Id','Name','Email'};
        List<User> listUsers = [SELECT Id, Name, Email FROM User];
        String tableHtml = MailHtml.createTableFields(headersTable, fieldsTable, listUsers);
        System.assert(tableHtml.length() > 20, 'It didn\'t work');
    }
}