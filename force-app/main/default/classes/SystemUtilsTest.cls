/**
 * Ivan Losilla
 * September 2020
 * Tets class of System Utils
 */
@isTest
public class SystemUtilsTest {
  @testSetup
  static void setup() {
    TestUtils.enableTriggers();
  }
  
    @isTest
    static void getOnSandbox() {
        boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        System.assert(runningInASandbox == SystemUtils.getOnSandbox(), 'Sandbox detection not working');
    }

    @isTest
    static void getdiffDays() {
        Datetime beginDate = System.now();
        Datetime endDate = System.now().addDays(2);
        Long days = SystemUtils.getdiffDays(beginDate, endDate);
        System.assert(days == 2, days);
    }

    @isTest
    static void debugError() {
        List<Devlog__c> listDevLogs = [SELECT Id from Devlog__c];
        Integer sizeBefore = listDevLogs.size();
        try {
            throw new DmlException('Something failed');
        } catch (Exception e) {
            SystemUtils.debugError('CREATE ACCOUNT', 'Account not created', e);
        }
        
        listDevLogs = [SELECT Id from Devlog__c];
        System.assert(sizeBefore < listDevLogs.size(), 'DevLog not created');
    }

    @isTest
    static void debugWarning() {
        List<Devlog__c> listDevLogs = [SELECT Id from Devlog__c];
        Integer sizeBefore = listDevLogs.size();
        try {
            throw new DmlException('Something failed');
        } catch (Exception e) {
            SystemUtils.debugWarning('CREATE ACCOUNT', 'Account not created', e);
        }

        listDevLogs = [SELECT Id from Devlog__c];
        System.assert(sizeBefore < listDevLogs.size(), 'DevLog not created');
    }

    @isTest
    static void debugInfo() {
        List<Devlog__c> listDevLogs = [SELECT Id from Devlog__c];
        Integer sizeBefore = listDevLogs.size();

        SystemUtils.debugInfo('CREATE ACCOUNT', 'Account not created');

        listDevLogs = [SELECT Id from Devlog__c];
        System.assert(sizeBefore < listDevLogs.size(), 'DevLog not created');
    }

    @isTest
    static void checkLabels() {
        Profile profile = [Select Id From Profile Where Name='Standard Retail' LIMIT 1][0];
        DataFactoryOrganization.createData();
        String email = 'ukuser@ukuser.cxm';
        User user = new User(Alias = 'tstuka', 
                             Email = email,
                             EmailEncodingKey ='ISO-8859-1', 
                             LastName ='Johnson', 
                             CountryCode = 'GB',
                             countries__c = 'GB',
                             Country = 'United Kingdom',
                             ProfileId = profile.Id, 
                             UserName = email,
                             Sales_Office__c = '2552',
                             Sales_Org__c = OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST,
                             Default_Sales_Organization__c =OrganizationCommons.ORG_SOUTH_EAST,
                             Distribution_Channel__c = '60;70', 
                             Distribution_channel_default__c = '70',
                             TimeZoneSidKey = 'GMT',
                             LocaleSidKey = 'en_GB',
                             LanguageLocaleKey = 'de',
                             Team_Manager__c = TRUE);
        insert user;
        System.runAs(user) {
            String labelText = System.Label.dict_amount;
            System.assert(labelText == 'Amount', 'No debería haber traducción');
        }
    }
}