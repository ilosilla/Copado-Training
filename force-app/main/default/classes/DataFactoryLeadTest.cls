@isTest public class DataFactoryLeadTest {

    @TestSetup
    private static void makeData(){
        TestUtils.enableTriggers();
    }

    @isTest private static void createWebRequest() {
        Integer num = 10;
        DataFactoryLead.createWebRequest(num);
        List<Lead> leads = [select Id, Title from Lead];
        System.assertEquals(num, leads.size(), 'Web Request Leads not created');
    }

    @isTest private static void createUSWebRequest() {
        Integer num = 10;
        DataFactoryLead.createUSWebRequest(num);
        List<Lead> leads = [select Id, Title from Lead];
        System.assertEquals(num, leads.size(), 'US Web Request Leads not created');
    }

}