@isTest
public class OpportunityUtilTest {
    @testSetup static void setup() {
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        List<User> userList = new List<User>();

        userList.addAll(User_TestDataFactory.createUsers(1, new List<String>{'en_US'}));
        userList.addAll(User_TestDataFactory.createUsersNoAdmin(1, new List<String>{'en_US'}));
        insert userList;

        Insert Account_TestDataFactory.createBusinessAccount();
        Insert Account_TestDataFactory.createFabricator();

        List<Account> accList = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1' OR Name = 'TestAcctFabricatorAccount1'];
            
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(Opportunity_TestDataFactory.createTrade(accList[0]));
        oppList.add(Opportunity_TestDataFactory.createTrade(accList[1]));

        insert oppList;    
    }

    @isTest static void getName() {
        Opportunity opp = [SELECT Id, Name FROM Opportunity][0];        
        System.assertEquals(opp.Name, OpportunityUtil.getName(opp.Id), 'Wrong opportunity name');   
    }

    @isTest
    static void addEventToOpportunity() {
        User adminU = [SELECT Id, Sales_Org__c FROM User WHERE UserName LIKE '%@testOrg0.com'];
        User noAdminU = [SELECT Id, Sales_Org__c FROM User WHERE UserName LIKE '%@testOrgNoAdmin0.com'];

        Opportunity opp = [SELECT Id, Last_Activity_Date__c, Sales_Org__c, Dist_Channel__c FROM Opportunity][0];
        DateTime auxDateTime = System.now();
        opp.OwnerId = adminU.Id;
        update opp;

        System.runAs(noAdminU) {
            Event newEvent = new Event(WhatId=opp.Id, Subject='Call', StartDateTime=DateTime.now(), EndDateTime=DateTime.now().addDays(2), Type='Claim Visit');
            Database.insert(newEvent, false);
        }
        
        opp = [SELECT Id, Last_Activity_Date__c, Sales_Org__c, Dist_Channel__c FROM Opportunity where Id =: opp.Id];
        System.assert(opp.Last_Activity_Date__c.date() == auxDateTime.date());
    }
}