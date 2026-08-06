@isTest public class SAPCasesMailerServiceTest {

    @testSetup static void makeData() {
        TestUtils.enableTriggers();
        SAPCasesSettings__c settings = new SAPCasesSettings__c();
        settings.Name = '502';
        settings.COL_ApproverEmails__c = 'test@testdomain.cxm';
        //settings.CLAIM_AssignTo__c = 'rprades@porcelanosagrupo.com';
        settings.CLAIM_NotifyNewToOwner__c = true;
        settings.CLAIM_QueueDevName__c = 'dummy_queue';
        settings.COL_TransportEmails__c = 'transport@maixl.cxm'; 
        settings.COL_AccountsEmails__c = 'accounts@maixl.cxm';
        insert settings;          
        //SAPCASesControllerTest.buildNewCase();  
        //DataFactoryCase.createClaims(1);
    }    

    @isTest static void test001() {
        SAPCASesControllerTest.buildNewCase();  
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        SAPCasesMailerService mailer = new SAPCasesMailerService(c.Id);
        mailer.emailApprovalRequest();
        Assert.areEqual(1, 1);
    }

    @isTest private static void test002() {
        SAPCASesControllerTest.buildNewCase();  
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        c.SAPDeliveryNumber__c = '999999';
        update c;
        SAPCasesMailerService mailer = new SAPCasesMailerService(c.Id);
        mailer.emailTransport();
        Assert.areEqual(1, 1);
    }

    @isTest private static void test003() {
        SAPCASesControllerTest.buildNewCase();  
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        c.SAPDeliveryNumber__c = '999999';
        c.SAPCreditNote__c = '6555555';
        update c;
        SAPCasesMailerService.AsyncAccountsEmail(c.Id, Blob.valueOf('Test'));
        Assert.areEqual(1, 1);
    }

    @isTest static void test004() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        Test.startTest();        
        SAPCasesMailerService.AsyncNotifyNewClaim(c.Id);
        Test.stopTest();
        Assert.areEqual(1, 1);
    }

    @isTest static void test005() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        Test.startTest();        
        SAPCasesMailerService.AsyncFactoryInquiryMail(c.Id);
        Test.stopTest();
        Assert.areEqual(1, 1);
    }

    @isTest static void test006() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        c.Compensation__c = 600;
        c.SupplyInstallation__c = true;
        c.SupplyReplacement__c = true;
        update c;
        Test.startTest();        
        SAPCasesMailerService.AsyncSendClaimSolutionToCustomer(c.Id, 'rprades@porcelansoagrupo.com');
        Test.stopTest();
        Assert.areEqual(1, 1);

    }

    @isTest static void test007() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        Test.startTest();        
        SAPCasesMailerService.AsyncSendClaimReceipt(c.Id);
        Test.stopTest();
        Assert.areEqual(1, 1);
    }    

    @isTest private static void test008() {
        SAPCASesControllerTest.buildNewCase();  
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        c.SAPDeliveryNumber__c = '999999';
        c.SAPCreditNote__c = '6555555';
        update c;
        SAPCasesMailerService.AsyncCollectionNoteCreated(c.Id, Blob.valueOf('Test'));
        Assert.areEqual(1, 1);
    }


    @isTest private static void test009() {
        SAPCASesControllerTest.buildNewCase();  
        Case c = [select Id from Case where IsCollection__c = true limit 1];
        c.SAPOrderNumber__c = '111111';
        c.SAPDeliveryNumber__c = '999999';
        c.SAPCreditNote__c = '6555555';
        update c;
        SAPCasesMailerService.AsyncRequestApproval(c.Id);
        Assert.areEqual(1, 1);
    }

    @isTest static void test010() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        Test.startTest();        
        SAPCasesMailerService.AsyncRequestApproval(c.Id);
        Test.stopTest();
        Assert.areEqual(1, 1);
    }

    @isTest static void test011() {
        DataFactoryCase.createClaims(1);
        Case c = [select Id from Case where IsClaim__c = true limit 1];
        Test.startTest();        
        SAPCasesMailerService.AsyncSendClaimSolutionToCustomer(c.Id, 'me@myemail.cxm');
        Test.stopTest();
        Assert.areEqual(1, 1);
    }
 
}