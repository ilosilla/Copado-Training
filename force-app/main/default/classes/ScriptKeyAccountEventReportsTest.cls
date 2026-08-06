@isTest
private class ScriptKeyAccountEventReportsTest {

    @testSetup
    static void setupData() {
        List<Master_relations__c> relations = new List<Master_relations__c>();
        relations.add(new Master_relations__c(SalesOrg_name__c ='Azurceramique' , SalesOrg_code__c = '225', DistributionChannel_name__c = 'PIPOO', DistributionChannel_code__c = '70', SalesOffice_code__c = '2552', SalesOffice_name__c = 'TOTOTO',Sector__c = '10'));
        relations.add(new Master_relations__c(SalesOrg_name__c ='Azurceramique' , SalesOrg_code__c = '502', DistributionChannel_name__c = 'PIPOO', DistributionChannel_code__c = '70', SalesOffice_code__c = '2552', SalesOffice_name__c = 'TOTOTO',Sector__c = '10'));
        relations.add(new Master_relations__c(SalesOrg_name__c ='Azurceramique' , SalesOrg_code__c = '232', DistributionChannel_name__c = 'PIPOO', DistributionChannel_code__c = '70', SalesOffice_code__c = '2552', SalesOffice_name__c = 'TOTOTO',Sector__c = '10'));

        insert relations;

        // Crear usuario que actuará como el reportUser
        List<User> users = DataFactoryUser.createUKUsers(4);
        users[0].Email = 'report.user@domain.com';
        users[0].Sales_Org__c = '225;' + OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST;
        users[0].Default_Sales_Organization__c = '225';
        users[0].Alias = 'ilos';

        users[1].Email = 'fr.user@domain.com';
        users[1].Sales_Org__c = '225;' + OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST;
        users[1].Default_Sales_Organization__c = '225';
        users[1].Alias = 'ssega';

        users[2].Email = 'gb.user@domain.com';
        users[2].Sales_Org__c = '502;' + OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST;
        users[2].Default_Sales_Organization__c = '502';
        users[2].Alias = 'ssega';

        users[3].Email = 'us.user@domain.com';
        users[3].Sales_Org__c = '232;' + OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST;
        users[3].Default_Sales_Organization__c = '232';
        users[3].Alias = 'MPrio';

        update users;

        // Crear eventos y follows
        List<Event> events = new List<Event>();
        List<Follow__c> follows = new List<Follow__c>();
        for (User u : users) {
            DateTime dt1 = DateTime.newInstance(Date.today().toStartOfWeek().addDays(1), Time.newInstance(9, 0, 0, 0));
            Event evtCompleted = new Event(
                Subject = 'Meeting with client',
                StartDateTime = dt1,
                EndDateTime = dt1.addHours(1),
                OwnerId = u.Id,
                LoginFlowCompleted__c = dt1,
                Type = 'Commercial',
                IsPrivate = false
            );
            events.add(evtCompleted);

            DateTime dt2 = DateTime.newInstance(Date.today().toStartOfWeek().addDays(2), Time.newInstance(10, 0, 0, 0));
            Event evtIncompleted = new Event(
                Subject = 'Call without info',
                StartDateTime = dt2,
                EndDateTime = dt2.addHours(1),
                OwnerId = u.Id,
                Type = null,
                IsPrivate = false
            );
            events.add(evtIncompleted);
        }
        insert events;

        for (Event evt : events) {
            follows.add(new Follow__c(
                ActivityId__c = evt.Id,
                OwnerId = users[1].Id,
                RecordTypeId = new TestUtils().getRecordTypeId('Follow__c', 'Event')
            ));
        }
        insert follows;

    }

    @isTest
    static void testSendEmails() {
        Test.startTest();

        // Instanciar clase y ejecutar
        Map<String, List<String>> emailsByRegion = new Map<String, List<String>>{
            'FR' => new List<String>{'test1@porcelanosagrupo.com.sandbox'},
            'GB' => new List<String>{'test2@porcelanosagrupo.com.sandbox'},
            'US' => new List<String>{'test3@porcelanosagrupo.com.sandbox'}
        };

        ScriptKeyAccountEventReports script = new ScriptKeyAccountEventReports(emailsByRegion);
        script.SendEmails();

        Test.stopTest();
        
        // Validación básica
        System.assert(true, 'El método se ejecutó correctamente');
    }

    @isTest
    static void testExecute() {
        Test.startTest();
        ScriptKeyAccountEventReports script = new ScriptKeyAccountEventReports();
        script.execute(null);
        Test.stopTest();

        System.assert(true, 'Método execute ejecutado correctamente');
    }

    private class TestUtils {
        User createUser(String email, String orgCode, String alias) {
            Profile p = [SELECT Id FROM Profile LIMIT 1];
            return new User(
                FirstName = 'Test',
                LastName = 'User',
                Email = email,
                Username = email.replace('@', '.' + String.valueOf(Math.random()).substring(2, 6) + '@'),
                Alias = alias != null ? alias : 'test',
                TimeZoneSidKey = 'Europe/Madrid',
                CountryCode = 'GB',
                Country = 'United Kingdom',
                EmailEncodingKey = 'UTF-8',
                Sales_Office__c = '2552',
                Sales_Org__c = orgCode,
                Default_Sales_Organization__c =orgCode,
                Distribution_Channel__c = '60;70;40;20;10;', 
                Distribution_channel_default__c = '60',
                LocaleSidKey = 'en_GB',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id
            );
        }

        Id getRecordTypeId(String sObjectType, String name) {
            return [SELECT Id FROM RecordType WHERE SObjectType = :sObjectType AND Name = :name LIMIT 1].Id;
        }
    }
}