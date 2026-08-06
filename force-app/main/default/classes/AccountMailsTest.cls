@isTest
public class AccountMailsTest {
    @testSetup static void setup() {
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        AccountSettings__c newAccSetting = new AccountSettings__c(Name = 'UK', Country__c = 'GB', novalidcreation_mailto__c = 'ivan.losilla@porcelanosagrupo.com');
        PostCodeObjects__c aux = new PostCodeObjects__c(postCode__c = 'BB', objectId__c = '500', objectType__c = 'SALES_ORG', country__c = 'GB');

        insert aux;
        insert newAccSetting;
    }

    @isTest
    static void alertNotValidCreation() {
        Map<String,Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        String tradeRecTypeId = recTypeMap.get('Trade_and_Specificators').getRecordTypeId();

        User u = [SELECT Id, CountryCode, Sales_org__c, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c, ProfileId from User where Sales_Org__c =: OrganizationCommons.ORG_PIDF and IsActive = true LIMIT 1][0];
        Account acc = new Account();
        System.runAs(u) {
            acc = new Account(Name = 'Test Trade Account',
                                        BillingPostalCode = 'BB5 7OH',
                                        BillingCountryCode = 'GB',
                                        Phone = '23423423423',
                                        RecordTypeId = tradeRecTypeId,
                                        BillingCity = 'LLOYD',
                                        Account_Classification__c = 'Architectural firm');
            insert acc;
        }

        List<Account> listAcc = AccountUtil.getData(new Set<Id>{acc.Id});
        AccountMails.alertNotValidCreation(listAcc);
        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
    }
}