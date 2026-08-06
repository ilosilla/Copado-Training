@isTest
public class PricebookAssignatorTest {
    @testSetup
    private static void testSetup() {
        TestUtils.enableTriggers();
        User usr = new UsersSelector().selectById(UserInfo.getUserId());
        Pricebook2 spb = new Pricebook2(
            IsActive = true,
            SapSync__c = true,
            Bzirk__c = 'V10001',
            Name = 'Test Pricebook SALES REL',
            ExecutionContext__c = 'FR'
        );
        Pricebook2 spb2 = new Pricebook2(
            IsActive = true,
            SapSync__c = true,
            Bzirk__c = '99999',
            Name = 'Test Pricebook Reference',
            ExecutionContext__c = 'FR',
            IsRetailReferencePricebook__c = true
        );
        Pricebook2 spb3 = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            SapSync__c = false
        );
        insert spb;
        insert spb2;
        update spb3;

        List<Account> accs = DataFactoryAccount.createAccounts(10);
        Opportunity newOpp = Opportunity_TestDataFactory.createTrade(accs[1]);
        insert newOpp;

        DataFactoryAccount.autoInsert = false;
        Sales_Relationship__c salesRel = DataFactoryAccount.createSalesRelation(accs[0],'650','60','4200');
        salesRel.Bzirk__c = 'V10001';
        insert salesRel;
    }

    @isTest
    private static void getPricebookToAssign() {
        User usr = new UsersSelector().selectById(UserInfo.getUserId());
        User usrFR = [select id,Execution_Context__c from user where isactive = true and Execution_Context__c = 'FR' LIMIT 1];
        Pricebook2 pb1 = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Test Pricebook SALES REL' LIMIT 1];
        Pricebook2 pbReference = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Test Pricebook Reference' LIMIT 1];
        Sales_Relationship__c salesRel = [SELECT Id, Sales_Org__c, Account_org__c FROM Sales_Relationship__c WHERE Sales_Org__c = '650'  LIMIT 1];
        Account accNoSalesRel = [SELECT Id FROM Account WHERE Id <> : salesRel.Account_Org__c LIMIT 1];
        String contextLabel = [Select Execution_Context__c From User Where  Id = :UserInfo.getUserId()].Execution_Context__c;

        AbstractPricebookAssignator pricebookAssign = PricebookAssignator.getInstance(usrFR.Execution_Context__c);
        pricebookAssign.setUser(usrFR.Id);
        pricebookAssign.setAccount(salesRel.Account_Org__c);
        Pricebook2 pbAssigned = pricebookAssign.getPricebook();
        
        System.assert(pbAssigned != null, 'No se ha encontrado Pricebook entry');
        System.assert(pbAssigned.Id == pb1.Id, 'No se ha encontrado Pricebook de la Sales Relationship');
        
        AbstractPricebookAssignator pricebookAssign2 = PricebookAssignator.getInstance(usrFR.Execution_Context__c);
        pricebookAssign2.setUser(usrFR.Id);
        pricebookAssign2.setAccount(accNoSalesRel.Id);
        Pricebook2 pbAssigned2 = pricebookAssign2.getPricebook();

        System.assert(pbAssigned2 != null, 'No se ha encontrado Pricebook entry');
        System.assert(pbAssigned2.Id == pbReference.Id, 'No se ha encontrado Pricebook de Referencia');
    }
}