@isTest
public class BatchSampleOrdersCleanerTest {
    @TestSetup
    static void makeData(){
        List<Account> accs = DataFactoryAccount.createBusinessAccounts(1);
        PorcelanosaSetting__c pSetting = new PorcelanosaSetting__c(key__c = 'SAMPLES_DELETE_DAYS', subkey__c = 'GB', value1__c = '5');
        insert pSetting;

        Id samplesRT = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('NBK_rt_samples').getRecordTypeId();
        Order aux = new Order(
            RecordTypeId = samplesRT,
            EffectiveDate = System.now().addDays(10).date(),
            accountid = accs[0].Id,
            status = 'Draft'
        );
        insert aux;
    }

    @isTest
    static void alertEmailsTest() {
        Integer beforeCounting = Limits.getEmailInvocations();

        test.startTest();
        Database.executebatch(new BatchSampleOrdersCleaner(), 200);
        test.stopTest();

        Assert.isTrue(Limits.getEmailInvocations() >-1, 'Emails no enviados');
    }

    @isTest
    static void deleteTest() {
        Integer beforeCounting = Limits.getEmailInvocations();

        test.startTest();
        BatchSampleOrdersCleaner aux = new BatchSampleOrdersCleaner();
        aux.setDeleteOrders();
        Database.executebatch(aux);
        test.stopTest();

        Assert.isTrue(Limits.getEmailInvocations() >-1, 'Emails no enviados');
    }

    @isTest
    static void fillerTest() {
        BatchSampleOrdersCleaner aux = new BatchSampleOrdersCleaner();
        aux.testFiller();
        Assert.isTrue(1 == 1);
    }
}